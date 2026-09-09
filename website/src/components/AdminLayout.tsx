import { useState } from 'react'
import { Button, Nav, Offcanvas } from 'react-bootstrap'
import { NavLink, Outlet } from 'react-router-dom'

const nav = [
  { to: '/', label: 'Overview', end: true, icon: 'bi-speedometer2' },
  { to: '/verification', label: 'Verification', icon: 'bi-shield-check' },
  { to: '/reports', label: 'Reports', icon: 'bi-flag' },
  { to: '/users', label: 'Users', icon: 'bi-people' },
  { to: '/jobs', label: 'Jobs & orders', icon: 'bi-briefcase' },
  { to: '/catalog', label: 'Catalog', icon: 'bi-tags' },
]

function SidebarNav({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <>
      <div className="admin-brand d-flex align-items-center gap-2 px-3 py-3">
        <span className="admin-brand-mark">H</span>
        <div>
          <strong className="d-block text-white">HupWorks</strong>
          <span className="small text-white-50">Admin</span>
        </div>
      </div>
      <Nav className="flex-column admin-side-nav px-2 pb-3">
        {nav.map((item) => (
          <Nav.Link
            key={item.to}
            as={NavLink}
            to={item.to}
            end={item.end}
            className="admin-nav-link d-flex align-items-center gap-2"
            onClick={onNavigate}
          >
            <i className={`bi ${item.icon}`} aria-hidden />
            {item.label}
          </Nav.Link>
        ))}
      </Nav>
    </>
  )
}

export function AdminLayout() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <div className="admin-shell">
      <aside className="admin-sidebar d-none d-lg-flex flex-column">
        <SidebarNav />
      </aside>

      <div className="admin-content d-flex flex-column min-vh-100">
        <header className="admin-topbar d-lg-none d-flex align-items-center gap-2 px-3 py-2 border-bottom bg-white">
          <Button
            variant="outline-secondary"
            size="sm"
            aria-label="Open menu"
            onClick={() => setMobileOpen(true)}
          >
            <i className="bi bi-list" />
          </Button>
          <strong>HupWorks Admin</strong>
        </header>

        <main className="admin-main flex-grow-1 p-3 p-md-4">
          <Outlet />
        </main>
      </div>

      <Offcanvas
        show={mobileOpen}
        onHide={() => setMobileOpen(false)}
        className="admin-offcanvas"
      >
        <Offcanvas.Header closeButton closeVariant="white">
          <Offcanvas.Title className="text-white">Menu</Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body className="p-0">
          <SidebarNav onNavigate={() => setMobileOpen(false)} />
        </Offcanvas.Body>
      </Offcanvas>
    </div>
  )
}
