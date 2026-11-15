// Test-only fake of the subset of @supabase/supabase-js used by
// api/_lib/handleAdminRequest.ts. No network: the Node loader swaps the real
// package for supabase-stub.mjs, which calls the factory installed here.
// Every query, rpc, storage and auth.admin call is recorded in `events`, in the
// order it was awaited, so tests can assert ordering and "no mutation".

// Ids contain hex letters on purpose: case-variant tests need toUpperCase() to change the string.
export const ADMIN_ID = '1a1a1a1a-aaaa-4aaa-8aaa-1a2b3c4d5e6f'
export const ADMIN2_ID = '3b3b3b3b-bbbb-4bbb-8bbb-3c4d5e6f7a8b'
export const USER_ID = '2c2c2c2c-cccc-4ccc-8ccc-2d3e4f5a6b7c'
export const CLIENT_IP = '203.0.113.7'

export const SECRET_KEY_VALUE = 'sb_secret_TEST_ONLY_do_not_leak_0123'
export const ENV_NAMES = ['VITE_SUPABASE_URL', 'SUPABASE_URL', 'SUPABASE_SECRET_KEY']

export type Filter = { col: string; op: string; value: unknown }

export type QueryRec = {
  table: string
  op: 'select' | 'insert' | 'update' | 'delete'
  filters: Filter[]
  payload: unknown
  columns: string | undefined
  mode: 'many' | 'single' | 'maybeSingle'
}

export type Result = { data?: unknown; error?: unknown }

export type Event =
  | { kind: 'auth.getUser'; token: string }
  | { kind: 'query'; table: string; op: QueryRec['op']; filters: Filter[]; payload: unknown; mode: QueryRec['mode'] }
  | { kind: 'rpc'; name: string; args: unknown }
  | { kind: 'storage.remove'; bucket: string; paths: unknown }
  | { kind: 'auth.admin.deleteUser'; id: string }
  | { kind: 'auth.admin.updateUserById'; id: string; attrs: unknown }

export type UserSpec =
  | { user: Record<string, unknown> }
  | { user: null; error: { status?: number; message: string } }

export type GetUserResult = {
  data: { user: Record<string, unknown> | null }
  error: { status?: number; message: string } | null
}

export type FakeConfig = {
  /** token -> user. Unknown tokens get a 401-style error, like the real API. */
  users?: Record<string, UserSpec>
  /** Full override of auth.getUser (e.g. to throw or return 5xx). */
  getUser?: (token: string) => Promise<GetUserResult> | GetUserResult
  /** Ids present in public.admin_users (compared case-insensitively, like uuid). */
  adminIds?: string[]
  /** Override any query. Return undefined to fall through to the default. */
  query?: (rec: QueryRec) => Result | undefined | Promise<Result | undefined>
  /** Override rpc(). Return undefined to fall through. */
  rpc?: (name: string, args: unknown) => Result | undefined
  /** Override auth.admin.* calls. Return undefined to fall through. */
  authAdmin?: (kind: 'deleteUser' | 'updateUserById', args: unknown[]) => Result | undefined
}

export type Fake = { events: Event[]; clientOptions: unknown[] }

export const USERS: Record<string, UserSpec> = {
  'tok-admin': { user: { id: ADMIN_ID, email: 'admin@example.test', email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: null } },
  'tok-admin2': { user: { id: ADMIN2_ID, email: 'admin2@example.test', email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: null } },
  'tok-user': { user: { id: USER_ID, email: 'user@example.test', email_confirmed_at: '2026-01-01T00:00:00Z', banned_until: null } },
}

export function installFake(cfg: FakeConfig = {}): Fake {
  const events: Event[] = []
  const clientOptions: unknown[] = []
  const adminIds = (cfg.adminIds ?? [ADMIN_ID]).map((s) => s.toLowerCase())
  const users = cfg.users ?? USERS
  let nextAuditId = 100

  const defaultGetUser = (token: string): GetUserResult => {
    const spec = users[token]
    if (!spec) {
      return {
        data: { user: null },
        error: { status: 403, message: 'invalid JWT: unable to parse or verify signature' },
      }
    }
    if ('error' in spec) return { data: { user: null }, error: spec.error }
    return { data: { user: spec.user }, error: null }
  }

  const eqValue = (rec: QueryRec, col: string) =>
    rec.filters.find((f) => f.col === col && f.op === 'eq')?.value

  const defaultQuery = (rec: QueryRec): Result => {
    if (rec.table === 'admin_users' && rec.op === 'select') {
      const id = String(eqValue(rec, 'user_id') ?? '').toLowerCase()
      return { data: adminIds.includes(id) ? { user_id: id } : null, error: null }
    }
    if (rec.table === 'admin_audit_log' && rec.op === 'insert') {
      return { data: { id: nextAuditId++ }, error: null }
    }
    if (rec.table === 'admin_audit_log' && rec.op === 'update') {
      return { data: null, error: null }
    }
    return { data: rec.op === 'select' ? [] : null, error: null }
  }

  const runQuery = async (rec: QueryRec): Promise<Result> => {
    events.push({
      kind: 'query',
      table: rec.table,
      op: rec.op,
      filters: rec.filters,
      payload: rec.payload,
      mode: rec.mode,
    })
    const override = await cfg.query?.(rec)
    return override ?? defaultQuery(rec)
  }

  class QueryBuilder implements PromiseLike<Result> {
    table: string
    op: QueryRec['op'] | undefined
    filters: Filter[] = []
    payload: unknown = undefined
    columns: string | undefined = undefined
    mode: QueryRec['mode'] = 'many'

    constructor(table: string) {
      this.table = table
    }
    select(columns?: string) {
      if (!this.op) this.op = 'select'
      this.columns = columns
      return this
    }
    insert(payload: unknown) {
      this.op = 'insert'
      this.payload = payload
      return this
    }
    update(payload: unknown) {
      this.op = 'update'
      this.payload = payload
      return this
    }
    delete() {
      this.op = 'delete'
      return this
    }
    eq(col: string, value: unknown) {
      this.filters.push({ col, op: 'eq', value })
      return this
    }
    in(col: string, value: unknown) {
      this.filters.push({ col, op: 'in', value })
      return this
    }
    is(col: string, value: unknown) {
      this.filters.push({ col, op: 'is', value })
      return this
    }
    or(expr: string) {
      this.filters.push({ col: 'or', op: 'or', value: expr })
      return this
    }
    order() {
      return this
    }
    limit() {
      return this
    }
    single() {
      this.mode = 'single'
      return this
    }
    maybeSingle() {
      this.mode = 'maybeSingle'
      return this
    }
    then<T1 = Result, T2 = never>(
      onfulfilled?: ((value: Result) => T1 | PromiseLike<T1>) | null,
      onrejected?: ((reason: unknown) => T2 | PromiseLike<T2>) | null,
    ): PromiseLike<T1 | T2> {
      const rec: QueryRec = {
        table: this.table,
        op: this.op ?? 'select',
        filters: this.filters,
        payload: this.payload,
        columns: this.columns,
        mode: this.mode,
      }
      return runQuery(rec).then(onfulfilled, onrejected)
    }
  }

  const client = {
    auth: {
      async getUser(token: string) {
        events.push({ kind: 'auth.getUser', token })
        return cfg.getUser ? await cfg.getUser(token) : defaultGetUser(token)
      },
      admin: {
        async deleteUser(id: string) {
          events.push({ kind: 'auth.admin.deleteUser', id })
          const o = cfg.authAdmin?.('deleteUser', [id])
          return o ?? { data: { user: null }, error: null }
        },
        async updateUserById(id: string, attrs: { ban_duration?: string }) {
          events.push({ kind: 'auth.admin.updateUserById', id, attrs })
          const o = cfg.authAdmin?.('updateUserById', [id, attrs])
          if (o) return o
          const banned = attrs.ban_duration && attrs.ban_duration !== 'none' ? '2126-01-01T00:00:00Z' : null
          return { data: { user: { banned_until: banned } }, error: null }
        },
      },
    },
    from(table: string) {
      return new QueryBuilder(table)
    },
    async rpc(name: string, args: unknown) {
      events.push({ kind: 'rpc', name, args })
      return cfg.rpc?.(name, args) ?? { data: null, error: null }
    },
    storage: {
      from(bucket: string) {
        return {
          async remove(paths: unknown) {
            events.push({ kind: 'storage.remove', bucket, paths })
            return { data: [], error: null }
          },
          async createSignedUrl() {
            return { data: { signedUrl: 'https://storage.invalid/none' }, error: null }
          },
        }
      },
    },
  }

  ;(globalThis as Record<string, unknown>).__hupFakeSupabaseFactory = (
    _url: string,
    _key: string,
    options: unknown,
  ) => {
    clientOptions.push(options)
    return client
  }

  return { events, clientOptions }
}

/** Environment used by the handler: placeholder local URL and a fake secret. */
export function setEnv(overrides: Partial<Record<(typeof ENV_NAMES)[number], string | undefined>> = {}) {
  const base: Record<string, string | undefined> = {
    VITE_SUPABASE_URL: 'http://127.0.0.1:1',
    SUPABASE_URL: undefined,
    SUPABASE_SECRET_KEY: SECRET_KEY_VALUE,
    ...overrides,
  }
  for (const [k, v] of Object.entries(base)) {
    if (v === undefined) delete process.env[k]
    else process.env[k] = v
  }
}

/** Writes that change data (excludes audit-log writes and reads). */
export function writes(events: Event[]): Event[] {
  return events.filter(
    (e) =>
      (e.kind === 'query' && e.op !== 'select' && e.table !== 'admin_audit_log') ||
      e.kind === 'rpc' ||
      e.kind === 'storage.remove' ||
      e.kind === 'auth.admin.deleteUser' ||
      e.kind === 'auth.admin.updateUserById',
  )
}

/** Audit-log queries in order (insert/update). */
export function auditQueries(events: Event[]): Extract<Event, { kind: 'query' }>[] {
  return events.filter(
    (e): e is Extract<Event, { kind: 'query' }> => e.kind === 'query' && e.table === 'admin_audit_log',
  )
}

/** "table:op" labels for query events, in order. */
export function queryLabels(events: Event[]): string[] {
  return events
    .filter((e): e is Extract<Event, { kind: 'query' }> => e.kind === 'query')
    .map((e) => `${e.table}:${e.op}`)
}
