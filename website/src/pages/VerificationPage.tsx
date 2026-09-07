import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  fetchVerifications,
  formatLanguages,
  formatSkills,
  reviewVerification,
  statusLabel,
  type ReviewTrack,
  type VerificationRow,
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

export function VerificationPage() {
  const [tab, setTab] = useState<Tab>('pending')
  const [rows, setRows] = useState<VerificationRow[]>([])
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
      const res = await fetchVerifications(tab)
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

  useEffect(() => {
    if (!lightbox) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setLightbox(null)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [lightbox])

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return rows
    return rows.filter((row) => {
      const p = row.profile
      const hay = [p?.name, p?.email, p?.phone, row.seller?.job_title, row.user_id]
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
      const label = track === 'profile' ? 'profile photo' : 'face + ID'
      const reason = window.prompt(`Rejection reason for ${label}:`)
      if (!reason?.trim()) return
      rejectionReason = reason.trim()
    }

    const key = `${userId}:${track}`
    setBusyKey(key)
    try {
      await reviewVerification({ userId, track, decision, rejectionReason })

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
            return { ...row, profile, status: track === 'identity' ? decision : row.status }
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
    <div className="page queue-page">
      <div className="queue-top">
        <div>
          <h1>Verification</h1>
          <p className="lede tight">
            Each column is its own decision: left = profile photo, right = face + ID.
          </p>
        </div>
        <div className="queue-tools">
          <input
            className="search-input"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search name, email, phone…"
          />
          <button type="button" className="btn ghost" onClick={() => void load()} disabled={loading}>
            Refresh
          </button>
        </div>
      </div>

      <div className="tabs">
        {(['pending', 'verified', 'rejected'] as Tab[]).map((value) => (
          <button
            key={value}
            type="button"
            className={tab === value ? 'tab active' : 'tab'}
            onClick={() => {
              setTab(value)
              setExpandedId(null)
            }}
          >
            {value}
            {value === tab && !loading ? ` · ${filtered.length}` : ''}
          </button>
        ))}
      </div>

      {error && (
        <section className="status-banner bad">
          <strong>Error</strong>
          <span>{error}</span>
        </section>
      )}

      {loading && <section className="panel empty">Loading queue…</section>}

      {!loading && !error && filtered.length === 0 && (
        <section className="panel empty">
          No {tab} sellers{query ? ' match your search' : ''}.
        </section>
      )}

      {!loading && filtered.length > 0 && (
        <div className="queue-table">
          <div className="queue-head three">
            <span>Seller</span>
            <span className="head-photo">Profile photo</span>
            <span className="head-id">Face + ID</span>
          </div>

          {filtered.map((row) => {
            const profile = row.profile
            const seller = row.seller
            const photoStatus = profile?.profile_photo_status ?? 'unverified'
            const identityStatus = profile?.verification_status ?? row.status ?? 'unverified'
            const photoUrl = profile?.profile_image_url
            const open = expandedId === row.user_id
            const photoBusy = busyKey === `${row.user_id}:profile`
            const idBusy = busyKey === `${row.user_id}:identity`
            const dob =
              row.privateDetails?.date_of_birth ||
              [seller?.birth_year, seller?.birth_month, seller?.birth_day]
                .filter((v) => v != null)
                .join('-') ||
              '—'

            return (
              <article key={row.user_id} className={`queue-row three ${open ? 'open' : ''}`}>
                <button
                  type="button"
                  className="queue-seller"
                  onClick={() => setExpandedId(open ? null : row.user_id)}
                >
                  <div className="avatar-wrap sm">
                    {photoUrl ? (
                      <img src={photoUrl} alt="" />
                    ) : (
                      <div className="avatar-fallback">
                        {(profile?.name || '?').slice(0, 1).toUpperCase()}
                      </div>
                    )}
                  </div>
                  <div className="queue-seller-text">
                    <strong>{profile?.name || 'Unnamed'}</strong>
                    <span>
                      {seller?.job_title || 'Seller'}
                      {profile?.city ? ` · ${profile.city}` : ''}
                    </span>
                    <span className="mono">{profile?.email || row.user_id.slice(0, 8)}</span>
                  </div>
                  <span className="expand-hint">{open ? 'Hide' : 'Details'}</span>
                </button>

                <TrackCell
                  kind="photo"
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

                <TrackCell
                  kind="id"
                  title="Face + ID"
                  src={row.selfieUrl}
                  status={identityStatus}
                  busy={idBusy}
                  acceptLabel="Accept ID"
                  rejectLabel="Reject ID"
                  missingLabel="No face + ID"
                  onOpen={() =>
                    row.selfieUrl &&
                    setLightbox({ src: row.selfieUrl, title: 'Face + ID selfie' })
                  }
                  onAccept={() => void onReview(row.user_id, 'identity', 'verified')}
                  onReject={() => void onReview(row.user_id, 'identity', 'rejected')}
                />

                {open && (
                  <div className="queue-details">
                    <div>
                      <span className="muted">Phone</span>
                      <p>{profile?.phone || '—'}</p>
                    </div>
                    <div>
                      <span className="muted">Address</span>
                      <p>{seller?.address || '—'}</p>
                    </div>
                    <div>
                      <span className="muted">DOB</span>
                      <p>{dob}</p>
                    </div>
                    <div>
                      <span className="muted">Skills</span>
                      <p>{formatSkills(seller?.skills)}</p>
                    </div>
                    <div>
                      <span className="muted">Languages</span>
                      <p>{formatLanguages(seller?.languages)}</p>
                    </div>
                    <div>
                      <span className="muted">About</span>
                      <p>{seller?.about || profile?.bio || '—'}</p>
                    </div>
                  </div>
                )}
              </article>
            )
          })}
        </div>
      )}

      {lightbox && (
        <div
          className="lightbox"
          role="dialog"
          aria-modal="true"
          onClick={() => setLightbox(null)}
        >
          <div className="lightbox-panel" onClick={(e) => e.stopPropagation()}>
            <div className="lightbox-bar">
              <strong>{lightbox.title}</strong>
              <div className="actions compact">
                <a className="btn ghost sm" href={lightbox.src} target="_blank" rel="noreferrer">
                  Open tab
                </a>
                <button type="button" className="btn ghost sm" onClick={() => setLightbox(null)}>
                  Close
                </button>
              </div>
            </div>
            <img src={lightbox.src} alt={lightbox.title} />
          </div>
        </div>
      )}
    </div>
  )
}

function TrackCell({
  kind,
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
  kind: 'photo' | 'id'
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
    <div className={`track-cell track-${kind}`}>
      <div className="track-cell-top">
        <strong>{title}</strong>
        <span className={`pill ${status}`}>{statusLabel(status)}</span>
      </div>

      {hasImage ? (
        <button
          type="button"
          className={`thumb wide ${kind === 'photo' ? 'thumb-photo' : 'thumb-id'}`}
          onClick={onOpen}
          title={`Maximize ${title}`}
        >
          <img src={src!} alt={title} />
          <span className="thumb-overlay">
            <span className="zoom-hint">Click to enlarge</span>
          </span>
        </button>
      ) : (
        <div
          className={`thumb wide empty-thumb ${kind === 'photo' ? 'thumb-photo' : 'thumb-id'}`}
        >
          <span>{missingLabel}</span>
        </div>
      )}

      <div className="track-buttons">
        {status === 'verified' ? (
          <span className="pill verified full">Accepted</span>
        ) : (
          <button
            type="button"
            className={`btn good sm full ${kind === 'id' ? 'btn-id' : 'btn-photo'}`}
            disabled={busy || !hasImage || !canAccept(status)}
            onClick={onAccept}
          >
            {acceptLabel}
          </button>
        )}
        {status === 'rejected' ? (
          <span className="pill rejected full">Rejected</span>
        ) : (
          <button
            type="button"
            className="btn bad sm full"
            disabled={busy || !hasImage || !canReject(status)}
            onClick={onReject}
          >
            {rejectLabel}
          </button>
        )}
      </div>
    </div>
  )
}
