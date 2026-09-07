import { useEffect, useState } from 'react'
import { fetchReports, type ReportRow } from '../lib/adminApi'

function personLabel(
  person: ReportRow['reporter'] | ReportRow['reported'],
  fallbackId: string | null,
) {
  if (person?.name) {
    return person.email ? `${person.name} (${person.email})` : person.name
  }
  return fallbackId ?? '—'
}

export function ReportsPage() {
  const [rows, setRows] = useState<ReportRow[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    async function load() {
      setLoading(true)
      setError(null)
      try {
        const res = await fetchReports()
        if (!cancelled) setRows(res.rows)
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : String(err))
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="page">
      <h1>Reports</h1>
      <p className="lede">Open and reviewing abuse reports from the app.</p>

      {error && (
        <section className="status-banner bad">
          <strong>Error</strong>
          <span>{error}</span>
        </section>
      )}

      {loading && <section className="panel empty">Loading reports…</section>}

      {!loading && !error && rows.length === 0 && (
        <section className="panel empty">No open reports.</section>
      )}

      <div className="card-list">
        {rows.map((row) => (
          <article key={row.id} className="panel">
            <h2>{row.reason}</h2>
            <p className="muted">
              {new Date(row.created_at).toLocaleString()} · {row.status}
              {row.pair_blocked ? ' · soft-blocked pair' : ''}
              {row.unpaid_completed ? ' · unpaid completed order' : ''}
            </p>
            {row.details && <p>{row.details}</p>}
            <p className="muted">
              Reporter {personLabel(row.reporter, row.reporter_id)}
              {row.reported_user_id
                ? ` → ${personLabel(row.reported, row.reported_user_id)}`
                : ''}
            </p>
            {(row.job_post_id || row.order_id || row.order) && (
              <p className="muted">
                {row.job_post_id ? `Job ${row.job_post_id}` : ''}
                {row.job_post_id && row.order_id ? ' · ' : ''}
                {row.order
                  ? `Order ${row.order.id} (${row.order.status ?? 'unknown'}${
                      row.order.payment_received_at
                        ? ', payment marked'
                        : row.order.status === 'completed'
                          ? ', payment not marked'
                          : ''
                    })`
                  : row.order_id
                    ? `Order ${row.order_id}`
                    : ''}
              </p>
            )}
          </article>
        ))}
      </div>
    </div>
  )
}
