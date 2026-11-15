// Tests for src/lib/adminApi.ts: how 401 / 403 / 503 / network / non-JSON
// responses are handled. The browser Supabase client is a stub
// (test/support/browser-supabase-stub.mjs) and fetch is replaced per test.
import { describe, it, beforeEach, afterEach, mock } from 'node:test'
import assert from 'node:assert/strict'
import {
  AdminAuthError,
  deleteUser,
  fetchOverview,
  probeAdmin,
  setAuthFailureHandler,
  setUserBlocked,
} from '../src/lib/adminApi.ts'

const NETWORK_ERROR = "Couldn't reach the server. Check your connection and try again."
const GENERIC_ERROR = 'Request failed'
const TOKEN = 'tok-browser-session'

type FetchCall = { url: string; init: RequestInit | undefined }
let fetchCalls: FetchCall[]
let handlerCalls: number[]
let session: { access_token: string } | null

function respond(status: number, body: string | object) {
  const text = typeof body === 'string' ? body : JSON.stringify(body)
  return new Response(text, { status, headers: { 'content-type': 'application/json' } })
}

/** Makes the next fetch() return this response. */
function nextFetch(make: () => Response | Promise<Response>) {
  globalThis.fetch = (async (url: string | URL | Request, init?: RequestInit) => {
    fetchCalls.push({ url: String(url), init })
    return make()
  }) as typeof fetch
}

beforeEach(() => {
  fetchCalls = []
  handlerCalls = []
  session = { access_token: TOKEN }
  ;(globalThis as Record<string, unknown>).__hupFakeBrowserSession = async () => ({
    data: { session },
    error: null,
  })
  setAuthFailureHandler((status) => {
    handlerCalls.push(status)
  })
  mock.method(console, 'error', () => {})
})

afterEach(() => {
  setAuthFailureHandler(null)
  mock.restoreAll()
  delete (globalThis as Record<string, unknown>).__hupFakeBrowserSession
})

describe('authed calls: 401 and 403 from the server', () => {
  it('401 -> AdminAuthError(401), global handler called with 401', async () => {
    nextFetch(() => respond(401, { ok: false, error: 'Unauthorized' }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.ok(err instanceof AdminAuthError)
      assert.equal((err as AdminAuthError).status, 401)
      assert.equal(err.message, 'Unauthorized')
      return true
    })
    assert.deepEqual(handlerCalls, [401])
  })

  it('403 -> AdminAuthError(403), global handler called with 403', async () => {
    nextFetch(() => respond(403, { ok: false, error: 'Forbidden' }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.ok(err instanceof AdminAuthError)
      assert.equal((err as AdminAuthError).status, 403)
      assert.equal(err.message, 'Forbidden')
      return true
    })
    assert.deepEqual(handlerCalls, [403])
  })

  it('no session -> AdminAuthError(401) without any fetch, handler called with 401', async () => {
    session = null
    nextFetch(() => respond(200, { ok: true }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.ok(err instanceof AdminAuthError)
      assert.equal((err as AdminAuthError).status, 401)
      return true
    })
    assert.equal(fetchCalls.length, 0)
    assert.deepEqual(handlerCalls, [401])
  })

  it('a 401 on a mutating call (deleteUser) also triggers the handler', async () => {
    nextFetch(() => respond(401, { ok: false, error: 'Unauthorized' }))
    await assert.rejects(deleteUser('22222222-2222-4222-8222-222222222222'), AdminAuthError)
    assert.deepEqual(handlerCalls, [401])
  })

  it('a 403 on a mutating call (setUserBlocked) triggers the handler with 403', async () => {
    nextFetch(() => respond(403, { ok: false, error: 'Forbidden' }))
    await assert.rejects(setUserBlocked('22222222-2222-4222-8222-222222222222', true), AdminAuthError)
    assert.deepEqual(handlerCalls, [403])
  })
})

describe('authed calls: 503 is transient and must not sign the admin out', () => {
  it('503 -> generic network-style message, handler NOT called, not an AdminAuthError', async () => {
    nextFetch(() => respond(503, { ok: false, error: 'Service unavailable' }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.equal(err instanceof AdminAuthError, false)
      assert.equal((err as Error).message, NETWORK_ERROR)
      return true
    })
    assert.deepEqual(handlerCalls, [])
  })

  it('503 on a mutating call -> network message, handler NOT called', async () => {
    nextFetch(() => respond(503, { ok: false, error: 'Service unavailable' }))
    await assert.rejects(setUserBlocked('22222222-2222-4222-8222-222222222222', false), (err: unknown) => {
      assert.equal((err as Error).message, NETWORK_ERROR)
      return true
    })
    assert.deepEqual(handlerCalls, [])
  })
})

describe('authed calls: network and other failures', () => {
  it('fetch throws (offline) -> network message, handler NOT called', async () => {
    nextFetch(() => {
      throw new TypeError('fetch failed')
    })
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.equal(err instanceof AdminAuthError, false)
      assert.equal((err as Error).message, NETWORK_ERROR)
      return true
    })
    assert.deepEqual(handlerCalls, [])
  })

  it('500 with a JSON error -> server message shown only as the generic fallback text', async () => {
    nextFetch(() => respond(500, { ok: false, error: 'Request failed' }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.equal((err as Error).message, GENERIC_ERROR)
      return true
    })
    assert.deepEqual(handlerCalls, [])
  })

  it('500 with an HTML body (non-JSON) -> generic message, HTML not surfaced', async () => {
    nextFetch(() => new Response('<html>Vercel error page</html>', { status: 500 }))
    await assert.rejects(fetchOverview(), (err: unknown) => {
      assert.equal((err as Error).message, GENERIC_ERROR)
      assert.ok(!(err as Error).message.includes('Vercel'))
      return true
    })
  })

  it('a 200 with ok:false on a mutating call -> throws the server error text', async () => {
    nextFetch(() => respond(400, { ok: false, error: 'Invalid userId' }))
    await assert.rejects(deleteUser('bad'), (err: unknown) => {
      assert.equal((err as Error).message, 'Invalid userId')
      return true
    })
    assert.deepEqual(handlerCalls, [])
  })
})

describe('authed calls: request shape', () => {
  it('sends Authorization: Bearer <access_token> on GET', async () => {
    nextFetch(() => respond(200, { ok: true, pendingVerification: 0, openReports: 0, unpaidCompleted: 0, activeContracts: 0, pendingIdentity: 0, pendingProfilePhoto: 0, pendingEmployerVerification: 0 }))
    const data = await fetchOverview()
    assert.equal(data.ok, true)
    assert.equal(fetchCalls[0].url, '/api/admin/overview')
    const headers = fetchCalls[0].init?.headers as Record<string, string>
    assert.equal(headers.Authorization, `Bearer ${TOKEN}`)
  })

  it('POST sends JSON body and the bearer token', async () => {
    nextFetch(() => respond(200, { ok: true, userId: 'x', blocked: true }))
    await setUserBlocked('22222222-2222-4222-8222-222222222222', true)
    const init = fetchCalls[0].init as RequestInit
    assert.equal(init.method, 'POST')
    assert.equal(fetchCalls[0].url, '/api/admin/users-block')
    assert.deepEqual(JSON.parse(String(init.body)), { userId: '22222222-2222-4222-8222-222222222222', blocked: true })
    assert.equal((init.headers as Record<string, string>).Authorization, `Bearer ${TOKEN}`)
  })
})

describe('probeAdmin (login-time check)', () => {
  it('no session -> "unauthorized" with no fetch', async () => {
    session = null
    nextFetch(() => respond(200, { ok: true }))
    assert.equal(await probeAdmin(), 'unauthorized')
    assert.equal(fetchCalls.length, 0)
  })

  it('200 -> "admin"', async () => {
    nextFetch(() => respond(200, { ok: true }))
    assert.equal(await probeAdmin(), 'admin')
    assert.equal(fetchCalls[0].url, '/api/admin/health')
  })

  it('401 -> "unauthorized"', async () => {
    nextFetch(() => respond(401, { ok: false, error: 'Unauthorized' }))
    assert.equal(await probeAdmin(), 'unauthorized')
  })

  it('403 -> "forbidden"', async () => {
    nextFetch(() => respond(403, { ok: false, error: 'Forbidden' }))
    assert.equal(await probeAdmin(), 'forbidden')
  })

  it('503 -> "error" (retry copy, not sign-out)', async () => {
    nextFetch(() => respond(503, { ok: false, error: 'Service unavailable' }))
    assert.equal(await probeAdmin(), 'error')
  })

  it('500 -> "error"', async () => {
    nextFetch(() => respond(500, { ok: false, error: 'Request failed' }))
    assert.equal(await probeAdmin(), 'error')
  })

  it('network failure -> "error"', async () => {
    nextFetch(() => {
      throw new TypeError('fetch failed')
    })
    assert.equal(await probeAdmin(), 'error')
  })

  it('never fires the global auth-failure handler, whatever the status', async () => {
    for (const status of [401, 403, 500, 503]) {
      nextFetch(() => respond(status, { ok: false }))
      await probeAdmin()
    }
    assert.deepEqual(handlerCalls, [])
  })
})
