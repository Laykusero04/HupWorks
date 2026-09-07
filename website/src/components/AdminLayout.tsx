import { NavLink, Outlet } from 'react-router-dom'
import './layout.css'

const nav = [
  { to: '/', label: 'Overview', end: true },
  { to: '/verification', label: 'Verification' },
  { to: '/reports', label: 'Reports' },
  { to: '/users', label: 'Users' },
  { to: '/jobs', label: 'Jobs & orders' },
  { to: '/catalog', label: 'Catalog' },
]

export function AdminLayout() {
  return (
    <div className="admin-shell">
      <aside className="admin-nav">
        <div className="brand">
          <span className="brand-mark">H</span>
          <div>
            <strong>HupWorks</strong>
            <p>Admin</p>
          </div>
        </div>
        <nav>
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <p className="nav-foot">
          Same Supabase project as the mobile app. See <code>docs/ADMIN_PANEL.md</code>.
        </p>
      </aside>
      <main className="admin-main">
        <Outlet />
      </main>
    </div>
  )
}
