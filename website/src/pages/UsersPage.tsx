import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchUsers, statusLabel, type AdminUserRow } from '../lib/adminApi'

type RoleFilter = 'all' | 'client' | 'seller' | 'incomplete'

function formatWhen(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

export function UsersPage() {
  const [rows, setRows] = useState<AdminUserRow[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [query, setQuery] = useState('')
  const [role, setRole] = useState<RoleFilter>('all')
  const [expandedId, setExpandedId] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchUsers(role, query)
      setRows(res.rows)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }, [role, query])

  useEffect(() => {
    const t = window.setTimeout(() => {
      void load()
    }, query ? 250 : 0)
    return () => window.clearTimeout(t)
  }, [load, query])

  const counts = useMemo(() => {
    return {
      all: rows.length,
      clients: rows.filter((r) => r.role === 'client').length,
      sellers: rows.filter((r) => r.role === 'seller').length,
    }
  }, [rows])

  return (
    <div className="page queue-page">
      <div className="queue-top">
        <div>
          <h1>Users</h1>
          <p className="lede tight">
            Clients and sellers from <code>profiles</code>, plus Auth sign-in info when available.
          </p>
        </div>
        <div className="queue-tools">
          <input
            className="search-input"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search name, email, phone, id…"
          />
          <button type="button" className="btn ghost" onClick={() => void load()} disabled={loading}>
            Refresh
          </button>
        </div>
      </div>

      <div className="tabs">
        {(
          [
            ['all', 'All'],
            ['client', 'Clients'],
            ['seller', 'Sellers'],
            ['incomplete', 'Incomplete onboarding'],
          ] as const
        ).map(([key, label]) => (
          <button
            key={key}
            type="button"
            className={role === key ? 'tab active' : 'tab'}
            onClick={() => {
              setRole(key)
              setExpandedId(null)
            }}
          >
            {label}
            {key === role && !loading ? ` · ${rows.length}` : ''}
          </button>
        ))}
      </div>

      {error && (
        <section className="status-banner bad">
          <strong>Error</strong>
          <span>{error}</span>
        </section>
      )}

      {loading && <section className="panel empty">Loading users…</section>}

      {!loading && !error && rows.length === 0 && (
        <section className="panel empty">No users match.</section>
      )}

      {!loading && !error && rows.length > 0 && (
        <p className="muted" style={{ marginBottom: '0.75rem' }}>
          Showing {rows.length}
          {role === 'all' ? ` · ${counts.clients} clients · ${counts.sellers} sellers` : ''}
        </p>
      )}

      <div className="card-list">
        {rows.map((row) => {
          const open = expandedId === row.id
          const roleLabel = row.role === 'seller' ? 'Seller' : row.role === 'client' ? 'Client' : row.role
          return (
            <article key={row.id} className="panel catalog-card">
              <button
                type="button"
                className="catalog-summary"
                onClick={() => setExpandedId(open ? null : row.id)}
              >
                <div>
                  <h2>{row.name || row.email || row.id}</h2>
                  <p className="muted">
                    {roleLabel}
                    {row.email ? ` · ${row.email}` : ''}
                    {row.city || row.country
                      ? ` · ${[row.city, row.country].filter(Boolean).join(', ')}`
                      : ''}
                  </p>
                  <p className="muted">
                    Photo {statusLabel(row.profile_photo_status)} · ID{' '}
                    {statusLabel(row.verification_status)}
                    {row.role === 'seller'
                      ? ` · onboarding ${row.seller_onboarding_completed ? 'done' : 'incomplete'}`
                      : ''}
                    {row.auth?.last_sign_in_at
                      ? ` · last sign-in ${formatWhen(row.auth.last_sign_in_at)}`
                      : row.auth
                        ? ' · never signed in'
                        : ''}
                  </p>
                </div>
                <span className="muted">{open ? 'Hide' : 'Details'}</span>
              </button>

              {open && (
                <div className="catalog-editor">
                  <p>
                    <strong>User id</strong>
                    <br />
                    <code>{row.id}</code>
                  </p>
                  <p>
                    <strong>Phone</strong> {row.phone || '—'}
                  </p>
                  <p>
                    <strong>Joined</strong> {formatWhen(row.created_at)}
                  </p>
                  <p>
                    <strong>Rating / balance</strong>{' '}
                    {row.rating ?? '—'} / {row.balance ?? '—'}
                  </p>
                  {row.seller?.job_title && (
                    <p>
                      <strong>Job title</strong> {row.seller.job_title}
                    </p>
                  )}
                  {row.bio && (
                    <p>
                      <strong>Bio</strong> {row.bio}
                    </p>
                  )}
                  <p>
                    <strong>Auth email confirmed</strong>{' '}
                    {formatWhen(row.auth?.email_confirmed_at)}
                  </p>
                  <p>
                    <strong>Auth providers</strong>{' '}
                    {row.auth?.providers?.length ? row.auth.providers.join(', ') : '—'}
                  </p>
                  {row.auth?.banned_until && (
                    <p>
                      <strong>Banned until</strong> {formatWhen(row.auth.banned_until)}
                    </p>
                  )}
                  {row.profile_image_url && (
                    <p>
                      <a href={row.profile_image_url} target="_blank" rel="noreferrer">
                        Open profile image
                      </a>
                    </p>
                  )}
                </div>
              )}
            </article>
          )
        })}
      </div>
    </div>
  )
}
