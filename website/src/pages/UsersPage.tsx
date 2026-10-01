import { useCallback, useEffect, useMemo, useState } from 'react'
import { Badge, Collapse } from 'react-bootstrap'
import { EmptyState, LoadingState } from '../components/LoadingState'
import { PageHeader } from '../components/PageHeader'
import { PageSection } from '../components/PageSection'
import { QueueToolbar } from '../components/QueueToolbar'
import { StatusAlert } from '../components/StatusAlert'
import {
  deleteUser,
  fetchUsers,
  setUserBan,
  statusLabel,
  type AdminUserRow,
} from '../lib/adminApi'

type RoleFilter = 'all' | 'client' | 'seller' | 'incomplete'

function formatWhen(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function statusVariant(status: string | null | undefined) {
  if (status === 'verified') return 'success'
  if (status === 'rejected') return 'danger'
  if (status === 'pending') return 'warning'
  return 'secondary'
}

function isUserBanned(row: AdminUserRow) {
  const until = row.auth?.banned_until
  if (!until) return false
  const t = Date.parse(until)
  return Number.isFinite(t) && t > Date.now()
}

export function UsersPage() {
  const [rows, setRows] = useState<AdminUserRow[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [query, setQuery] = useState('')
  const [role, setRole] = useState<RoleFilter>('all')
  const [expandedId, setExpandedId] = useState<string | null>(null)
  const [actionId, setActionId] = useState<string | null>(null)
  const [actionKind, setActionKind] = useState<'ban' | 'delete' | null>(null)

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

  async function handleDelete(row: AdminUserRow) {
    const label = row.name || row.email || row.id
    const ok = window.confirm(
      `Permanently delete ${label}?\n\nThis cancels their open orders, removes profile data, and deletes the Auth user. This cannot be undone.`,
    )
    if (!ok) return
    setActionId(row.id)
    setActionKind('delete')
    setError(null)
    try {
      await deleteUser(row.id)
      setExpandedId(null)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setActionId(null)
      setActionKind(null)
    }
  }

  async function handleToggleBan(row: AdminUserRow) {
    const label = row.name || row.email || row.id
    const banned = isUserBanned(row)
    const ok = window.confirm(
      banned
        ? `Unblock ${label}?\n\nThey will be able to sign in again.`
        : `Block ${label}?\n\nThey will not be able to sign in. Their account and data stay intact (unlike Delete).`,
    )
    if (!ok) return
    setActionId(row.id)
    setActionKind('ban')
    setError(null)
    try {
      await setUserBan(row.id, !banned)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setActionId(null)
      setActionKind(null)
    }
  }

  return (
    <div>
      <PageHeader
        title="Users"
        subtitle="Clients and sellers from profiles, plus Auth sign-in info when available."
      />

      <QueueToolbar
        search={query}
        onSearchChange={setQuery}
        searchPlaceholder="Search name, email, phone, id…"
        onRefresh={() => void load()}
        refreshing={loading}
        tabs={[
          { key: 'all', label: 'All', count: role === 'all' && !loading ? rows.length : undefined },
          { key: 'client', label: 'Clients', count: role === 'client' && !loading ? rows.length : undefined },
          { key: 'seller', label: 'Sellers', count: role === 'seller' && !loading ? rows.length : undefined },
          {
            key: 'incomplete',
            label: 'Incomplete onboarding',
            count: role === 'incomplete' && !loading ? rows.length : undefined,
          },
        ]}
        activeTab={role}
        onTabChange={(key) => {
          setRole(key as RoleFilter)
          setExpandedId(null)
        }}
      />

      {error && <StatusAlert title="Error">{error}</StatusAlert>}

      {loading && <LoadingState label="Loading users…" />}

      {!loading && !error && rows.length === 0 && <EmptyState>No users match.</EmptyState>}

      {!loading && rows.length > 0 && (
        <>
          <p className="text-secondary small mb-2">
            Showing {rows.length}
            {role === 'all' ? ` · ${counts.clients} clients · ${counts.sellers} sellers` : ''}
          </p>
          <div className="d-flex flex-column gap-2">
            {rows.map((row) => {
              const open = expandedId === row.id
              const roleLabel =
                row.role === 'seller' ? 'Seller' : row.role === 'client' ? 'Client' : row.role
              const busy = actionId === row.id
              const banned = isUserBanned(row)
              return (
                <PageSection key={row.id} bodyClassName="py-3">
                  <button
                    type="button"
                    className="btn btn-link text-decoration-none text-start text-body p-0 w-100"
                    onClick={() => setExpandedId(open ? null : row.id)}
                    aria-expanded={open}
                  >
                    <div className="d-flex justify-content-between gap-3">
                      <div className="min-w-0">
                        <div className="fw-semibold">{row.name || row.email || row.id}</div>
                        <div className="small text-secondary text-truncate">
                          {roleLabel}
                          {row.email ? ` · ${row.email}` : ''}
                          {row.city || row.country
                            ? ` · ${[row.city, row.country].filter(Boolean).join(', ')}`
                            : ''}
                        </div>
                        <div className="d-flex flex-wrap gap-1 mt-2">
                          <Badge bg={statusVariant(row.profile_photo_status)} text={row.profile_photo_status === 'pending' ? 'dark' : undefined}>
                            Photo {statusLabel(row.profile_photo_status)}
                          </Badge>
                          <Badge bg={statusVariant(row.verification_status)} text={row.verification_status === 'pending' ? 'dark' : undefined}>
                            ID {statusLabel(row.verification_status)}
                          </Badge>
                          {row.role === 'seller' && (
                            <Badge bg={row.seller_onboarding_completed ? 'success' : 'secondary'}>
                              Onboarding {row.seller_onboarding_completed ? 'done' : 'incomplete'}
                            </Badge>
                          )}
                          {banned && <Badge bg="danger">Blocked</Badge>}
                        </div>
                      </div>
                      <span className="small text-secondary flex-shrink-0">{open ? 'Hide' : 'Details'}</span>
                    </div>
                  </button>

                  <Collapse in={open}>
                    <div>
                      <hr className="my-3" />
                      <div className="row g-3 small">
                        <div className="col-md-6">
                          <div className="text-secondary">User id</div>
                          <code className="mono-id" title={row.id}>
                            {row.id}
                          </code>
                        </div>
                        <div className="col-md-6">
                          <div className="text-secondary">Phone</div>
                          <div>{row.phone || '—'}</div>
                        </div>
                        <div className="col-md-6">
                          <div className="text-secondary">Joined</div>
                          <div>{formatWhen(row.created_at)}</div>
                        </div>
                        <div className="col-md-6">
                          <div className="text-secondary">Rating / balance</div>
                          <div>
                            {row.rating ?? '—'} / {row.balance ?? '—'}
                          </div>
                        </div>
                        {row.seller?.job_title && (
                          <div className="col-md-6">
                            <div className="text-secondary">Job title</div>
                            <div>{row.seller.job_title}</div>
                          </div>
                        )}
                        {row.bio && (
                          <div className="col-12">
                            <div className="text-secondary">Bio</div>
                            <div>{row.bio}</div>
                          </div>
                        )}
                        <div className="col-md-6">
                          <div className="text-secondary">Auth email confirmed</div>
                          <div>{formatWhen(row.auth?.email_confirmed_at)}</div>
                        </div>
                        <div className="col-md-6">
                          <div className="text-secondary">Auth providers</div>
                          <div>{row.auth?.providers?.length ? row.auth.providers.join(', ') : '—'}</div>
                        </div>
                        {row.auth?.last_sign_in_at && (
                          <div className="col-md-6">
                            <div className="text-secondary">Last sign-in</div>
                            <div>{formatWhen(row.auth.last_sign_in_at)}</div>
                          </div>
                        )}
                        <div className="col-md-6">
                          <div className="text-secondary">Account status</div>
                          <div>
                            {banned ? (
                              <>
                                <Badge bg="danger" className="me-2">
                                  Blocked
                                </Badge>
                                until {formatWhen(row.auth?.banned_until)}
                              </>
                            ) : (
                              'Active'
                            )}
                          </div>
                        </div>
                        {row.profile_image_url && (
                          <div className="col-12">
                            <a href={row.profile_image_url} target="_blank" rel="noreferrer">
                              Open profile image
                            </a>
                          </div>
                        )}
                        <div className="col-12 d-flex flex-wrap gap-2">
                          <button
                            type="button"
                            className={`btn btn-sm ${banned ? 'btn-outline-success' : 'btn-outline-warning'}`}
                            disabled={busy}
                            onClick={() => void handleToggleBan(row)}
                          >
                            {busy && actionKind === 'ban'
                              ? banned
                                ? 'Unblocking…'
                                : 'Blocking…'
                              : banned
                                ? 'Unblock'
                                : 'Block'}
                          </button>
                          <button
                            type="button"
                            className="btn btn-outline-danger btn-sm"
                            disabled={busy}
                            onClick={() => void handleDelete(row)}
                          >
                            {busy && actionKind === 'delete' ? 'Deleting…' : 'Delete account'}
                          </button>
                        </div>
                      </div>
                    </div>
                  </Collapse>
                </PageSection>
              )
            })}
          </div>
        </>
      )}
    </div>
  )
}
