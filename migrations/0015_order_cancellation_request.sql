-- ============================================
-- Migration 0015 — Fair order cancellation (request + client approval)
-- ============================================

-- 1. Extend status + cancellation metadata on orders
alter table public.orders drop constraint if exists orders_status_check;

alter table public.orders
  add constraint orders_status_check check (
    status in (
      'active',
      'pending',
      'completed',
      'cancelled',
      'delivered',
      'cancellation_requested'
    )
  );

alter table public.orders
  add column if not exists cancellation_requested_at timestamptz,
  add column if not exists cancellation_requested_by uuid references public.profiles(id),
  add column if not exists cancellation_reason_code text,
  add column if not exists cancellation_reason_note text,
  add column if not exists cancellation_previous_status text,
  add column if not exists cancelled_by uuid references public.profiles(id),
  add column if not exists cancelled_at timestamptz;

-- 2. Valid reason codes
create or replace function public.is_valid_cancellation_reason_code(p_code text)
returns boolean
language sql
immutable
as $$
  select lower(trim(coalesce(p_code, ''))) in (
    'schedule_conflict',
    'scope_mismatch',
    'site_or_safety',
    'personal_emergency',
    'client_issue',
    'other'
  );
$$;

-- 3. Clear in-flight cancellation request fields (keep reason on final cancel)
create or replace function public._clear_cancellation_request(p_order_id uuid, p_keep_reason boolean default false)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.orders
  set
    cancellation_requested_at = null,
    cancellation_requested_by = null,
    cancellation_previous_status = null,
    cancellation_reason_code = case when p_keep_reason then cancellation_reason_code else null end,
    cancellation_reason_note = case when p_keep_reason then cancellation_reason_note else null end
  where id = p_order_id;
end;
$$;

-- 4. Freelancer requests cancellation
create or replace function public.request_order_cancellation(
  p_order_id uuid,
  p_reason_code text,
  p_reason_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_note text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_note := trim(coalesce(p_reason_note, ''));
  if length(v_note) < 20 then
    raise exception 'Please provide at least 20 characters explaining why you need to cancel';
  end if;

  if not public.is_valid_cancellation_reason_code(p_reason_code) then
    raise exception 'Invalid cancellation reason';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.seller_id is distinct from auth.uid() then
    raise exception 'Only the freelancer on this contract can request cancellation';
  end if;

  if lower(coalesce(v_order.status, '')) not in ('pending', 'active') then
    raise exception 'Cancellation can only be requested for pending or active contracts';
  end if;

  update public.orders
  set
    cancellation_previous_status = v_order.status,
    cancellation_requested_at = now(),
    cancellation_requested_by = auth.uid(),
    cancellation_reason_code = lower(trim(p_reason_code)),
    cancellation_reason_note = v_note,
    status = 'cancellation_requested'
  where id = p_order_id;
end;
$$;

grant execute on function public.request_order_cancellation(uuid, text, text) to authenticated;

-- 5. Client approves or declines
create or replace function public.respond_order_cancellation(
  p_order_id uuid,
  p_approve boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_restore text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.client_id is distinct from auth.uid() then
    raise exception 'Only the client on this contract can respond to a cancellation request';
  end if;

  if lower(coalesce(v_order.status, '')) <> 'cancellation_requested' then
    raise exception 'No pending cancellation request for this order';
  end if;

  v_restore := lower(trim(coalesce(v_order.cancellation_previous_status, 'active')));
  if v_restore not in ('pending', 'active') then
    v_restore := 'active';
  end if;

  if p_approve then
    update public.orders
    set
      status = 'cancelled',
      cancelled_by = auth.uid(),
      cancelled_at = now(),
      cancellation_requested_at = null,
      cancellation_requested_by = null,
      cancellation_previous_status = null
    where id = p_order_id;
  else
    update public.orders
    set status = v_restore
    where id = p_order_id;
    perform public._clear_cancellation_request(p_order_id, false);
  end if;
end;
$$;

grant execute on function public.respond_order_cancellation(uuid, boolean) to authenticated;

-- 6. Freelancer withdraws request
create or replace function public.withdraw_order_cancellation(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_restore text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.seller_id is distinct from auth.uid() then
    raise exception 'Only the freelancer can withdraw this cancellation request';
  end if;

  if lower(coalesce(v_order.status, '')) <> 'cancellation_requested' then
    raise exception 'No pending cancellation request to withdraw';
  end if;

  v_restore := lower(trim(coalesce(v_order.cancellation_previous_status, 'active')));
  if v_restore not in ('pending', 'active') then
    v_restore := 'active';
  end if;

  update public.orders set status = v_restore where id = p_order_id;
  perform public._clear_cancellation_request(p_order_id, false);
end;
$$;

grant execute on function public.withdraw_order_cancellation(uuid) to authenticated;

-- 7. Expire stale requests (>48h, client did not respond)
create or replace function public.expire_stale_cancellation_requests()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.orders%rowtype;
  v_count int := 0;
  v_restore text;
begin
  for v_row in
    select * from public.orders
    where lower(coalesce(status, '')) = 'cancellation_requested'
      and cancellation_requested_at is not null
      and cancellation_requested_at < now() - interval '48 hours'
    for update
  loop
    v_restore := lower(trim(coalesce(v_row.cancellation_previous_status, 'active')));
    if v_restore not in ('pending', 'active') then
      v_restore := 'active';
    end if;

    update public.orders set status = v_restore where id = v_row.id;
    perform public._clear_cancellation_request(v_row.id, false);

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

grant execute on function public.expire_stale_cancellation_requests() to authenticated;

-- 8. Richer order status notifications
create or replace function public.notify_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
  v_title text;
  v_body text;
  v_actor uuid;
  v_reason_snip text;
begin
  if lower(coalesce(old.status, '')) = lower(coalesce(new.status, '')) then
    return new;
  end if;

  v_actor := auth.uid();
  if v_actor = new.seller_id then
    v_recipient := new.client_id;
  elsif v_actor = new.client_id then
    v_recipient := new.seller_id;
  else
    return new;
  end if;

  v_title := 'Order update';
  v_body := 'Order status is now ' || coalesce(new.status, 'updated') || '.';

  v_reason_snip := left(trim(coalesce(new.cancellation_reason_note, '')), 120);
  if length(v_reason_snip) > 0 then
    v_reason_snip := ' Reason: ' || v_reason_snip;
  end if;

  case lower(coalesce(new.status, ''))
    when 'delivered' then
      v_title := 'Order delivered';
      v_body := 'The seller has delivered your order.';
    when 'completed' then
      v_title := 'Order completed';
      v_body := 'Your order has been marked completed.';
    when 'cancelled' then
      v_title := 'Contract cancelled';
      v_body := 'This contract has been cancelled.' || v_reason_snip;
    when 'cancellation_requested' then
      v_title := 'Cancellation requested';
      v_body := 'The freelancer requested to cancel this contract. Please review and respond within 48 hours.' || v_reason_snip;
    else
      null;
  end case;

  -- Decline / withdraw / expire: restored from cancellation_requested
  if lower(coalesce(old.status, '')) = 'cancellation_requested'
     and lower(coalesce(new.status, '')) not in ('cancelled', 'cancellation_requested') then
    if v_actor is null then
      v_recipient := new.seller_id;
      v_title := 'Cancellation request expired';
      v_body := 'No response within 48 hours. The contract remains active.';
    elsif v_actor = new.client_id then
      v_recipient := new.seller_id;
      v_title := 'Cancellation request declined';
      v_body := 'The client chose to keep this contract active.';
    elsif v_actor = new.seller_id then
      v_recipient := new.client_id;
      v_title := 'Cancellation request withdrawn';
      v_body := 'The freelancer withdrew their cancellation request.';
    end if;
  end if;

  perform public.create_notification(
    v_recipient,
    v_title,
    v_body,
    'order',
    new.id
  );
  return new;
end;
$$;
