import { PageHeader } from '../components/PageHeader'
import { EmptyState } from '../components/LoadingState'

export function JobsPage() {
  return (
    <div>
      <PageHeader
        title="Jobs & orders"
        subtitle="Ops queues for stuck cancellations, long-delivered unpaid completion, and completed orders missing payment confirmation."
      />
      <EmptyState>Job and contract queues will appear here.</EmptyState>
    </div>
  )
}
