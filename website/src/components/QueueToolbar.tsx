import type { ReactNode } from 'react'
import { Button, Form, Nav } from 'react-bootstrap'

export type QueueTab = {
  key: string
  label: string
  count?: number | string
}

type QueueToolbarProps = {
  tabs?: QueueTab[]
  activeTab?: string
  onTabChange?: (key: string) => void
  search?: string
  onSearchChange?: (value: string) => void
  searchPlaceholder?: string
  onRefresh?: () => void
  refreshing?: boolean
  extra?: ReactNode
}

export function QueueToolbar({
  tabs,
  activeTab,
  onTabChange,
  search,
  onSearchChange,
  searchPlaceholder = 'Search…',
  onRefresh,
  refreshing,
  extra,
}: QueueToolbarProps) {
  return (
    <div className="queue-toolbar mb-3">
      <div className="d-flex flex-wrap align-items-center gap-2 mb-2">
        {onSearchChange != null && (
          <Form.Control
            type="search"
            value={search ?? ''}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder={searchPlaceholder}
            className="queue-search"
            style={{ maxWidth: 280 }}
          />
        )}
        {extra}
        {onRefresh && (
          <Button variant="outline-secondary" size="sm" onClick={onRefresh} disabled={refreshing}>
            <i className="bi bi-arrow-clockwise me-1" aria-hidden />
            Refresh
          </Button>
        )}
      </div>
      {tabs && tabs.length > 0 && onTabChange && (
        <Nav variant="tabs" activeKey={activeTab} onSelect={(k) => k && onTabChange(k)}>
          {tabs.map((tab) => (
            <Nav.Item key={tab.key}>
              <Nav.Link eventKey={tab.key}>
                {tab.label}
                {tab.count != null ? ` · ${tab.count}` : ''}
              </Nav.Link>
            </Nav.Item>
          ))}
        </Nav>
      )}
    </div>
  )
}
