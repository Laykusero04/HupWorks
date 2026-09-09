import type { ReactNode } from 'react'
import { Card } from 'react-bootstrap'

type PageSectionProps = {
  children: ReactNode
  className?: string
  bodyClassName?: string
}

export function PageSection({ children, className = '', bodyClassName = '' }: PageSectionProps) {
  return (
    <Card className={`border-0 shadow-sm ${className}`.trim()}>
      <Card.Body className={bodyClassName}>{children}</Card.Body>
    </Card>
  )
}
