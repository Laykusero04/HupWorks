// Tests for the two HTTP entry points that call handleAdminRequest:
//  - api/admin.ts (Vercel Edge handler, used in production; rewrites ?__path=)
//  - server/adminApi.ts (Vite dev middleware)
// Both use the fake Supabase client from test/support/fake-supabase.ts.
import { describe, it, beforeEach, afterEach, mock } from 'node:test'
import assert from 'node:assert/strict'
import { Readable } from 'node:stream'
import handler from '../api/admin.ts'
import { adminApiPlugin } from '../server/adminApi.ts'
import {
  ADMIN_ID,
  ENV_NAMES,
  SECRET_KEY_VALUE,
  USERS,
  USER_ID,
  installFake,
  setEnv,
  writes,
  type Fake,
} from './support/fake-supabase.ts'

const BASE = 'https://app.test'
const TOK_ADMIN = 'Bearer tok-admin'
const TOK_USER = 'Bearer tok-user'

let fake: Fake

beforeEach(() => {
  setEnv()
  mock.method(console, 'error', () => {})
  fake = installFake({ users: USERS, adminIds: [ADMIN_ID] })
})

afterEach(() => {
  mock.restoreAll()
})

function edgeRequest(path: string, init: { method?: string; auth?: string; body?: unknown; search?: string } = {}) {
  const url = `${BASE}${path}${init.search ? `?${init.search}` : ''}`
  const headers: Record<string, string> = {}
  if (init.auth) headers.authorization = init.auth
  let body: string | undefined
  if (init.body !== undefined) {
    headers['content-type'] = 'application/json'
    body = JSON.stringify(init.body)
  }
  return new Request(url, { method: init.method ?? 'GET', headers, body })
}

describe('edge entry api/admin.ts: gate runs for every rewritten or direct path', () => {
  it('POST /api/admin/users-delete without token -> 401 and the request body is never read', async () => {
    const req = edgeRequest('/api/admin/users-delete', { method: 'POST', body: { userId: USER_ID } })
    const res = await handler(req)
    assert.equal(res.status, 401)
    assert.deepEqual(await res.json(), { ok: false, error: 'Unauthorized' })
    assert.equal(req.bodyUsed, false, 'body must not be consumed before auth')
    assert.equal(writes(fake.events).length, 0)
  })

  it('401 responses carry no-store and JSON headers', async () => {
    const res = await handler(edgeRequest('/api/admin/health'))
    assert.equal(res.status, 401)
    assert.equal(res.headers.get('cache-control'), 'no-store')
    assert.match(res.headers.get('content-type') ?? '', /application\/json/)
  })

  it('?__path=health without token -> 401 (rewrite does not skip the gate)', async () => {
    const res = await handler(edgeRequest('/api/admin', { search: '__path=health' }))
    assert.equal(res.status, 401)
  })

  it('?__path=users-delete POST without token -> 401, body unread, no RPC or delete', async () => {
    const req = edgeRequest('/api/admin', { method: 'POST', search: '__path=users-delete', body: { userId: USER_ID } })
    const res = await handler(req)
    assert.equal(res.status, 401)
    assert.equal(req.bodyUsed, false)
    assert.equal(writes(fake.events).length, 0)
  })

  it('spoofed path: /api/admin/health?__path=users-delete without token -> 401', async () => {
    const res = await handler(edgeRequest('/api/admin/health', { search: '__path=users-delete', method: 'POST' }))
    assert.equal(res.status, 401)
  })

  it('spoofed path: /api/admin/anything?__path=health with non-admin token -> 403', async () => {
    const res = await handler(edgeRequest('/api/admin/anything', { search: '__path=health', auth: TOK_USER }))
    assert.equal(res.status, 403)
  })

  it('OPTIONS and HEAD without token -> 401 (no CORS or preflight shortcut)', async () => {
    const opt = await handler(edgeRequest('/api/admin/health', { method: 'OPTIONS' }))
    assert.equal(opt.status, 401)
    const head = await handler(edgeRequest('/api/admin/health', { method: 'HEAD' }))
    assert.equal(head.status, 401)
  })

  it('unknown path without token -> 401 (route existence is not revealed)', async () => {
    const res = await handler(edgeRequest('/api/admin/nope'))
    assert.equal(res.status, 401)
  })

  it('trailing slash with ?__path=health/ and admin token -> 200 {ok:true}', async () => {
    const res = await handler(edgeRequest('/api/admin', { search: '__path=health/', auth: TOK_ADMIN }))
    assert.equal(res.status, 200)
    assert.deepEqual(await res.json(), { ok: true })
  })

  it('admin mutating request: JSON body is read after auth and the route runs', async () => {
    const req = edgeRequest('/api/admin/users-block', {
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID.toUpperCase(), blocked: true },
    })
    const res = await handler(req)
    assert.equal(req.bodyUsed, true)
    assert.equal(res.status, 200)
    const json = (await res.json()) as { userId: string; blocked: boolean }
    assert.equal(json.userId, USER_ID)
    assert.equal(json.blocked, true)
  })

  it('admin with an unparseable JSON body on users-block -> body treated as {} -> 400 Invalid userId', async () => {
    const req = new Request(`${BASE}/api/admin/users-block`, {
      method: 'POST',
      headers: { authorization: TOK_ADMIN, 'content-type': 'application/json' },
      body: '{not json',
    })
    const res = await handler(req)
    assert.equal(res.status, 400)
    assert.deepEqual(await res.json(), { ok: false, error: 'Invalid userId' })
  })

  it('missing env on the edge -> 500 generic body without env names or the secret', async () => {
    setEnv({ VITE_SUPABASE_URL: undefined, SUPABASE_URL: undefined })
    const res = await handler(edgeRequest('/api/admin/health', { auth: TOK_ADMIN }))
    const text = await res.text()
    assert.equal(res.status, 500)
    assert.equal(text, JSON.stringify({ ok: false, error: 'Request failed' }))
    for (const name of ENV_NAMES) assert.ok(!text.includes(name))
    assert.ok(!text.includes(SECRET_KEY_VALUE))
  })
})

// ---- Vite dev middleware (server/adminApi.ts) ------------------------------

type Captured = { status: number; headers: Record<string, string>; body: string; nextCalled: boolean; reqRead: boolean }

async function devRequest(opts: { method: string; url: string; auth?: string; body?: string }): Promise<Captured> {
  const plugin = adminApiPlugin()
  let middleware: ((req: unknown, res: unknown, next: () => void) => Promise<void>) | undefined
  // configureServer is called by Vite with the dev server; here only the middleware stack is needed.
  ;(plugin.configureServer as unknown as (s: unknown) => void)({
    middlewares: {
      use(fn: typeof middleware) {
        middleware = fn
      },
    },
  })

  const req = Readable.from(opts.body ? [Buffer.from(opts.body)] : []) as Readable & Record<string, unknown>
  req.method = opts.method
  req.url = opts.url
  req.headers = opts.auth ? { authorization: opts.auth } : {}
  req.socket = { remoteAddress: '198.51.100.9' }

  const out: Captured = { status: 0, headers: {}, body: '', nextCalled: false, reqRead: false }
  const res = {
    statusCode: 200,
    setHeader(name: string, value: string) {
      out.headers[name.toLowerCase()] = value
    },
    end(chunk: string) {
      out.status = this.statusCode
      out.body = chunk
    },
  }
  await middleware!(req, res, () => {
    out.nextCalled = true
  })
  out.reqRead = req.readableDidRead
  return out
}

describe('dev middleware server/adminApi.ts: same gate as production', () => {
  it('GET /api/admin/health without token -> 401, no-store, not passed to next()', async () => {
    const r = await devRequest({ method: 'GET', url: '/api/admin/health' })
    assert.equal(r.status, 401)
    assert.deepEqual(JSON.parse(r.body), { ok: false, error: 'Unauthorized' })
    assert.equal(r.headers['cache-control'], 'no-store')
    assert.equal(r.nextCalled, false)
  })

  it('POST users-delete without token -> 401 and the request stream is not consumed', async () => {
    const r = await devRequest({
      method: 'POST',
      url: '/api/admin/users-delete',
      body: JSON.stringify({ userId: USER_ID }),
    })
    assert.equal(r.status, 401)
    assert.equal(r.reqRead, false, 'body stream must not be read before auth')
    assert.equal(writes(fake.events).length, 0)
  })

  for (const [method, url] of [
    ['OPTIONS', '/api/admin/health'],
    ['HEAD', '/api/admin/health'],
    ['GET', '/api/admin/health/'],
    ['GET', '/api/admin/nope'],
    ['GET', '/api/admin/health?__path=users-delete'],
  ] as const) {
    it(`${method} ${url} without token -> 401`, async () => {
      const r = await devRequest({ method, url })
      assert.equal(r.status, 401)
      assert.equal(r.nextCalled, false)
    })
  }

  it('admin token on /api/admin/health -> 200 {ok:true}', async () => {
    const r = await devRequest({ method: 'GET', url: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 200)
    assert.deepEqual(JSON.parse(r.body), { ok: true })
  })

  it('non-admin token on /api/admin/health -> 403', async () => {
    const r = await devRequest({ method: 'GET', url: '/api/admin/health', auth: TOK_USER })
    assert.equal(r.status, 403)
  })

  it('admin POST users-block with JSON body -> body read after auth, route runs', async () => {
    const r = await devRequest({
      method: 'POST',
      url: '/api/admin/users-block',
      auth: TOK_ADMIN,
      body: JSON.stringify({ userId: USER_ID, blocked: true }),
    })
    assert.equal(r.reqRead, true)
    assert.equal(r.status, 200)
    assert.equal(JSON.parse(r.body).blocked, true)
  })

  it('non-admin paths are left to Vite (next() is called)', async () => {
    const r = await devRequest({ method: 'GET', url: '/src/main.tsx' })
    assert.equal(r.nextCalled, true)
    assert.equal(r.status, 0)
  })

  it('missing env in dev -> 500 generic body without env names', async () => {
    setEnv({ SUPABASE_SECRET_KEY: undefined })
    const r = await devRequest({ method: 'GET', url: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 500)
    assert.equal(r.body, JSON.stringify({ ok: false, error: 'Request failed' }))
    for (const name of ENV_NAMES) assert.ok(!r.body.includes(name))
  })
})
