import { useEffect, useRef, useState } from 'react'
import { Button, Dropdown, Nav, Offcanvas } from 'react-bootstrap'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

const nav = [
  { to: '/', label: 'Overview', end: true, icon: 'bi-speedometer2' },
  { to: '/verification', label: 'Seller verification', icon: 'bi-shield-check' },
  {
    to: '/employer-verification',
    label: 'Employer verification',
    icon: 'bi-building-check',
  },
  { to: '/reports', label: 'Reports', icon: 'bi-flag' },
  { to: '/users', label: 'Users', icon: 'bi-people' },
  { to: '/jobs', label: 'Jobs & orders', icon: 'bi-briefcase' },
  { to: '/catalog', label: 'Catalog', icon: 'bi-tags' },
]

function AccountBlock() {
  const { email, signOut } = useAuth()
  return (
    <div className="admin-account mt-auto px-2 py-2">
      {email && (
        <div className="admin-account-email text-truncate py-1" title={email}>
          {email}
        </div>
      )}
      <button
        type="button"
        className="admin-signout admin-nav-link d-flex align-items-center gap-2 border-0"
        onClick={() => void signOut()}
      >
        <i className="bi bi-box-arrow-right" aria-hidden />
        Sign out
      </button>
    </div>
  )
}

function SidebarNav({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <div className="d-flex flex-column flex-grow-1 h-100">
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
      <AccountBlock />
    </div>
  )
}

export function AdminLayout() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const { email, signOut } = useAuth()
  const location = useLocation()
  const firstRender = useRef(true)
  const focusAfterClose = useRef(false)
  const menuButtonRef = useRef<HTMLButtonElement>(null)

  function focusHeading() {
    const h1 = document.querySelector<HTMLElement>('main h1')
    if (h1) {
      h1.tabIndex = -1
      h1.focus({ preventScroll: true })
    }
  }

  // After navigation, move focus to the page heading (spec: a11y focus).
  // Also after a fresh sign-in (login passes state.focusHeading).
  useEffect(() => {
    const afterLogin = (location.state as { focusHeading?: boolean } | null)?.focusHeading
    if (firstRender.current) {
      firstRender.current = false
      if (!afterLogin) return
    }
    if (mobileOpen) return // offcanvas onExited focuses instead
    focusHeading()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.pathname, location.key])

  return (
    <div className="admin-shell">
      <aside className="admin-sidebar d-none d-lg-flex flex-column">
        <SidebarNav />
      </aside>

      <div className="admin-content d-flex flex-column min-vh-100">
        <header className="admin-topbar d-lg-none d-flex align-items-center gap-2 px-3 py-2 border-bottom bg-white">
          <Button
            variant="outline-secondary"
            className="admin-hit admin-topbtn"
            ref={menuButtonRef}
            aria-label="Open menu"
            onClick={() => setMobileOpen(true)}
          >
            <i className="bi bi-list" aria-hidden />
          </Button>
          <strong>HupWorks Admin</strong>
          <Dropdown align="end" className="ms-auto">
            <Dropdown.Toggle
              variant="outline-secondary"
              className="admin-hit admin-topbtn"
              aria-label="Account menu"
              bsPrefix="btn"
            >
              <i className="bi bi-person-circle" aria-hidden />
            </Dropdown.Toggle>
            <Dropdown.Menu>
              {email && <Dropdown.ItemText className="text-break">{email}</Dropdown.ItemText>}
              <Dropdown.Item as="button" type="button" onClick={() => void signOut()}>
                <i className="bi bi-box-arrow-right me-2" aria-hidden />
                Sign out
              </Dropdown.Item>
            </Dropdown.Menu>
          </Dropdown>
        </header>

        <main className="admin-main flex-grow-1 p-3 p-md-4">
          <Outlet />
        </main>
      </div>

      <Offcanvas
        show={mobileOpen}
        onHide={() => setMobileOpen(false)}
        restoreFocus={!focusAfterClose.current}
        onExited={() => {
          if (focusAfterClose.current) {
            focusAfterClose.current = false
            // Defer so nothing else (Bootstrap focus restore) wins.
            requestAnimationFrame(() => setTimeout(focusHeading, 0))
          } else {
            // WebKit doesn't focus buttons on mouse click, so Bootstrap's
            // restoreFocus has no target; return focus to the trigger explicitly.
            menuButtonRef.current?.focus()
          }
        }}
        className="admin-offcanvas"
        aria-labelledby="admin-menu-title"
      >
        <Offcanvas.Header closeButton closeVariant="white">
          <Offcanvas.Title id="admin-menu-title" className="text-white">Menu</Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body className="p-0">
          <SidebarNav
            onNavigate={() => {
              focusAfterClose.current = true
              setMobileOpen(false)
            }}
          />
        </Offcanvas.Body>
      </Offcanvas>
    </div>
  )
}
