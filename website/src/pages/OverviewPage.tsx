import { useEffect, useState } from 'react'
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

  return (
    <div className="page">
      <h1>Overview</h1>
      <p className="lede">
        Live ops snapshot from the same Supabase project as the Flutter app.
      </p>

      <section className={`status-banner ${error ? 'bad' : health?.ok ? 'good' : 'pending'}`}>
        {loading && <strong>Connecting to Supabase…</strong>}
        {!loading && error && (
          <>
            <strong>Not connected</strong>
            <span>{error}</span>
            <span className="hint">
              Restart <code>npm run dev</code> after editing <code>website/.env</code>. Need{' '}
              <code>VITE_SUPABASE_URL</code>, <code>VITE_SUPABASE_ANON_KEY</code>, and{' '}
              <code>SUPABASE_SECRET_KEY</code>.
            </span>
          </>
        )}
        {!loading && !error && health?.ok && (
          <>
            <strong>Connected</strong>
            <span>{health.projectUrl}</span>
            <span className="hint">
              {health.usingServiceRole
                ? 'Using service role via /api/admin (dev server only).'
                : 'Service role missing — admin queues may fail RLS.'}
            </span>
            {health.schemaHint && (
              <span className="hint">Schema: {health.schemaHint}</span>
            )}
          </>
        )}
      </section>

      <div className="kpi-grid">
        <div className="kpi">
          <span>Pending reviews (photo + ID)</span>
          <strong>{loading ? '…' : (overview?.pendingVerification ?? '—')}</strong>
        </div>
        <div className="kpi">
          <span>Open reports</span>
          <strong>{loading ? '…' : (overview?.openReports ?? '—')}</strong>
        </div>
        <div className="kpi">
          <span>Unpaid completed orders</span>
          <strong>{loading ? '…' : (overview?.unpaidCompleted ?? '—')}</strong>
        </div>
        <div className="kpi">
          <span>Active contracts</span>
          <strong>{loading ? '…' : (overview?.activeContracts ?? '—')}</strong>
        </div>
      </div>

      <section className="panel">
        <h2>Next queues</h2>
        <ul>
          <li>Verification — approve / reject pending ID selfies</li>
          <li>Reports — moderate open / reviewing abuse reports</li>
        </ul>
      </section>
    </div>
  )
}
