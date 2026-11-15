import { Spinner } from 'react-bootstrap'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { loginUrl } from '../lib/authRedirect'
import { useAuth } from './AuthContext'

export function FullPageSpinner() {
  return (
    <div className="min-vh-100 d-flex align-items-center justify-content-center">
      <Spinner animation="border" role="status">
        <span className="visually-hidden">Loading</span>
      </Spinner>
    </div>
  )
}

/** Gate for admin routes. Real enforcement is server-side on /api/admin/*. */
export function RequireAdmin() {
  const { session, loading } = useAuth()
  const location = useLocation()
  if (loading) return <FullPageSpinner />
  if (!session) {
    return <Navigate to={loginUrl(location.pathname + location.search)} replace />
  }
  return <Outlet />
}
