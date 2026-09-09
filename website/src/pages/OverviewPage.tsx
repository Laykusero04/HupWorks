import { useEffect, useState } from 'react'
import { Card, Col, Row, Spinner } from 'react-bootstrap'
import { Link } from 'react-router-dom'
import { EmptyState, LoadingState } from '../components/LoadingState'
import { PageHeader } from '../components/PageHeader'
import { StatusAlert } from '../components/StatusAlert'
import { fetchHealth, fetchOverview, type AdminHealth, type AdminOverview } from '../lib/adminApi'

export function OverviewPage() {
  const [health, setHealth] = useState<AdminHealth | null>(null)
  const [overview, setOverview] = useState<AdminOverview | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    async function load() {
      setLoading(true)
      setError(null)
      try {
        const [healthRes, overviewRes] = await Promise.all([fetchHealth(), fetchOverview()])
        if (cancelled) return
        setHealth(healthRes)
        setOverview(overviewRes)
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : String(err))
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [])

  const showServiceRoleWarning = !loading && !error && health?.ok && !health.usingServiceRole

  return (
    <div>
      <PageHeader
        title="Overview"
        subtitle="Live ops snapshot from the same Supabase project as the Flutter app."
      />

      {loading && (
        <StatusAlert variant="info" title="Connecting">
          <span className="d-inline-flex align-items-center gap-2">
            <Spinner animation="border" size="sm" /> Connecting to Supabase…
          </span>
        </StatusAlert>
      )}

      {!loading && error && (
        <StatusAlert variant="danger" title="Not connected">
          <p className="mb-2">{error}</p>
          <p className="mb-0">
            On Vercel: set <code>SUPABASE_URL</code> + <code>SUPABASE_SECRET_KEY</code>, then
            redeploy. Locally: put the same in <code>website/.env</code> and restart{' '}
            <code>npm run dev</code>.
          </p>
        </StatusAlert>
      )}

      {showServiceRoleWarning && (
        <StatusAlert variant="warning" title="Service role missing">
          Admin queues may fail RLS until <code>SUPABASE_SECRET_KEY</code> is configured.
          {health?.schemaHint ? (
            <span className="d-block mt-1">Schema: {health.schemaHint}</span>
          ) : null}
        </StatusAlert>
      )}

      {loading ? (
        <LoadingState label="Loading overview…" />
      ) : error ? (
        <EmptyState>Fix the connection above to load KPIs.</EmptyState>
      ) : (
        <Row className="g-3">
          <Col sm={6} xl={3}>
            <Card as={Link} to="/verification" className="kpi-card border-0 shadow-sm h-100">
              <Card.Body>
                <div className="text-secondary small mb-1">Pending reviews</div>
                <div className="kpi-value">{overview?.pendingVerification ?? '—'}</div>
                <div className="text-secondary small mt-1">Photo + ID</div>
              </Card.Body>
            </Card>
          </Col>
          <Col sm={6} xl={3}>
            <Card as={Link} to="/reports" className="kpi-card border-0 shadow-sm h-100">
              <Card.Body>
                <div className="text-secondary small mb-1">Open reports</div>
                <div className="kpi-value">{overview?.openReports ?? '—'}</div>
                <div className="text-secondary small mt-1">Abuse queue</div>
              </Card.Body>
            </Card>
          </Col>
          <Col sm={6} xl={3}>
            <Card className="border-0 shadow-sm h-100">
              <Card.Body>
                <div className="text-secondary small mb-1">Unpaid completed</div>
                <div className="kpi-value">{overview?.unpaidCompleted ?? '—'}</div>
                <div className="text-secondary small mt-1">Orders</div>
              </Card.Body>
            </Card>
          </Col>
          <Col sm={6} xl={3}>
            <Card className="border-0 shadow-sm h-100">
              <Card.Body>
                <div className="text-secondary small mb-1">Active contracts</div>
                <div className="kpi-value">{overview?.activeContracts ?? '—'}</div>
                <div className="text-secondary small mt-1">In progress</div>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}
    </div>
  )
}
