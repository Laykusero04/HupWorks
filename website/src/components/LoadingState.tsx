import { Spinner } from 'react-bootstrap'
import { PageSection } from './PageSection'

type LoadingStateProps = {
  label?: string
}

export function LoadingState({ label = 'Loading…' }: LoadingStateProps) {
  return (
    <PageSection bodyClassName="d-flex align-items-center justify-content-center gap-2 py-5 text-secondary">
      <Spinner animation="border" size="sm" role="status" />
      <span>{label}</span>
    </PageSection>
  )
}

export function EmptyState({ children }: { children: React.ReactNode }) {
  return (
    <PageSection bodyClassName="py-5 text-center text-secondary">{children}</PageSection>
  )
}
