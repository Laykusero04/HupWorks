import { useCallback, useEffect, useState } from 'react'
import { Badge, Button, Table } from 'react-bootstrap'
import { EmptyState, LoadingState } from '../components/LoadingState'
import { PageHeader } from '../components/PageHeader'
import { PageSection } from '../components/PageSection'
import { StatusAlert } from '../components/StatusAlert'
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

function shortId(id: string | null | undefined) {
  if (!id) return '—'
  return id.length > 12 ? `${id.slice(0, 8)}…` : id
}

export function ReportsPage() {
  const [rows, setRows] = useState<ReportRow[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchReports()
      setRows(res.rows)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="Open and reviewing abuse reports from the app."
        actions={
          <Button variant="outline-secondary" size="sm" onClick={() => void load()} disabled={loading}>
            <i className="bi bi-arrow-clockwise me-1" aria-hidden />
            Refresh
          </Button>
        }
      />

      {error && (
        <StatusAlert title="Error">{error}</StatusAlert>
      )}

      {loading && <LoadingState label="Loading reports…" />}

      {!loading && !error && rows.length === 0 && <EmptyState>No open reports.</EmptyState>}

      {!loading && rows.length > 0 && (
        <PageSection bodyClassName="p-0">
          <Table responsive hover className="mb-0 align-middle">
            <thead className="table-light">
              <tr>
                <th>Reason</th>
                <th>Status</th>
                <th>Parties</th>
                <th>Context</th>
                <th>When</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    <div className="fw-semibold">{row.reason}</div>
                    {row.details ? <div className="small text-secondary mt-1">{row.details}</div> : null}
                  </td>
                  <td>
                    <Badge bg="warning" text="dark" className="text-capitalize">
                      {row.status}
                    </Badge>
                    {row.pair_blocked ? (
                      <div className="small text-secondary mt-1">Soft-blocked pair</div>
                    ) : null}
                    {row.unpaid_completed ? (
                      <div className="small text-secondary">Unpaid completed</div>
                    ) : null}
                  </td>
                  <td className="small">
                    <div>{personLabel(row.reporter, row.reporter_id)}</div>
                    {row.reported_user_id ? (
                      <div className="text-secondary">
                        → {personLabel(row.reported, row.reported_user_id)}
                      </div>
                    ) : null}
                  </td>
                  <td className="small text-secondary">
                    {row.job_post_id ? (
                      <div>
                        Job{' '}
                        <span className="mono-id" title={row.job_post_id}>
                          {shortId(row.job_post_id)}
                        </span>
                      </div>
                    ) : null}
                    {row.order ? (
                      <div>
                        Order{' '}
                        <span className="mono-id" title={row.order.id}>
                          {shortId(row.order.id)}
                        </span>{' '}
                        ({row.order.status ?? 'unknown'}
                        {row.order.payment_received_at
                          ? ', payment marked'
                          : row.order.status === 'completed'
                            ? ', payment not marked'
                            : ''}
                        )
                      </div>
                    ) : row.order_id ? (
                      <div>
                        Order{' '}
                        <span className="mono-id" title={row.order_id}>
                          {shortId(row.order_id)}
                        </span>
                      </div>
                    ) : null}
                    {!row.job_post_id && !row.order_id && !row.order ? '—' : null}
                  </td>
                  <td className="small text-nowrap">{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </Table>
        </PageSection>
      )}
    </div>
  )
}
