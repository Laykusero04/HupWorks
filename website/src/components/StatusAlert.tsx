import { Alert } from 'react-bootstrap'

type StatusAlertProps = {
  variant?: 'danger' | 'warning' | 'info' | 'success'
  title?: string
  children: React.ReactNode
}

export function StatusAlert({ variant = 'danger', title, children }: StatusAlertProps) {
  return (
    <Alert variant={variant} className="mb-3">
      {title ? <Alert.Heading className="h6 mb-1">{title}</Alert.Heading> : null}
      <div className="mb-0 small">{children}</div>
    </Alert>
  )
}
