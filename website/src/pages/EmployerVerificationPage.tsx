import { Fragment, useCallback, useEffect, useMemo, useState } from 'react'
import { Badge, Button, Col, Modal, Row, Table } from 'react-bootstrap'
import { EmptyState, LoadingState } from '../components/LoadingState'
import { PageHeader } from '../components/PageHeader'
import { PageSection } from '../components/PageSection'
import { QueueToolbar } from '../components/QueueToolbar'
import { StatusAlert } from '../components/StatusAlert'
import {
  fetchEmployerVerifications,
  reviewEmployerVerification,
  statusLabel,
  type EmployerVerificationRow,
  type ReviewTrack,
} from '../lib/adminApi'

type Tab = 'pending' | 'verified' | 'rejected'

type LightboxState = {
  src: string
  title: string
} | null

function canAccept(status: string | null | undefined) {
  return status !== 'verified'
}

function canReject(status: string | null | undefined) {
  return status !== 'rejected'
}

function statusBadge(status: string) {
  const variant =
    status === 'verified' ? 'success' : status === 'rejected' ? 'danger' : status === 'pending' ? 'warning' : 'secondary'
  return (
    <Badge bg={variant} text={variant === 'warning' ? 'dark' : undefined} className="text-capitalize">
      {statusLabel(status)}
    </Badge>
  )
}

function verifyTypeLabel(type: string | null | undefined) {
  if (type === 'company') return 'Company doc'
  if (type === 'personal_id') return 'Personal ID'
  return 'Not submitted'
}

export function EmployerVerificationPage() {
  const [tab, setTab] = useState<Tab>('pending')
  const [rows, setRows] = useState<EmployerVerificationRow[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [busyKey, setBusyKey] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [expandedId, setExpandedId] = useState<string | null>(null)
  const [lightbox, setLightbox] = useState<LightboxState>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchEmployerVerifications(tab)
      setRows(res.rows)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }, [tab])

  useEffect(() => {
    void load()
  }, [load])

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return rows
    return rows.filter((row) => {
      const p = row.profile
      const hay = [
        p?.name,
        p?.email,
        p?.phone,
        row.company_name,
        p?.company_name,
        row.user_id,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase()
      return hay.includes(q)
    })
  }, [rows, query])

  async function onReview(
    userId: string,
    track: ReviewTrack,
    decision: 'verified' | 'rejected',
  ) {
    let rejectionReason: string | undefined
    if (decision === 'rejected') {
      const label = track === 'profile' ? 'profile photo' : 'ID / company doc'
      const reason = window.prompt(`Rejection reason for ${label}:`)
      if (!reason?.trim()) return
      rejectionReason = reason.trim()
    }

    const key = `${userId}:${track}`
    setBusyKey(key)
    try {
      await reviewEmployerVerification({ userId, track, decision, rejectionReason })

      setRows((prev) =>
        prev
          .map((row) => {
            if (row.user_id !== userId || !row.profile) return row
            const profile = { ...row.profile }
            if (track === 'profile') {
              profile.profile_photo_status = decision
              profile.profile_photo_rejection_reason = rejectionReason ?? null
            } else {
              profile.verification_status = decision
              profile.verification_rejection_reason = rejectionReason ?? null
            }
            return {
              ...row,
              profile,
              status: track === 'identity' ? decision : row.status,
            }
          })
          .filter((row) => {
            if (tab !== 'pending') return true
            const photo = row.profile?.profile_photo_status
            const identity = row.profile?.verification_status ?? row.status
            return photo === 'pending' || identity === 'pending'
          }),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusyKey(null)
    }
  }

  return (
    <div>
      <PageHeader
        title="Employer verification"
        subtitle="Separate from sellers: profile photo and personal ID or company registration."
      />

      <QueueToolbar
        search={query}
        onSearchChange={setQuery}
        searchPlaceholder="Search name, email, company…"
        onRefresh={() => void load()}
        refreshing={loading}
        tabs={[
          { key: 'pending', label: 'Pending', count: tab === 'pending' && !loading ? filtered.length : undefined },
          { key: 'verified', label: 'Verified', count: tab === 'verified' && !loading ? filtered.length : undefined },
          { key: 'rejected', label: 'Rejected', count: tab === 'rejected' && !loading ? filtered.length : undefined },
        ]}
        activeTab={tab}
        onTabChange={(key) => {
          setTab(key as Tab)
          setExpandedId(null)
        }}
      />

      {error && <StatusAlert title="Error">{error}</StatusAlert>}

      {loading && <LoadingState label="Loading employer queue…" />}

      {!loading && !error && filtered.length === 0 && (
        <EmptyState>
          No {tab} employers{query ? ' match your search' : ''}.
        </EmptyState>
      )}

      {!loading && filtered.length > 0 && (
        <PageSection bodyClassName="p-0">
          <Table responsive className="mb-0 align-middle">
            <thead className="table-light">
              <tr>
                <th style={{ minWidth: 220 }}>Employer</th>
                <th style={{ minWidth: 180 }}>Profile photo</th>
                <th style={{ minWidth: 200 }}>ID / company</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((row) => {
                const profile = row.profile
                const photoStatus = profile?.profile_photo_status ?? 'unverified'
                const identityStatus = profile?.verification_status ?? row.status ?? 'unverified'
                const photoUrl = profile?.profile_image_url
                const open = expandedId === row.user_id
                const photoBusy = busyKey === `${row.user_id}:profile`
                const idBusy = busyKey === `${row.user_id}:identity`
                const companyName =
                  row.company_name || profile?.company_name || '—'
                const upgradeLabel = verifyTypeLabel(row.verify_type)

                return (
                  <Fragment key={row.user_id}>
                    <tr>
                      <td>
                        <button
                          type="button"
                          className="btn btn-link text-start text-decoration-none p-0 w-100"
                          onClick={() => setExpandedId(open ? null : row.user_id)}
                        >
                          <div className="d-flex align-items-center gap-2">
                            {photoUrl ? (
                              <img src={photoUrl} alt="" className="avatar-sm" />
                            ) : (
                              <div className="avatar-fallback">
                                {(profile?.name || '?').slice(0, 1).toUpperCase()}
                              </div>
                            )}
                            <div className="min-w-0">
                              <div className="fw-semibold text-body text-truncate">
                                {profile?.name || 'Unnamed'}
                              </div>
                              <div className="small text-secondary text-truncate">
                                {companyName !== '—' ? companyName : 'Employer'}
                                {profile?.city ? ` · ${profile.city}` : ''}
                              </div>
                              <div className="mono-id text-secondary text-truncate">
                                {profile?.email || row.user_id.slice(0, 8)}
                              </div>
                            </div>
                            <span className="small text-secondary ms-auto flex-shrink-0">
                              {open ? 'Hide' : 'Details'}
                            </span>
                          </div>
                        </button>
                      </td>
                      <td>
                        <TrackCell
                          title="Profile photo"
                          src={photoUrl}
                          status={photoStatus}
                          busy={photoBusy}
                          acceptLabel="Accept photo"
                          rejectLabel="Reject photo"
                          missingLabel="No profile photo"
                          onOpen={() =>
                            photoUrl && setLightbox({ src: photoUrl, title: 'Profile photo' })
                          }
                          onAccept={() => void onReview(row.user_id, 'profile', 'verified')}
                          onReject={() => void onReview(row.user_id, 'profile', 'rejected')}
                        />
                      </td>
                      <td>
                        <TrackCell
                          title={upgradeLabel}
                          src={row.docUrl}
                          status={identityStatus}
                          busy={idBusy}
                          acceptLabel="Accept docs"
                          rejectLabel="Reject docs"
                          missingLabel="No ID / company doc"
                          onOpen={() =>
                            row.docUrl &&
                            setLightbox({
                              src: row.docUrl,
                              title: upgradeLabel,
                            })
                          }
                          onAccept={() => void onReview(row.user_id, 'identity', 'verified')}
                          onReject={() => void onReview(row.user_id, 'identity', 'rejected')}
                        />
                      </td>
                    </tr>
                    {open && (
                      <tr className="table-light">
                        <td colSpan={3}>
                          <Row className="g-3 small px-1">
                            <Col md={4}>
                              <div className="text-secondary">Phone</div>
                              <div>{profile?.phone || '—'}</div>
                            </Col>
                            <Col md={4}>
                              <div className="text-secondary">Company</div>
                              <div>{companyName}</div>
                            </Col>
                            <Col md={4}>
                              <div className="text-secondary">Registration</div>
                              <div>
                                {row.company_registration_number ||
                                  profile?.company_registration_number ||
                                  '—'}
                              </div>
                            </Col>
                            <Col md={4}>
                              <div className="text-secondary">Website</div>
                              <div>
                                {row.company_website || profile?.company_website || '—'}
                              </div>
                            </Col>
                            <Col md={4}>
                              <div className="text-secondary">Verify path</div>
                              <div>{upgradeLabel}</div>
                            </Col>
                            <Col md={4}>
                              <div className="text-secondary">About</div>
                              <div>{profile?.bio || '—'}</div>
                            </Col>
                          </Row>
                        </td>
                      </tr>
                    )}
                  </Fragment>
                )
              })}
            </tbody>
          </Table>
        </PageSection>
      )}

      <Modal show={Boolean(lightbox)} onHide={() => setLightbox(null)} size="lg" centered>
        <Modal.Header closeButton>
          <Modal.Title>{lightbox?.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body className="text-center">
          {lightbox && <img src={lightbox.src} alt={lightbox.title} className="lightbox-img" />}
        </Modal.Body>
        <Modal.Footer>
          {lightbox && (
            <a
              className="btn btn-outline-secondary"
              href={lightbox.src}
              target="_blank"
              rel="noreferrer"
            >
              Open tab
            </a>
          )}
          <Button variant="secondary" onClick={() => setLightbox(null)}>
            Close
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

function TrackCell({
  title,
  src,
  status,
  busy,
  acceptLabel,
  rejectLabel,
  missingLabel,
  onOpen,
  onAccept,
  onReject,
}: {
  title: string
  src: string | null | undefined
  status: string
  busy: boolean
  acceptLabel: string
  rejectLabel: string
  missingLabel: string
  onOpen: () => void
  onAccept: () => void
  onReject: () => void
}) {
  const hasImage = Boolean(src)

  return (
    <div className="d-flex flex-column gap-2">
      <div className="d-flex align-items-center justify-content-between gap-2">
        <span className="small fw-semibold">{title}</span>
        {statusBadge(status)}
      </div>

      {hasImage ? (
        <button type="button" className="btn p-0 border-0 text-start" onClick={onOpen} title={`Maximize ${title}`}>
          <img src={src!} alt={title} className="verify-thumb" />
        </button>
      ) : (
        <div className="verify-thumb-empty">{missingLabel}</div>
      )}

      <div className="d-flex flex-column gap-1" style={{ maxWidth: 160 }}>
        {status === 'verified' ? (
          <Badge bg="success" className="w-100 py-2">
            Accepted
          </Badge>
        ) : (
          <Button
            size="sm"
            variant="success"
            disabled={busy || !hasImage || !canAccept(status)}
            onClick={onAccept}
          >
            {acceptLabel}
          </Button>
        )}
        {status === 'rejected' ? (
          <Badge bg="danger" className="w-100 py-2">
            Rejected
          </Badge>
        ) : (
          <Button
            size="sm"
            variant="outline-danger"
            disabled={busy || !hasImage || !canReject(status)}
            onClick={onReject}
          >
            {rejectLabel}
          </Button>
        )}
      </div>
    </div>
  )
}
