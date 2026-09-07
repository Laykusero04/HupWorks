import { createClient, type SupabaseClient } from '@supabase/supabase-js'

export type AdminRequest = {
  path: string
  method: string
  searchParams: URLSearchParams
  body: unknown
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

function errorMessage(err: unknown): string {
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message: unknown }).message)
  }
  if (err instanceof Error) return err.message
  return String(err)
}

/** Shared admin API used by Vite middleware and Vercel serverless. */
export async function handleAdminRequest(req: AdminRequest): Promise<AdminResponse> {
  try {
    const path = req.path.replace(/\/+$/, '') || '/'
    const method = req.method.toUpperCase()
    const sb = adminClient()

    if (path === '/api/admin/health' && method === 'GET') {
      const { error } = await sb.from('profiles').select('id', { count: 'exact', head: true })
      if (error) throw error
      const reportsProbe = await sb.from('user_reports').select('id', { count: 'exact', head: true })
      const blocksProbe = await sb.from('user_blocks').select('id', { count: 'exact', head: true })
      return {
        status: 200,
        body: {
          ok: true,
          usingServiceRole: Boolean(process.env.SUPABASE_SECRET_KEY),
          userReportsReady: !reportsProbe.error,
          userBlocksReady: !blocksProbe.error,
          schemaHint:
            reportsProbe.error || blocksProbe.error
              ? 'Apply migrations/0039_user_blocks.sql in the Supabase SQL Editor (includes user_reports + soft blocks).'
              : null,
        },
      }
    }

    if (path === '/api/admin/overview' && method === 'GET') {
      const [
        pendingIdentity,
        pendingProfilePhoto,
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
        return {
          status: 500,
          body: { ok: false, error: errors.map((e) => e!.message).join('; ') },
        }
      }

      return {
        status: 200,
        body: {
          ok: true,
          pendingVerification:
            (pendingIdentity.count ?? 0) + (pendingProfilePhoto.count ?? 0),
          pendingIdentity: pendingIdentity.count ?? 0,
          pendingProfilePhoto: pendingProfilePhoto.count ?? 0,
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

    if (path === '/api/admin/verifications/review' && method === 'POST') {
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

    if (path === '/api/admin/categories/update' && method === 'POST') {
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

    return { status: 404, body: { ok: false, error: 'Not found' } }
  } catch (err) {
    return { status: 500, body: { ok: false, error: errorMessage(err) } }
  }
}
