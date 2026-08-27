-- Secure deliver/complete RPCs + counter-offer that updates job_offers.price.
-- Safe to re-run.

-- 1. Client counter-offer: update pending offer price (hire reads this).
create or replace function public.counter_job_offer(
  p_offer_id uuid,
  p_price numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid;
  v_status text;
  v_job_status text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_price is null or p_price <= 0 then
    raise exception 'Counter offer amount must be greater than zero';
  end if;

  select jp.client_id, jo.status, jp.status
  into v_client, v_status, v_job_status
  from public.job_offers jo
  join public.job_posts jp on jp.id = jo.job_post_id
  where jo.id = p_offer_id
  for update of jo;

  if not found then
    raise exception 'Offer not found';
  end if;

  if v_client is distinct from auth.uid() then
    raise exception 'Only the client can send a counter offer';
  end if;

  if lower(coalesce(v_job_status, '')) <> 'open' then
    raise exception 'This job is not open';
  end if;

  if lower(coalesce(v_status, '')) <> 'pending' then
    raise exception 'This application is not pending';
  end if;

  update public.job_offers
  set price = p_price
  where id = p_offer_id;
end;
$$;

grant execute on function public.counter_job_offer(uuid, numeric) to authenticated;

-- 2. Seller delivers work (insert delivery + set status).
create or replace function public.deliver_order(
  p_order_id uuid,
  p_message text,
  p_attachment_url text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_message text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_message := trim(coalesce(p_message, ''));
  if v_message = '' then
    raise exception 'Please describe your delivery';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.seller_id is distinct from auth.uid() then
    raise exception 'Only the seller can deliver this order';
  end if;

  if lower(coalesce(v_order.status, '')) not in ('pending', 'active', 'delivered') then
    raise exception 'This order cannot be delivered from its current status';
  end if;

  insert into public.order_deliveries (order_id, message, attachment_url)
  values (p_order_id, v_message, nullif(trim(coalesce(p_attachment_url, '')), ''));

  update public.orders
  set status = 'delivered'
  where id = p_order_id;
end;
$$;

grant execute on function public.deliver_order(uuid, text, text) to authenticated;

-- 3. Client completes after delivery.
create or replace function public.complete_order(p_order_id uuid)
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

  if v_order.client_id is distinct from auth.uid() then
    raise exception 'Only the client can mark this order complete';
  end if;

  if lower(coalesce(v_order.status, '')) <> 'delivered' then
    raise exception 'Order can only be completed after the seller delivers';
  end if;

  if not exists (
    select 1 from public.order_deliveries d where d.order_id = p_order_id
  ) then
    raise exception 'Order can only be completed after the seller delivers';
  end if;

  update public.orders
  set status = 'completed',
      completed_at = coalesce(completed_at, now())
  where id = p_order_id;
end;
$$;

grant execute on function public.complete_order(uuid) to authenticated;
