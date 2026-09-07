-- Phase 2: optional off-app payment confirmation on completed orders.
-- Safe to re-run.

alter table public.orders
  add column if not exists payment_received_at timestamptz;

alter table public.orders
  add column if not exists payment_received_by uuid
    references public.profiles(id) on delete set null;

comment on column public.orders.payment_received_at is
  'When client or seller confirmed payment was received outside the app.';
comment on column public.orders.payment_received_by is
  'Profile that marked payment received (manual confirmation, not a PSP).';

create index if not exists orders_seller_payment_received_idx
  on public.orders (seller_id, payment_received_at)
  where status = 'completed';

create or replace function public.set_order_payment_received(
  p_order_id uuid,
  p_received boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if auth.uid() is distinct from v_order.client_id
     and auth.uid() is distinct from v_order.seller_id then
    raise exception 'Only the client or seller can update payment status';
  end if;

  if lower(coalesce(v_order.status, '')) <> 'completed' then
    raise exception 'Payment can only be marked on completed orders';
  end if;

  if p_received then
    update public.orders
    set payment_received_at = coalesce(payment_received_at, now()),
        payment_received_by = coalesce(payment_received_by, auth.uid())
    where id = p_order_id;
  else
    update public.orders
    set payment_received_at = null,
        payment_received_by = null
    where id = p_order_id;
  end if;
end;
$$;

grant execute on function public.set_order_payment_received(uuid, boolean)
  to authenticated;
