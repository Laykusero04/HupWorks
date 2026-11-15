// Tests for api/_lib/handleAdminRequest.ts (admin auth gate, audit, targets).
// Supabase is a fake (test/support/fake-supabase.ts); nothing leaves the process.
import { describe, it, beforeEach, afterEach, mock } from 'node:test'
import assert from 'node:assert/strict'
import { handleAdminRequest, type AdminRequest } from '../api/_lib/handleAdminRequest.ts'
import {
  ADMIN_ID,
  ADMIN2_ID,
  CLIENT_IP,
  ENV_NAMES,
  SECRET_KEY_VALUE,
  USERS,
  USER_ID,
  auditQueries,
  installFake,
  queryLabels,
  setEnv,
  writes,
  type Event,
  type Fake,
  type FakeConfig,
  type QueryRec,
} from './support/fake-supabase.ts'

const TOK_ADMIN = 'Bearer tok-admin'
const TOK_USER = 'Bearer tok-user'
const UPSTREAM_DETAIL = 'UPSTREAM-SECRET-DETAIL-xyz'
const DB_DETAIL = 'DB-SECRET-DETAIL-abc'

type CallOpts = {
  path: string
  method?: string
  auth?: string | null
  body?: unknown
  readBodyThrows?: boolean
  search?: string
  ip?: string | null
}

async function call(opts: CallOpts) {
  const state = { reads: 0 }
  const req: AdminRequest = {
    path: opts.path,
    method: opts.method ?? 'GET',
    searchParams: new URLSearchParams(opts.search ?? ''),
    readBody: async () => {
      state.reads++
      if (opts.readBodyThrows) throw new Error('bad json')
      return opts.body ?? {}
    },
    authorization: opts.auth === undefined ? null : opts.auth,
    ip: opts.ip === undefined ? CLIENT_IP : opts.ip,
  }
  const res = await handleAdminRequest(req)
  return { status: res.status, body: res.body as Record<string, unknown>, text: JSON.stringify(res.body), reads: state.reads }
}

function logged(errSpy: { mock: { calls: { arguments: unknown[] }[] } }): string {
  return errSpy.mock.calls.map((c) => c.arguments.map((a) => (a instanceof Error ? a.message : JSON.stringify(a))).join(' ')).join('\n')
}

let fake: Fake
let errSpy: ReturnType<typeof mock.method>

function use(cfg: FakeConfig = {}) {
  fake = installFake({ users: USERS, adminIds: [ADMIN_ID], ...cfg })
  return fake
}

beforeEach(() => {
  setEnv()
  errSpy = mock.method(console, 'error', () => {})
  use()
})

afterEach(() => {
  mock.restoreAll()
})

describe('admin gate: Authorization header parsing', () => {
  it('no Authorization header -> 401, token never sent to Supabase, body not read', async () => {
    const r = await call({ path: '/api/admin/health', auth: null })
    assert.equal(r.status, 401)
    assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
    assert.equal(fake.events.filter((e) => e.kind === 'auth.getUser').length, 0)
  })

  const malformed = [
    'Basic dG9rLWFkbWlu',
    'Bearer',
    'Bearer ',
    'Bearer  ',
    'Bearer tok-admin extra',
    'Bearer tok admin',
    'Bearer <tok-admin>',
    'Bearer tok-admin;drop',
    'Bearer toké',
    'Token tok-admin',
    'tok-admin',
    '',
  ]
  for (const header of malformed) {
    it(`malformed header ${JSON.stringify(header)} -> 401 without calling getUser`, async () => {
      const r = await call({ path: '/api/admin/health', auth: header })
      assert.equal(r.status, 401)
      assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
      assert.equal(fake.events.filter((e) => e.kind === 'auth.getUser').length, 0)
    })
  }

  it('lowercase "bearer" scheme with a valid admin token -> 200 (scheme match is case-insensitive)', async () => {
    const r = await call({ path: '/api/admin/health', auth: 'bearer tok-admin' })
    assert.equal(r.status, 200)
    assert.deepEqual(r.body, { ok: true })
  })

  it('token is passed to getUser exactly as given (no local decode)', async () => {
    await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    const gu = fake.events.filter((e) => e.kind === 'auth.getUser')
    assert.deepEqual(gu, [{ kind: 'auth.getUser', token: 'tok-admin' }])
  })
})

describe('admin gate: upstream token verification (getUser)', () => {
  it('unknown/invalid token (getUser error 403 from API) -> 401', async () => {
    const r = await call({ path: '/api/admin/health', auth: 'Bearer not-a-real-token' })
    assert.equal(r.status, 401)
    assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
  })

  for (const status of [400, 401, 403]) {
    it(`getUser error status ${status} -> 401`, async () => {
      use({
        getUser: () => ({
          data: { user: null },
          error: { status, message: UPSTREAM_DETAIL },
        }),
      })
      const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
      assert.equal(r.status, 401)
      assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
      assert.ok(!r.text.includes(UPSTREAM_DETAIL), 'upstream message must not reach the client')
    })
  }

  for (const status of [429, 500, 502, 503]) {
    it(`getUser error status ${status} (transient) -> 503, fail-closed`, async () => {
      use({
        getUser: () => ({
          data: { user: null },
          error: { status, message: UPSTREAM_DETAIL },
        }),
      })
      const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
      assert.equal(r.status, 503)
      assert.deepEqual(r.body, { ok: false, error: 'Service unavailable' })
      assert.ok(!r.text.includes(UPSTREAM_DETAIL))
    })
  }

  it('getUser error with no status (network failure) -> 503', async () => {
    use({ getUser: () => ({ data: { user: null }, error: { message: UPSTREAM_DETAIL } }) })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 503)
    assert.deepEqual(r.body, { ok: false, error: 'Service unavailable' })
  })

  it('getUser throws -> 503 with no detail in the body', async () => {
    use({
      getUser: () => {
        throw new Error(UPSTREAM_DETAIL)
      },
    })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 503)
    assert.deepEqual(r.body, { ok: false, error: 'Service unavailable' })
    assert.ok(!r.text.includes(UPSTREAM_DETAIL))
    assert.ok(logged(errSpy).includes(UPSTREAM_DETAIL), 'detail goes to server logs only')
  })

  it('getUser returns no error and no user -> 401', async () => {
    use({ getUser: () => ({ data: { user: null }, error: null }) })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 401)
    assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
  })
})

describe('admin gate: user state', () => {
  it('unconfirmed email (both confirmation fields empty) -> 403, admin table not consulted', async () => {
    use({
      users: {
        'tok-unconfirmed': {
          user: { id: ADMIN_ID, email_confirmed_at: null, confirmed_at: null, banned_until: null },
        },
      },
    })
    const r = await call({ path: '/api/admin/health', auth: 'Bearer tok-unconfirmed' })
    assert.equal(r.status, 403)
    assert.deepEqual(r.body, { ok: false, error: 'Forbidden' })
    assert.ok(!queryLabels(fake.events).includes('admin_users:select'))
  })

  it('confirmed_at set but email_confirmed_at null is accepted (either field counts) -> 200', async () => {
    use({
      users: {
        'tok-confirmed-alt': {
          user: { id: ADMIN_ID, email_confirmed_at: null, confirmed_at: '2026-01-01T00:00:00Z', banned_until: null },
        },
      },
    })
    const r = await call({ path: '/api/admin/health', auth: 'Bearer tok-confirmed-alt' })
    assert.equal(r.status, 200)
  })

  it('active ban (banned_until in the future) -> 403, admin table not consulted', async () => {
    use({
      users: {
        'tok-banned': {
          user: { id: ADMIN_ID, email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: '2999-01-01T00:00:00Z' },
        },
      },
    })
    const r = await call({ path: '/api/admin/health', auth: 'Bearer tok-banned' })
    assert.equal(r.status, 403)
    assert.deepEqual(r.body, { ok: false, error: 'Forbidden' })
    assert.ok(!queryLabels(fake.events).includes('admin_users:select'))
  })

  it('expired ban (banned_until in the past) -> not treated as banned -> 200', async () => {
    use({
      users: {
        'tok-old-ban': {
          user: { id: ADMIN_ID, email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: '2020-01-01T00:00:00Z' },
        },
      },
    })
    const r = await call({ path: '/api/admin/health', auth: 'Bearer tok-old-ban' })
    assert.equal(r.status, 200)
  })

  it('non-admin confirmed user (no admin_users row) -> 403', async () => {
    const r = await call({ path: '/api/admin/health', auth: TOK_USER })
    assert.equal(r.status, 403)
    assert.deepEqual(r.body, { ok: false, error: 'Forbidden' })
  })

  it('admin_users lookup error -> 503 (fail-closed, not 403, not 200)', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_users' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 503)
    assert.deepEqual(r.body, { ok: false, error: 'Service unavailable' })
    assert.ok(!r.text.includes(DB_DETAIL))
  })

  it('admin row present for an admin id in mixed case still matches -> 200', async () => {
    use({ adminIds: [ADMIN_ID.toUpperCase()] })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 200)
  })

  it('admin -> /api/admin/health 200 {ok:true} and the health route does not touch the DB', async () => {
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 200)
    assert.deepEqual(r.body, { ok: true })
    const dataQueries = fake.events.filter((e) => e.kind === 'query' && e.table !== 'admin_users')
    assert.equal(dataQueries.length, 0)
  })
})

describe('admin gate: every path and method is gated before routing', () => {
  const cases: [string, string][] = [
    ['GET', '/api/admin/health'],
    ['GET', '/api/admin/health/'],
    ['GET', '/api/admin/health//'],
    ['HEAD', '/api/admin/health'],
    ['OPTIONS', '/api/admin/health'],
    ['OPTIONS', '/api/admin/users-delete'],
    ['POST', '/api/admin/users-delete'],
    ['POST', '/api/admin/users-block/'],
    ['DELETE', '/api/admin/users'],
    ['PUT', '/api/admin/categories/update'],
    ['GET', '/api/admin/overview'],
    ['GET', '/api/admin/verifications'],
    ['POST', '/api/admin/verifications/review'],
    ['GET', '/api/admin/does-not-exist'],
    ['POST', '/api/admin/does-not-exist'],
    ['GET', '/api/admin'],
    ['GET', '/'],
  ]

  for (const [method, path] of cases) {
    it(`${method} ${path}: no token -> 401 (not 404), no token forwarded to data`, async () => {
      const r = await call({ path, method, auth: null })
      assert.equal(r.status, 401)
      assert.deepEqual(r.body, { ok: false, error: 'Unauthorized' })
      assert.equal(r.reads, 0, 'body must not be read')
      assert.equal(fake.events.filter((e) => e.kind !== 'auth.getUser').length, 0, 'no DB/Auth access')
    })

    it(`${method} ${path}: non-admin token -> 403`, async () => {
      const r = await call({ path, method, auth: TOK_USER })
      assert.equal(r.status, 403)
      assert.deepEqual(r.body, { ok: false, error: 'Forbidden' })
      assert.equal(r.reads, 0)
    })
  }

  it('admin on an unknown path reaches routing and gets 404 (gate passed, route missing)', async () => {
    const r = await call({ path: '/api/admin/does-not-exist', auth: TOK_ADMIN })
    assert.equal(r.status, 404)
    assert.deepEqual(r.body, { ok: false, error: 'Not found' })
  })

  it('trailing slash on an admin route is normalised -> 200 for admin', async () => {
    const r = await call({ path: '/api/admin/health/', auth: TOK_ADMIN })
    assert.equal(r.status, 200)
    assert.deepEqual(r.body, { ok: true })
  })

  it('?__path= in the search params does not bypass the gate (no token -> 401)', async () => {
    const r = await call({ path: '/api/admin/health', search: '__path=users-delete', auth: null, method: 'POST' })
    assert.equal(r.status, 401)
    assert.equal(r.reads, 0)
    assert.equal(writes(fake.events).length, 0)
  })

  it('?__path= spoof with non-admin token -> 403, no mutation', async () => {
    const r = await call({
      path: '/api/admin/health',
      search: '__path=users-delete',
      method: 'POST',
      auth: TOK_USER,
      body: { userId: ADMIN2_ID },
    })
    assert.equal(r.status, 403)
    assert.equal(writes(fake.events).length, 0)
  })
})

describe('admin gate: body is not read before authentication', () => {
  it('POST mutating route with no token: body not read', async () => {
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: null, body: { userId: USER_ID } })
    assert.equal(r.status, 401)
    assert.equal(r.reads, 0)
  })

  it('POST mutating route with non-admin token: body not read', async () => {
    const r = await call({ path: '/api/admin/verification-review', method: 'POST', auth: TOK_USER, body: { userId: USER_ID } })
    assert.equal(r.status, 403)
    assert.equal(r.reads, 0)
  })

  it('POST with unconfirmed user: body not read', async () => {
    use({
      users: { 'tok-unconfirmed': { user: { id: ADMIN_ID, email_confirmed_at: null, confirmed_at: null } } },
    })
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: 'Bearer tok-unconfirmed', body: { userId: USER_ID } })
    assert.equal(r.status, 403)
    assert.equal(r.reads, 0)
  })

  it('POST with transient 503 from getUser: body not read', async () => {
    use({ getUser: () => { throw new Error('boom') } })
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID } })
    assert.equal(r.status, 503)
    assert.equal(r.reads, 0)
  })

  it('GET on an admin route: body never read', async () => {
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 200)
    assert.equal(r.reads, 0)
  })

  it('admin POST: body is read once, after the gate', async () => {
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: true } })
    assert.equal(r.status, 200)
    assert.equal(r.reads, 1)
  })

  it('unreadable body for an admin -> treated as {} and the route validates it (400)', async () => {
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, readBodyThrows: true })
    assert.equal(r.status, 400)
    assert.deepEqual(r.body, { ok: false, error: 'Invalid userId' })
    assert.equal(writes(fake.events).length, 0)
  })
})

describe('admin gate: error bodies never leak env var names or raw error messages', () => {
  it('missing VITE_SUPABASE_URL/SUPABASE_URL -> 500 generic, no env names, no secret value', async () => {
    setEnv({ VITE_SUPABASE_URL: undefined, SUPABASE_URL: undefined })
    const r = await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    for (const name of ENV_NAMES) assert.ok(!r.text.includes(name), `body must not contain ${name}`)
    assert.ok(!r.text.includes(SECRET_KEY_VALUE))
  })

  it('missing SUPABASE_SECRET_KEY -> 500 generic, no env names, no secret value', async () => {
    setEnv({ SUPABASE_SECRET_KEY: undefined })
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: null })
    // Unauthenticated: the env check runs first, so 500 is returned before the gate.
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    for (const name of ENV_NAMES) assert.ok(!r.text.includes(name), `body must not contain ${name}`)
  })

  it('route error with a DB message -> 500 generic, detail only in server logs', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'profiles' && rec.op === 'update'
          ? { data: null, error: { message: DB_DETAIL, code: 'XX000' } }
          : undefined,
    })
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile', decision: 'verified' },
    })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.ok(!r.text.includes(DB_DETAIL))
    assert.ok(logged(errSpy).includes(DB_DETAIL), 'detail is logged server-side')
  })

  it('overview query error -> 500 generic body', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'user_reports' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({ path: '/api/admin/overview', auth: TOK_ADMIN })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.ok(!r.text.includes(DB_DETAIL))
  })

  it('every gate rejection body has exactly {ok, error} and a generic error string', async () => {
    const generic = new Set(['Unauthorized', 'Forbidden', 'Service unavailable', 'Request failed'])
    const scenarios: CallOpts[] = [
      { path: '/api/admin/health', auth: null },
      { path: '/api/admin/health', auth: TOK_USER },
    ]
    for (const s of scenarios) {
      const r = await call(s)
      assert.deepEqual(Object.keys(r.body).sort(), ['error', 'ok'])
      assert.ok(generic.has(r.body.error as string), `unexpected error text ${String(r.body.error)}`)
    }
  })
})

describe('mutating routes: audit row is written before the mutation, then finalised', () => {
  const REASON = 'SENSITIVE-REASON-TEXT-42'

  it('verification-review success: pending audit -> profile update -> success audit (in order)', async () => {
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile', decision: 'verified' },
    })
    assert.equal(r.status, 200)
    assert.deepEqual(r.body, { ok: true, track: 'profile' })
    assert.deepEqual(queryLabels(fake.events), [
      'admin_users:select',
      'admin_audit_log:insert',
      'profiles:update',
      'admin_audit_log:update',
    ])
    const [ins, upd] = auditQueries(fake.events)
    assert.equal(ins.op, 'insert')
    assert.deepEqual(ins.payload, {
      admin_id: ADMIN_ID,
      action: 'verification-review',
      target: USER_ID,
      ip: CLIENT_IP,
      status: 'pending',
      detail: { decision: 'verified', track: 'profile' },
    })
    assert.equal(upd.op, 'update')
    assert.deepEqual(upd.payload, { status: 'success', detail: { decision: 'verified', track: 'profile', http_status: 200 } })
    assert.deepEqual(upd.filters, [{ col: 'id', op: 'eq', value: 100 }])
  })

  it('rejection reason text is not written to the audit log', async () => {
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'identity', decision: 'rejected', rejectionReason: REASON },
    })
    assert.equal(r.status, 200)
    const audit = JSON.stringify(auditQueries(fake.events).map((e) => e.payload))
    assert.ok(!audit.includes(REASON))
    assert.deepEqual(auditQueries(fake.events)[0].payload, {
      admin_id: ADMIN_ID,
      action: 'verification-review',
      target: USER_ID,
      ip: CLIENT_IP,
      status: 'pending',
      detail: { decision: 'rejected', track: 'identity' },
    })
  })

  it('route failure after the audit row exists -> response 500 and audit row finalised as failed', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'profiles' && rec.op === 'update' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile', decision: 'verified' },
    })
    assert.equal(r.status, 500)
    const upd = auditQueries(fake.events)[1]
    assert.deepEqual(upd.payload, {
      status: 'failed',
      detail: { decision: 'verified', track: 'profile', http_status: 500 },
    })
  })

  it('validation 400 on a verification route -> pending row finalised as failed (http 400)', async () => {
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile' },
    })
    assert.equal(r.status, 400)
    const upd = auditQueries(fake.events)[1]
    assert.equal((upd.payload as { status: string }).status, 'failed')
    assert.equal(writes(fake.events).length, 0)
  })

  it('audit insert returns an error -> 500 and nothing is mutated', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_audit_log' && rec.op === 'insert' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile', decision: 'verified' },
    })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.equal(writes(fake.events).length, 0, 'no profile/seller/auth write may happen')
    assert.ok(!queryLabels(fake.events).includes('admin_audit_log:update'))
  })

  it('audit insert throws -> 500 and nothing is mutated', async () => {
    use({
      query: (rec: QueryRec) => {
        if (rec.table === 'admin_audit_log' && rec.op === 'insert') throw new Error(DB_DETAIL)
        return undefined
      },
    })
    const r = await call({
      path: '/api/admin/employer-verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'identity', decision: 'verified' },
    })
    assert.equal(r.status, 500)
    assert.equal(writes(fake.events).length, 0)
  })

  it('audit insert fails for users-block -> 500 and no ban is applied', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_audit_log' && rec.op === 'insert' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: true } })
    assert.equal(r.status, 500)
    assert.equal(fake.events.some((e) => e.kind === 'auth.admin.updateUserById'), false)
  })

  it('audit insert fails for users-delete -> 500 and no RPC, storage, profile or auth delete', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_audit_log' && rec.op === 'insert' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID } })
    assert.equal(r.status, 500)
    assert.equal(writes(fake.events).length, 0)
  })

  it('final audit update fails -> response is still the route result; row stays pending (logged only)', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_audit_log' && rec.op === 'update' ? { data: null, error: { message: DB_DETAIL } } : undefined,
    })
    const r = await call({
      path: '/api/admin/verification-review',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: USER_ID, track: 'profile', decision: 'verified' },
    })
    assert.equal(r.status, 200)
    assert.ok(queryLabels(fake.events).includes('admin_audit_log:update'), 'update was attempted')
    assert.ok(logged(errSpy).includes('[admin/audit] update failed'))
  })

  it('category-update success writes audit action category-update with empty detail', async () => {
    const CAT = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
    const r = await call({
      path: '/api/admin/categories/update',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { id: CAT, nameI18n: { en: 'Design' }, descriptionI18n: {} },
    })
    assert.equal(r.status, 200)
    const [ins] = auditQueries(fake.events)
    assert.equal((ins.payload as { action: string }).action, 'category-update')
    assert.equal((ins.payload as { target: string }).target, CAT)
    assert.deepEqual((ins.payload as { detail: unknown }).detail, {})
  })

  it('read-only routes write no audit rows', async () => {
    await call({ path: '/api/admin/health', auth: TOK_ADMIN })
    await call({ path: '/api/admin/overview', auth: TOK_ADMIN })
    await call({ path: '/api/admin/verifications', auth: TOK_ADMIN, search: 'status=pending' })
    assert.equal(auditQueries(fake.events).length, 0)
  })
})

describe('users-delete / users-block: target validation', () => {
  const DELETE_PATHS = ['/api/admin/users-delete', '/api/admin/users/delete']
  const BLOCK_PATHS = ['/api/admin/users-block', '/api/admin/users/block']
  const ALL = [...DELETE_PATHS, ...BLOCK_PATHS]
  const mixedCase = (id: string) => id.slice(0, 8).toUpperCase() + id.slice(8, 20) + id.slice(20).toUpperCase()

  const selfVariants = [
    ADMIN_ID,
    ADMIN_ID.toUpperCase(),
    mixedCase(ADMIN_ID),
    `  ${ADMIN_ID.toUpperCase()}  `,
  ]

  for (const path of ALL) {
    for (const variant of selfVariants) {
      it(`${path} self-target variant ${JSON.stringify(variant)} -> 400, no mutation, audit rejected`, async () => {
        const r = await call({ path, method: 'POST', auth: TOK_ADMIN, body: { userId: variant, blocked: true } })
        assert.equal(r.status, 400)
        assert.deepEqual(r.body, { ok: false, error: 'Cannot target your own account' })
        assert.equal(writes(fake.events).length, 0)
        const [ins] = auditQueries(fake.events)
        assert.equal((ins.payload as { status: string }).status, 'rejected')
        assert.equal((ins.payload as { target: string }).target, ADMIN_ID)
        assert.equal((ins.payload as { detail: { reason: string } }).detail.reason, 'self_target')
      })
    }
  }

  it('admin whose auth user id is stored in uppercase: lowercase self id still rejected as self', async () => {
    use({
      users: {
        'tok-upper-admin': {
          user: { id: ADMIN_ID.toUpperCase(), email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: null },
        },
      },
      adminIds: [ADMIN_ID],
    })
    const r = await call({
      path: '/api/admin/users-delete',
      method: 'POST',
      auth: 'Bearer tok-upper-admin',
      body: { userId: ADMIN_ID },
    })
    assert.equal(r.status, 400)
    assert.deepEqual(r.body, { ok: false, error: 'Cannot target your own account' })
    assert.equal(writes(fake.events).length, 0)
  })

  it('self-target through the "id" field alias -> 400', async () => {
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, body: { id: ADMIN_ID.toUpperCase() } })
    assert.equal(r.status, 400)
    assert.equal(writes(fake.events).length, 0)
  })

  for (const path of ALL) {
    for (const id of [ADMIN2_ID, ADMIN2_ID.toUpperCase()]) {
      it(`${path} other admin ${id === ADMIN2_ID ? 'lowercase' : 'uppercase'} -> 400, no mutation`, async () => {
        use({ adminIds: [ADMIN_ID, ADMIN2_ID] })
        const r = await call({ path, method: 'POST', auth: TOK_ADMIN, body: { userId: id, blocked: true } })
        assert.equal(r.status, 400)
        assert.deepEqual(r.body, { ok: false, error: 'Cannot target another admin' })
        assert.equal(writes(fake.events).length, 0)
        const [ins] = auditQueries(fake.events)
        assert.equal((ins.payload as { detail: { reason: string } }).detail.reason, 'admin_target')
        assert.equal((ins.payload as { status: string }).status, 'rejected')
      })
    }
  }

  it('admin-target lookup error -> 500 generic, no mutation, and no audit row is written', async () => {
    use({
      query: (rec: QueryRec) =>
        rec.table === 'admin_users' && rec.filters.some((f) => f.value === USER_ID)
          ? { data: null, error: { message: DB_DETAIL } }
          : undefined,
    })
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: true } })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.ok(!r.text.includes(DB_DETAIL))
    assert.equal(writes(fake.events).length, 0)
    assert.equal(auditQueries(fake.events).length, 0)
  })

  const invalid: [string, unknown][] = [
    ['empty string', ''],
    ['whitespace only', '   '],
    ['not a uuid', 'not-a-uuid'],
    ['uuid without hyphens', USER_ID.replace(/-/g, '')],
    ['uuid with trailing text', `${USER_ID} extra`],
    ['sql-ish string', "x' OR '1'='1"],
    ['number', 123],
    ['null', null],
    ['object', { id: USER_ID }],
  ]
  for (const path of ALL) {
    for (const [label, value] of invalid) {
      it(`${path} invalid id (${label}) -> 400 Invalid userId, no mutation, audit rejected`, async () => {
        const r = await call({ path, method: 'POST', auth: TOK_ADMIN, body: { userId: value, blocked: true } })
        assert.equal(r.status, 400)
        assert.deepEqual(r.body, { ok: false, error: 'Invalid userId' })
        assert.equal(writes(fake.events).length, 0)
        const [ins] = auditQueries(fake.events)
        assert.equal((ins.payload as { status: string }).status, 'rejected')
        assert.equal((ins.payload as { detail: { reason: string } }).detail.reason, 'invalid_user_id')
      })
    }
  }

  it('missing body entirely -> 400 Invalid userId', async () => {
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, body: {} })
    assert.equal(r.status, 400)
    assert.equal(writes(fake.events).length, 0)
  })
})

describe('users-delete: uses the validated id everywhere', () => {
  it('uppercase + padded valid id -> RPC, storage, profile delete and auth delete all use the lowercase trimmed id', async () => {
    const r = await call({
      path: '/api/admin/users-delete',
      method: 'POST',
      auth: TOK_ADMIN,
      body: { userId: `  ${USER_ID.toUpperCase()} ` },
    })
    assert.equal(r.status, 200)
    assert.deepEqual(r.body, { ok: true, deletedUserId: USER_ID })

    const w = writes(fake.events)
    assert.deepEqual(w, [
      { kind: 'rpc', name: 'prepare_account_deletion', args: { p_user_id: USER_ID } },
      { kind: 'storage.remove', bucket: 'avatars', paths: [`${USER_ID}/avatar.jpg`] },
      { kind: 'storage.remove', bucket: 'identity-docs', paths: [`${USER_ID}/id_selfie.jpg`, `${USER_ID}/company_doc.jpg`] },
      { kind: 'query', table: 'profiles', op: 'delete', filters: [{ col: 'id', op: 'eq', value: USER_ID }], payload: undefined, mode: 'many' },
      { kind: 'auth.admin.deleteUser', id: USER_ID },
    ])
    const [ins, upd] = auditQueries(fake.events)
    assert.deepEqual(ins.payload, {
      admin_id: ADMIN_ID,
      action: 'users-delete',
      target: USER_ID,
      ip: CLIENT_IP,
      status: 'pending',
      detail: {},
    })
    assert.deepEqual(upd.payload, { status: 'success', detail: { http_status: 200 } })
  })

  it('"id" alias still targets the validated id', async () => {
    const r = await call({ path: '/api/admin/users/delete', method: 'POST', auth: TOK_ADMIN, body: { id: USER_ID.toUpperCase() } })
    assert.equal(r.status, 200)
    assert.deepEqual(fake.events.find((e) => e.kind === 'auth.admin.deleteUser'), { kind: 'auth.admin.deleteUser', id: USER_ID })
  })

  it('RPC error mentioning the missing function -> 500 with the migration hint, no later writes', async () => {
    use({ rpc: () => ({ data: null, error: { message: 'Could not find the function prepare_account_deletion' } }) })
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID } })
    assert.equal(r.status, 500)
    assert.match(String(r.body.error), /migrations\/0044_delete_account\.sql/)
    assert.equal(writes(fake.events).filter((e) => e.kind !== 'rpc').length, 0)
    assert.equal(auditQueries(fake.events)[1].payload && (auditQueries(fake.events)[1].payload as { status: string }).status, 'failed')
  })

  it('auth deleteUser error after the profile was deleted -> 500, audit finalised as failed (partial state is recorded)', async () => {
    use({ authAdmin: (kind) => (kind === 'deleteUser' ? { data: null, error: { message: DB_DETAIL } } : undefined) })
    const r = await call({ path: '/api/admin/users-delete', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID } })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.ok(!r.text.includes(DB_DETAIL))
    assert.ok(queryLabels(fake.events).includes('profiles:delete'))
    const upd = auditQueries(fake.events)[1]
    assert.equal((upd.payload as { status: string }).status, 'failed')
  })
})

describe('users-block: ban state uses the validated id', () => {
  it('block true -> updateUserById(lowercase id, 876000h) and audit op block', async () => {
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID.toUpperCase(), blocked: true } })
    assert.equal(r.status, 200)
    assert.deepEqual(fake.events.find((e) => e.kind === 'auth.admin.updateUserById'), {
      kind: 'auth.admin.updateUserById',
      id: USER_ID,
      attrs: { ban_duration: '876000h' },
    })
    assert.equal(r.body.userId, USER_ID)
    assert.equal(r.body.blocked, true)
    const [ins, upd] = auditQueries(fake.events)
    assert.deepEqual((ins.payload as { detail: unknown }).detail, { op: 'block' })
    assert.deepEqual(upd.payload, { status: 'success', detail: { op: 'block', http_status: 200 } })
  })

  it('blocked: false -> ban_duration none and audit op unblock', async () => {
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: false } })
    assert.equal(r.status, 200)
    assert.deepEqual(fake.events.find((e) => e.kind === 'auth.admin.updateUserById'), {
      kind: 'auth.admin.updateUserById',
      id: USER_ID,
      attrs: { ban_duration: 'none' },
    })
    assert.deepEqual((auditQueries(fake.events)[0].payload as { detail: unknown }).detail, { op: 'unblock' })
  })

  it('blocked as the string "true" is not treated as a block (strict check) -> unblock', async () => {
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: 'true' } })
    assert.equal(r.status, 200)
    assert.deepEqual(fake.events.find((e) => e.kind === 'auth.admin.updateUserById'), {
      kind: 'auth.admin.updateUserById',
      id: USER_ID,
      attrs: { ban_duration: 'none' },
    })
  })

  it('auth update error -> 500 generic, audit failed', async () => {
    use({ authAdmin: () => ({ data: null, error: { message: DB_DETAIL } }) })
    const r = await call({ path: '/api/admin/users-block', method: 'POST', auth: TOK_ADMIN, body: { userId: USER_ID, blocked: true } })
    assert.equal(r.status, 500)
    assert.deepEqual(r.body, { ok: false, error: 'Request failed' })
    assert.ok(!r.text.includes(DB_DETAIL))
    assert.equal((auditQueries(fake.events)[1].payload as { status: string }).status, 'failed')
  })
})
