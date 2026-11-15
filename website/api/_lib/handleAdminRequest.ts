import { createClient, type SupabaseClient } from '@supabase/supabase-js'

export type AdminRequest = {
  path: string
  method: string
  searchParams: URLSearchParams
  /** Lazily reads the JSON body. Called only after the admin gate passes. */
  readBody: () => Promise<unknown>
  /** Raw Authorization header value (Bearer <jwt>). */
  authorization?: string | null
  /** Client IP for audit rows, if known. */
  ip?: string | null
}

export type AdminResponse = {
  status: number
  body: unknown
}

function adminClient(): SupabaseClient {
  const url = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL
  const key = process.env.SUPABASE_SECRET_KEY

  if (!url || !key) {
    throw new Error(
      'Missing VITE_SUPABASE_URL (or SUPABASE_URL) / SUPABASE_SECRET_KEY',
    )
  }

  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

const MUTATING_ROUTES: Record<string, string> = {
  '/api/admin/verification-review': 'verification-review',
  '/api/admin/verifications/review': 'verification-review',
  '/api/admin/employer-verification-review': 'employer-verification-review',
  '/api/admin/employer-verifications/review': 'employer-verification-review',
  '/api/admin/category-update': 'category-update',
  '/api/admin/categories/update': 'category-update',
  '/api/admin/users-delete': 'users-delete',
  '/api/admin/users/delete': 'users-delete',
  '/api/admin/users-block': 'users-block',
  '/api/admin/users/block': 'users-block',
}

function fail(status: number, error: string): AdminResponse {
  return { status, body: { ok: false, error } }
}

type AdminIdentity = { id: string }

/**
 * Fail-closed admin gate. Verifies the bearer JWT with Supabase (server-side,
 * not a local decode) and requires the user to be in public.admin_users.
 * Returns the admin identity or a ready-made error response.
 */
async function requireAdmin(
  req: AdminRequest,
  sb: SupabaseClient,
): Promise<{ admin: AdminIdentity } | { response: AdminResponse }> {
  const header = req.authorization ?? ''
  const match = /^Bearer\s+([A-Za-z0-9._~+/=-]+)\s*$/i.exec(header)
  if (!match) return { response: fail(401, 'Unauthorized') }

  try {
    const { data, error } = await sb.auth.getUser(match[1])
    const user = data?.user
    if (error) {
      // 4xx (except 429) = the token itself was rejected. Anything else
      // (network, 5xx, rate limit, unknown) is transient: 503, still fail-closed.
      const st = (error as { status?: number }).status
      if (typeof st === 'number' && st >= 400 && st < 500 && st !== 429) {
        return { response: fail(401, 'Unauthorized') }
      }
      console.error('[admin/auth] getUser upstream failure', error)
      return { response: fail(503, 'Service unavailable') }
    }
    if (!user) return { response: fail(401, 'Unauthorized') }
    if (!user.email_confirmed_at && !user.confirmed_at) {
      return { response: fail(403, 'Forbidden') }
    }
    if (user.banned_until && new Date(user.banned_until).getTime() > Date.now()) {
      return { response: fail(403, 'Forbidden') }
    }

    const { data: row, error: lookupError } = await sb
      .from('admin_users')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle()
    if (lookupError) {
      console.error('[admin/auth] admin_users lookup failed', lookupError)
      return { response: fail(503, 'Service unavailable') }
    }
    if (!row) return { response: fail(403, 'Forbidden') }
    return { admin: { id: user.id } }
  } catch (err) {
    console.error('[admin/auth] verification failed', err)
    return { response: fail(503, 'Service unavailable') }
  }
}

type AuditStatus = 'pending' | 'success' | 'failed' | 'rejected'

/**
 * Audit policy (fail-closed): for every mutating route an audit row is inserted
 * BEFORE the mutation with status 'pending'. If that insert fails the request
 * fails (500) and nothing is mutated. After the mutation the row is updated to
 * 'success' / 'failed' (with the HTTP status). If that final update fails it is
 * only logged; the row stays 'pending', which marks "attempted, outcome unknown"
 * (e.g. a partial users-delete). Requests rejected by validation get a
 * best-effort 'rejected' row.
 */
async function insertAudit(
  sb: SupabaseClient,
  adminId: string,
  action: string,
  target: string | null,
  ip: string | null,
  status: AuditStatus,
  detail: Record<string, unknown>,
): Promise<number | null> {
  try {
    const { data, error } = await sb
      .from('admin_audit_log')
      .insert({ admin_id: adminId, action, target, ip, status, detail })
      .select('id')
      .single()
    if (error || !data) {
      console.error('[admin/audit] insert failed', error)
      return null
    }
    return data.id as number
  } catch (err) {
    console.error('[admin/audit] insert threw', err)
    return null
  }
}

async function finishAudit(
  sb: SupabaseClient,
  id: number,
  status: AuditStatus,
  detail: Record<string, unknown>,
): Promise<void> {
  try {
    const { error } = await sb.from('admin_audit_log').update({ status, detail }).eq('id', id)
    if (error) console.error('[admin/audit] update failed', error)
  } catch (err) {
    console.error('[admin/audit] update threw', err)
  }
}

function auditDetail(action: string, body: unknown): Record<string, unknown> {
  const b = (body ?? {}) as Record<string, unknown>
  const str = (v: unknown) => (typeof v === 'string' ? v.slice(0, 64) : undefined)
  switch (action) {
    case 'users-block':
      return { op: b.blocked === true ? 'block' : 'unblock' }
    case 'verification-review':
    case 'employer-verification-review':
      return { decision: str(b.decision), track: str(b.track) }
    default:
      return {}
  }
}

/** Shared admin API used by Vite middleware and Vercel serverless. */
export async function handleAdminRequest(req: AdminRequest): Promise<AdminResponse> {
  try {
    const path = req.path.replace(/\/+$/, '') || '/'
    const method = req.method.toUpperCase()

    let sb: SupabaseClient
    try {
      sb = adminClient()
    } catch (err) {
      console.error('[admin] server misconfigured', err)
      return fail(500, 'Request failed')
    }

    const gate = await requireAdmin(req, sb)
    if ('response' in gate) return gate.response
    const admin = gate.admin

    // Body is read only after the caller is authenticated as an admin.
    let body: unknown = {}
    if (method !== 'GET' && method !== 'HEAD') {
      try {
        body = (await req.readBody()) ?? {}
      } catch {
        body = {}
      }
    }

    const action = method === 'POST' ? MUTATING_ROUTES[path] : undefined
    let target: string | null = null
    let validatedUserId: string | null = null
    let auditId: number | null = null
    let detail: Record<string, unknown> = {}

    if (action) {
      const b = (body ?? {}) as { userId?: unknown; id?: unknown }
      const raw = typeof b.userId === 'string' ? b.userId : typeof b.id === 'string' ? b.id : ''
      target = raw.trim() || null
      detail = auditDetail(action, body)
      const ip = req.ip ?? null

      if (action === 'users-delete' || action === 'users-block') {
        const reject = async (status: number, msg: string, reason: string) => {
          await insertAudit(sb, admin.id, action, target, ip, 'rejected', { ...detail, reason })
          return fail(status, msg)
        }
        if (!target || !UUID_RE.test(target)) return reject(400, 'Invalid userId', 'invalid_user_id')
        target = target.toLowerCase()
        validatedUserId = target
        if (target === admin.id.toLowerCase()) {
          return reject(400, 'Cannot target your own account', 'self_target')
        }
        const { data: isAdmin, error: adminErr } = await sb
          .from('admin_users')
          .select('user_id')
          .eq('user_id', target)
          .maybeSingle()
        if (adminErr) {
          console.error('[admin] admin target check failed', adminErr)
          return fail(500, 'Request failed')
        }
        if (isAdmin) return reject(400, 'Cannot target another admin', 'admin_target')
      }

      auditId = await insertAudit(sb, admin.id, action, target, ip, 'pending', detail)
      if (auditId === null) return fail(500, 'Request failed')
    }

    let result: AdminResponse
    try {
      result = await routeAdminRequest({ ...req, body }, sb, path, method, validatedUserId)
    } catch (err) {
      console.error('[admin] route threw', err)
      result = fail(500, 'Request failed')
    }
    if (auditId !== null) {
      const ok = result.status >= 200 && result.status < 300
      await finishAudit(sb, auditId, ok ? 'success' : 'failed', {
        ...detail,
        http_status: result.status,
      })
    }
    return result
  } catch (err) {
    console.error('[admin] unhandled', err)
    return fail(500, 'Request failed')
  }
}

async function routeAdminRequest(
  req: AdminRequest & { body: unknown },
  sb: SupabaseClient,
  path: string,
  method: string,
  targetUserId: string | null,
): Promise<AdminResponse> {
  try {
    if (path === '/api/admin/health' && method === 'GET') {
      return { status: 200, body: { ok: true } }
    }

    if (path === '/api/admin/overview' && method === 'GET') {
      const [
        pendingIdentity,
        pendingProfilePhoto,
        pendingEmployerIdentity,
        pendingEmployerPhoto,
        openReports,
        unpaidCompleted,
        activeContracts,
      ] = await Promise.all([
        sb
          .from('seller_identity_verifications')
          .select('user_id', { count: 'exact', head: true })
          .eq('status', 'pending'),
        sb
          .from('profiles')
          .select('id', { count: 'exact', head: true })
          .eq('role', 'seller')
          .eq('profile_photo_status', 'pending'),
        sb
          .from('employer_verifications')
          .select('user_id', { count: 'exact', head: true })
          .eq('status', 'pending'),
        sb
          .from('profiles')
          .select('id', { count: 'exact', head: true })
          .eq('role', 'client')
          .eq('profile_photo_status', 'pending'),
        sb
          .from('user_reports')
          .select('id', { count: 'exact', head: true })
          .in('status', ['open', 'reviewing']),
        sb
          .from('orders')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'completed')
          .is('payment_received_at', null),
        sb
          .from('orders')
          .select('id', { count: 'exact', head: true })
          .in('status', ['active', 'delivered', 'cancellation_requested']),
      ])

      const errors = [
        pendingIdentity.error,
        pendingProfilePhoto.error,
        openReports.error,
        unpaidCompleted.error,
        activeContracts.error,
      ].filter(Boolean)

      if (errors.length) {
        console.error('[admin/overview]', errors.map((e) => e!.message).join('; '))
        return {
          status: 500,
          body: { ok: false, error: 'Request failed' },
        }
      }

      const employerTableMissing = Boolean(
        pendingEmployerIdentity.error || pendingEmployerPhoto.error,
      )
      const pendingEmployer = employerTableMissing
        ? 0
        : (pendingEmployerIdentity.count ?? 0) + (pendingEmployerPhoto.count ?? 0)

      return {
        status: 200,
        body: {
          ok: true,
          pendingVerification:
            (pendingIdentity.count ?? 0) + (pendingProfilePhoto.count ?? 0),
          pendingIdentity: pendingIdentity.count ?? 0,
          pendingProfilePhoto: pendingProfilePhoto.count ?? 0,
          pendingEmployerVerification: pendingEmployer,
          openReports: openReports.count ?? 0,
          unpaidCompleted: unpaidCompleted.count ?? 0,
          activeContracts: activeContracts.count ?? 0,
        },
      }
    }

    if (path === '/api/admin/verifications' && method === 'GET') {
      const status = req.searchParams.get('status') ?? 'pending'
      let profileQuery = sb
        .from('profiles')
        .select(
          'id, name, email, phone, role, city, country, bio, profile_image_url, verification_status, verification_rejection_reason, profile_photo_status, profile_photo_rejection_reason, seller_onboarding_completed',
        )
        .eq('role', 'seller')
        .limit(200)

      if (status === 'pending') {
        profileQuery = profileQuery.or(
          'profile_photo_status.eq.pending,verification_status.eq.pending',
        )
      } else if (status === 'verified') {
        profileQuery = profileQuery
          .eq('profile_photo_status', 'verified')
          .eq('verification_status', 'verified')
      } else if (status === 'rejected') {
        profileQuery = profileQuery.or(
          'profile_photo_status.eq.rejected,verification_status.eq.rejected',
        )
      }

      const { data: profiles, error } = await profileQuery
      if (error) throw error

      const userIds = (profiles ?? []).map((p) => p.id as string)
      const [{ data: identityRows }, { data: sellers }, { data: privateDetails }] =
        userIds.length
          ? await Promise.all([
              sb
                .from('seller_identity_verifications')
                .select(
                  'user_id, id_selfie_path, status, submitted_at, reviewed_at, rejection_reason',
                )
                .in('user_id', userIds),
              sb
                .from('seller_profiles')
                .select(
                  'user_id, job_title, about, skills, address, languages, birth_year, birth_month, birth_day',
                )
                .in('user_id', userIds),
              sb
                .from('seller_private_details')
                .select('user_id, date_of_birth, street_address, state, postal_code')
                .in('user_id', userIds),
            ])
          : [
              { data: [] as Record<string, unknown>[] },
              { data: [] as Record<string, unknown>[] },
              { data: [] as Record<string, unknown>[] },
            ]

      const identityMap = new Map(
        (identityRows ?? []).map((row) => [row.user_id as string, row]),
      )
      const sellerMap = new Map((sellers ?? []).map((s) => [s.user_id as string, s]))
      const privateMap = new Map(
        (privateDetails ?? []).map((p) => [p.user_id as string, p]),
      )

      const rows = await Promise.all(
        (profiles ?? []).map(async (profile) => {
          const identity = identityMap.get(profile.id as string) ?? null
          let selfieUrl: string | null = null
          const selfiePath = identity?.id_selfie_path as string | undefined
          if (selfiePath) {
            const { data: signed } = await sb.storage
              .from('identity-docs')
              .createSignedUrl(selfiePath, 60 * 10)
            selfieUrl = signed?.signedUrl ?? null
          }
          return {
            user_id: profile.id,
            status: identity?.status ?? profile.verification_status,
            submitted_at: identity?.submitted_at ?? null,
            reviewed_at: identity?.reviewed_at ?? null,
            rejection_reason:
              identity?.rejection_reason ?? profile.verification_rejection_reason,
            id_selfie_path: selfiePath ?? null,
            profile,
            seller: sellerMap.get(profile.id as string) ?? null,
            privateDetails: privateMap.get(profile.id as string) ?? null,
            selfieUrl,
          }
        }),
      )

      return { status: 200, body: { ok: true, rows } }
    }

    // Single-segment path: Vercel non-Next catch-alls do not receive /api/admin/*/*
    if (
      (path === '/api/admin/verification-review' ||
        path === '/api/admin/verifications/review') &&
      method === 'POST'
    ) {
      const body = (req.body ?? {}) as {
        userId?: string
        track?: 'profile' | 'identity'
        decision?: 'verified' | 'rejected'
        rejectionReason?: string
      }

      if (!body.userId || !body.decision || !body.track) {
        return {
          status: 400,
          body: {
            ok: false,
            error: 'userId, track (profile|identity), and decision required',
          },
        }
      }
      if (body.decision === 'rejected' && !body.rejectionReason?.trim()) {
        return { status: 400, body: { ok: false, error: 'rejectionReason required' } }
      }

      const reviewedAt = new Date().toISOString()
      const rejectionReason =
        body.decision === 'rejected' ? body.rejectionReason!.trim() : null

      if (body.track === 'profile') {
        const { error: profileError } = await sb
          .from('profiles')
          .update({
            profile_photo_status: body.decision,
            profile_photo_reviewed_at: reviewedAt,
            profile_photo_rejection_reason: rejectionReason,
          })
          .eq('id', body.userId)
        if (profileError) throw profileError
        return { status: 200, body: { ok: true, track: 'profile' } }
      }

      const { error } = await sb
        .from('seller_identity_verifications')
        .update({
          status: body.decision,
          reviewed_at: reviewedAt,
          rejection_reason: rejectionReason,
        })
        .eq('user_id', body.userId)

      if (error) throw error

      const { error: profileError } = await sb
        .from('profiles')
        .update({
          verification_status: body.decision,
          verification_reviewed_at: reviewedAt,
          verification_rejection_reason: rejectionReason,
        })
        .eq('id', body.userId)

      if (profileError) throw profileError
      return { status: 200, body: { ok: true, track: 'identity' } }
    }

    if (path === '/api/admin/employer-verifications' && method === 'GET') {
      const status = req.searchParams.get('status') ?? 'pending'
      let profileQuery = sb
        .from('profiles')
        .select(
          'id, name, email, phone, role, city, country, bio, profile_image_url, verification_status, verification_rejection_reason, profile_photo_status, profile_photo_rejection_reason, company_name, company_registration_number, company_website',
        )
        .eq('role', 'client')
        .limit(200)

      if (status === 'pending') {
        profileQuery = profileQuery.or(
          'profile_photo_status.eq.pending,verification_status.eq.pending',
        )
      } else if (status === 'verified') {
        profileQuery = profileQuery
          .eq('profile_photo_status', 'verified')
          .eq('verification_status', 'verified')
      } else if (status === 'rejected') {
        profileQuery = profileQuery.or(
          'profile_photo_status.eq.rejected,verification_status.eq.rejected',
        )
      }

      const { data: profiles, error } = await profileQuery
      if (error) throw error

      const userIds = (profiles ?? []).map((p) => p.id as string)
      const { data: employerRows, error: employerError } = userIds.length
        ? await sb
            .from('employer_verifications')
            .select(
              'user_id, verify_type, id_selfie_path, company_doc_path, company_name, company_registration_number, company_website, status, submitted_at, reviewed_at, rejection_reason',
            )
            .in('user_id', userIds)
        : { data: [] as Record<string, unknown>[], error: null }

      if (employerError) {
        const msg = employerError.message || ''
        if (msg.includes('employer_verifications') || msg.includes('schema cache')) {
          return {
            status: 500,
            body: {
              ok: false,
              error:
                'Apply migrations/0043_employer_verification.sql in the Supabase SQL Editor, then retry.',
            },
          }
        }
        throw employerError
      }

      const employerMap = new Map(
        (employerRows ?? []).map((row) => [row.user_id as string, row]),
      )

      const rows = await Promise.all(
        (profiles ?? []).map(async (profile) => {
          const employer = employerMap.get(profile.id as string) ?? null
          let docUrl: string | null = null
          const verifyType = employer?.verify_type as string | undefined
          const docPath =
            verifyType === 'company'
              ? (employer?.company_doc_path as string | undefined)
              : (employer?.id_selfie_path as string | undefined)
          if (docPath) {
            const { data: signed } = await sb.storage
              .from('identity-docs')
              .createSignedUrl(docPath, 60 * 10)
            docUrl = signed?.signedUrl ?? null
          }
          return {
            user_id: profile.id,
            verify_type: verifyType ?? null,
            id_selfie_path: (employer?.id_selfie_path as string | null) ?? null,
            company_doc_path:
              (employer?.company_doc_path as string | null) ?? null,
            company_name:
              (employer?.company_name as string | null) ??
              (profile.company_name as string | null) ??
              null,
            company_registration_number:
              (employer?.company_registration_number as string | null) ??
              (profile.company_registration_number as string | null) ??
              null,
            company_website:
              (employer?.company_website as string | null) ??
              (profile.company_website as string | null) ??
              null,
            status: employer?.status ?? profile.verification_status,
            submitted_at: employer?.submitted_at ?? null,
            reviewed_at: employer?.reviewed_at ?? null,
            rejection_reason:
              employer?.rejection_reason ?? profile.verification_rejection_reason,
            profile,
            docUrl,
          }
        }),
      )

      return { status: 200, body: { ok: true, rows } }
    }

    if (
      (path === '/api/admin/employer-verification-review' ||
        path === '/api/admin/employer-verifications/review') &&
      method === 'POST'
    ) {
      const body = (req.body ?? {}) as {
        userId?: string
        track?: 'profile' | 'identity'
        decision?: 'verified' | 'rejected'
        rejectionReason?: string
      }

      if (!body.userId || !body.decision || !body.track) {
        return {
          status: 400,
          body: {
            ok: false,
            error: 'userId, track (profile|identity), and decision required',
          },
        }
      }
      if (body.decision === 'rejected' && !body.rejectionReason?.trim()) {
        return { status: 400, body: { ok: false, error: 'rejectionReason required' } }
      }

      const reviewedAt = new Date().toISOString()
      const rejectionReason =
        body.decision === 'rejected' ? body.rejectionReason!.trim() : null

      if (body.track === 'profile') {
        const { error: profileError } = await sb
          .from('profiles')
          .update({
            profile_photo_status: body.decision,
            profile_photo_reviewed_at: reviewedAt,
            profile_photo_rejection_reason: rejectionReason,
          })
          .eq('id', body.userId)
          .eq('role', 'client')
        if (profileError) throw profileError
        return { status: 200, body: { ok: true, track: 'profile' } }
      }

      const { error } = await sb
        .from('employer_verifications')
        .update({
          status: body.decision,
          reviewed_at: reviewedAt,
          rejection_reason: rejectionReason,
        })
        .eq('user_id', body.userId)

      if (error) throw error

      const { error: profileError } = await sb
        .from('profiles')
        .update({
          verification_status: body.decision,
          verification_reviewed_at: reviewedAt,
          verification_rejection_reason: rejectionReason,
        })
        .eq('id', body.userId)
        .eq('role', 'client')

      if (profileError) throw profileError
      return { status: 200, body: { ok: true, track: 'identity' } }
    }

    if (path === '/api/admin/reports' && method === 'GET') {
      const { data, error } = await sb
        .from('user_reports')
        .select(
          'id, reporter_id, reported_user_id, reason, details, status, created_at, job_post_id, order_id',
        )
        .in('status', ['open', 'reviewing'])
        .order('created_at', { ascending: true })
        .limit(50)

      if (error) throw error

      const rows = data ?? []
      const profileIds = [
        ...new Set(
          rows
            .flatMap((r) => [r.reporter_id, r.reported_user_id])
            .filter((id): id is string => Boolean(id)),
        ),
      ]
      const orderIds = [
        ...new Set(
          rows.map((r) => r.order_id).filter((id): id is string => Boolean(id)),
        ),
      ]

      const profilesById = new Map<
        string,
        { id: string; name: string | null; email: string | null; role: string | null }
      >()
      if (profileIds.length) {
        const { data: profiles, error: profilesError } = await sb
          .from('profiles')
          .select('id, name, email, role')
          .in('id', profileIds)
        if (profilesError) throw profilesError
        for (const p of profiles ?? []) {
          profilesById.set(p.id, p)
        }
      }

      const ordersById = new Map<
        string,
        {
          id: string
          status: string | null
          payment_received_at: string | null
          client_id: string
          seller_id: string
          price: number | null
        }
      >()
      if (orderIds.length) {
        const { data: orders, error: ordersError } = await sb
          .from('orders')
          .select('id, status, payment_received_at, client_id, seller_id, price')
          .in('id', orderIds)
        if (ordersError) throw ordersError
        for (const o of orders ?? []) {
          ordersById.set(o.id, o)
        }
      }

      const blockPairs = rows
        .filter((r) => r.reporter_id && r.reported_user_id)
        .map((r) => ({
          a: r.reporter_id as string,
          b: r.reported_user_id as string,
        }))

      const blockedPairKeys = new Set<string>()
      if (blockPairs.length) {
        const ids = [...new Set(blockPairs.flatMap((p) => [p.a, p.b]))]
        const { data: blocks, error: blocksError } = await sb
          .from('user_blocks')
          .select('blocker_id, blocked_id')
          .or(`blocker_id.in.(${ids.join(',')}),blocked_id.in.(${ids.join(',')})`)

        if (blocksError && !/user_blocks|schema cache|PGRST205/i.test(blocksError.message)) {
          throw blocksError
        }
        for (const b of blocks ?? []) {
          const key = [b.blocker_id, b.blocked_id].sort().join('|')
          const relevant = blockPairs.some((p) => [p.a, p.b].sort().join('|') === key)
          if (relevant) blockedPairKeys.add(key)
        }
      }

      const enriched = rows.map((row) => {
        const order = row.order_id ? ordersById.get(row.order_id) ?? null : null
        const pairKey =
          row.reporter_id && row.reported_user_id
            ? [row.reporter_id, row.reported_user_id].sort().join('|')
            : null
        const unpaid =
          order != null &&
          String(order.status || '').toLowerCase() === 'completed' &&
          !order.payment_received_at
        return {
          ...row,
          reporter: row.reporter_id ? profilesById.get(row.reporter_id) ?? null : null,
          reported: row.reported_user_id
            ? profilesById.get(row.reported_user_id) ?? null
            : null,
          order,
          unpaid_completed: unpaid,
          pair_blocked: pairKey ? blockedPairKeys.has(pairKey) : false,
        }
      })

      return { status: 200, body: { ok: true, rows: enriched } }
    }

    if (path === '/api/admin/categories' && method === 'GET') {
      const { data, error } = await sb
        .from('categories')
        .select(
          'id, name, description, icon, is_custom, created_at, name_i18n, description_i18n',
        )
        .order('is_custom', { ascending: true })
        .order('name', { ascending: true })
        .limit(500)

      if (error) {
        if (/name_i18n|description_i18n|schema cache|PGRST204|42703/i.test(error.message)) {
          return {
            status: 500,
            body: {
              ok: false,
              error:
                'Category translations columns missing. Apply migrations/0040_category_i18n.sql in the Supabase SQL Editor.',
            },
          }
        }
        throw error
      }

      return { status: 200, body: { ok: true, rows: data ?? [] } }
    }

    if (
      (path === '/api/admin/category-update' ||
        path === '/api/admin/categories/update') &&
      method === 'POST'
    ) {
      const body = (req.body ?? {}) as {
        id?: string
        nameI18n?: Record<string, string>
        descriptionI18n?: Record<string, string>
        icon?: string | null
      }

      if (!body.id) {
        return { status: 400, body: { ok: false, error: 'id required' } }
      }

      const locales = ['en', 'nl', 'bn'] as const
      const cleanMap = (raw: Record<string, string> | undefined) => {
        const out: Record<string, string> = {}
        if (!raw || typeof raw !== 'object') return out
        for (const code of locales) {
          const value = String(raw[code] ?? '').trim()
          if (value) out[code] = value
        }
        return out
      }

      const nameI18n = cleanMap(body.nameI18n)
      const descriptionI18n = cleanMap(body.descriptionI18n)
      const enName = nameI18n.en?.trim()
      if (!enName) {
        return {
          status: 400,
          body: {
            ok: false,
            error: 'English name (en) is required — it is the canonical category key',
          },
        }
      }

      const patch: Record<string, unknown> = {
        name: enName,
        name_i18n: nameI18n,
        description_i18n: descriptionI18n,
        description: descriptionI18n.en?.trim() || null,
      }
      if (body.icon !== undefined) {
        patch.icon = body.icon?.trim() || null
      }

      const { data, error } = await sb
        .from('categories')
        .update(patch)
        .eq('id', body.id)
        .select(
          'id, name, description, icon, is_custom, created_at, name_i18n, description_i18n',
        )
        .single()

      if (error) {
        if (/name_i18n|description_i18n|schema cache|PGRST204|42703/i.test(error.message)) {
          return {
            status: 500,
            body: {
              ok: false,
              error:
                'Category translations columns missing. Apply migrations/0040_category_i18n.sql in the Supabase SQL Editor.',
            },
          }
        }
        throw error
      }

      return { status: 200, body: { ok: true, row: data } }
    }

    if (path === '/api/admin/users' && method === 'GET') {
      const role = (req.searchParams.get('role') ?? 'all').toLowerCase()
      const q = (req.searchParams.get('q') ?? '').trim().toLowerCase()

      let query = sb
        .from('profiles')
        .select(
          'id, name, email, phone, role, city, country, bio, profile_image_url, rating, balance, created_at, verification_status, profile_photo_status, seller_onboarding_completed',
        )
        .order('created_at', { ascending: false })
        .limit(300)

      if (role === 'client' || role === 'seller') {
        query = query.eq('role', role)
      } else if (role === 'incomplete') {
        query = query.eq('role', 'seller').eq('seller_onboarding_completed', false)
      }

      const { data: profiles, error } = await query
      if (error) throw error

      const rows = profiles ?? []
      const sellerIds = rows.filter((p) => p.role === 'seller').map((p) => p.id as string)

      const sellerMap = new Map<string, { user_id: string; job_title: string | null }>()
      if (sellerIds.length) {
        const { data: sellers, error: sellersError } = await sb
          .from('seller_profiles')
          .select('user_id, job_title')
          .in('user_id', sellerIds)
        if (sellersError) throw sellersError
        for (const s of sellers ?? []) {
          sellerMap.set(s.user_id as string, {
            user_id: s.user_id as string,
            job_title: (s.job_title as string | null) ?? null,
          })
        }
      }

      // Auth metadata (last sign-in / confirmed) via Admin Auth API.
      const authById = new Map<
        string,
        {
          last_sign_in_at: string | null
          email_confirmed_at: string | null
          banned_until: string | null
          providers: string[]
        }
      >()
      try {
        for (let page = 1; page <= 5; page += 1) {
          const { data: authPage, error: authError } = await sb.auth.admin.listUsers({
            page,
            perPage: 200,
          })
          if (authError) throw authError
          const users = authPage?.users ?? []
          for (const u of users) {
            const providers = (u.app_metadata?.providers as string[] | undefined) ??
              (u.app_metadata?.provider ? [String(u.app_metadata.provider)] : [])
            authById.set(u.id, {
              last_sign_in_at: u.last_sign_in_at ?? null,
              email_confirmed_at: u.email_confirmed_at ?? null,
              banned_until: (u as { banned_until?: string | null }).banned_until ?? null,
              providers,
            })
          }
          if (users.length < 200) break
        }
      } catch (authErr) {
        // Profiles still useful if Auth admin listing fails.
        console.error('[admin/users] auth.listUsers failed', authErr)
      }

      let enriched = rows.map((p) => {
        const auth = authById.get(p.id as string) ?? null
        return {
          ...p,
          seller: sellerMap.get(p.id as string) ?? null,
          auth,
        }
      })

      if (q) {
        enriched = enriched.filter((row) => {
          const hay = [
            row.name,
            row.email,
            row.phone,
            row.id,
            row.city,
            row.country,
            row.seller?.job_title,
          ]
            .filter(Boolean)
            .join(' ')
            .toLowerCase()
          return hay.includes(q)
        })
      }

      return {
        status: 200,
        body: {
          ok: true,
          rows: enriched,
          authMatched: authById.size,
        },
      }
    }

    if (
      (path === '/api/admin/users-delete' || path === '/api/admin/users/delete') &&
      method === 'POST'
    ) {
      const userId = targetUserId ?? ''
      if (!userId) {
        return { status: 400, body: { ok: false, error: 'userId is required' } }
      }

      const { error: prepareError } = await sb.rpc('prepare_account_deletion', {
        p_user_id: userId,
      })
      if (prepareError) {
        const msg = prepareError.message || String(prepareError)
        if (msg.includes('prepare_account_deletion') || msg.includes('Could not find')) {
          return {
            status: 500,
            body: {
              ok: false,
              error:
                'Apply migrations/0044_delete_account.sql in the Supabase SQL Editor, then retry.',
            },
          }
        }
        throw prepareError
      }

      // Best-effort storage cleanup (avatars + identity docs).
      const storagePaths = [
        `${userId}/avatar.jpg`,
        `${userId}/id_selfie.jpg`,
        `${userId}/company_doc.jpg`,
      ]
      try {
        await sb.storage.from('avatars').remove([`${userId}/avatar.jpg`])
      } catch (storageErr) {
        console.error('[admin/users-delete] avatars cleanup', storageErr)
      }
      try {
        await sb.storage.from('identity-docs').remove(storagePaths.slice(1))
      } catch (storageErr) {
        console.error('[admin/users-delete] identity-docs cleanup', storageErr)
      }

      const { error: profileError } = await sb.from('profiles').delete().eq('id', userId)
      if (profileError) throw profileError

      const { error: authError } = await sb.auth.admin.deleteUser(userId)
      if (authError) {
        // Profile may already be gone; still report Auth failure.
        throw authError
      }

      return { status: 200, body: { ok: true, deletedUserId: userId } }
    }

    if (
      (path === '/api/admin/users-block' || path === '/api/admin/users/block') &&
      method === 'POST'
    ) {
      const body = (req.body ?? {}) as { blocked?: boolean }
      const userId = targetUserId ?? ''
      const blocked = body.blocked === true
      if (!userId) {
        return { status: 400, body: { ok: false, error: 'userId is required' } }
      }

      // ~100 years matches the Supabase dashboard "ban" action. 'none' lifts it.
      const { data, error } = await sb.auth.admin.updateUserById(userId, {
        ban_duration: blocked ? '876000h' : 'none',
      })
      if (error) throw error

      return {
        status: 200,
        body: {
          ok: true,
          userId,
          blocked,
          banned_until: data.user?.banned_until ?? null,
        },
      }
    }

    return { status: 404, body: { ok: false, error: 'Not found' } }
  } catch (err) {
    console.error('[admin] route error', err)
    return fail(500, 'Request failed')
  }
}
