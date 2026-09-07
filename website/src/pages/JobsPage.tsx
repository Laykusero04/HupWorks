export function JobsPage() {
  return (
    <div className="page">
      <h1>Jobs &amp; orders</h1>
      <p className="lede">
        Ops queues: stuck cancellation requests, long-delivered unpaid completion, and completed
        orders missing <code>payment_received_at</code>.
      </p>
      <section className="panel empty">Job and contract queues will appear here.</section>
    </div>
  )
}
