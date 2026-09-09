import type { ReactNode } from 'react'

type PageHeaderProps = {
  title: string
  subtitle?: string
  actions?: ReactNode
}

export function PageHeader({ title, subtitle, actions }: PageHeaderProps) {
  return (
    <div className="page-header d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div className="min-w-0">
        <h1 className="h3 mb-1">{title}</h1>
        {subtitle ? <p className="text-secondary mb-0">{subtitle}</p> : null}
      </div>
      {actions ? <div className="page-header-actions d-flex flex-wrap align-items-center gap-2">{actions}</div> : null}
    </div>
  )
}
