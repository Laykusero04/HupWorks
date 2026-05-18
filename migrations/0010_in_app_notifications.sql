-- ============================================
-- Migration 0010 — In-app notifications
-- Helper, triggers, accept_job_offer seller notify, realtime
-- ============================================

create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text default null,
  p_type text default null,
  p_reference_id uuid default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    return;
  end if;
  insert into public.notifications (user_id, title, body, type, reference_id)
  values (p_user_id, p_title, p_body, p_type, p_reference_id);
end;
$$;

-- Notify seller when client accepts an application (order-centric deep link).
create or replace function public.accept_job_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_id uuid;
  v_client uuid;
  v_seller uuid;
  v_price numeric;
  v_delivery_time int;
  v_delivery_time_unit text;
  v_workers_needed int;
  v_offer_status text;
  v_job_status text;
  v_job_title text;
  v_deadline timestamptz;
  v_unit text;
  v_accepted_before int;
  v_accepted_after int;
  v_order_id uuid;
begin
  select
    jo.job_post_id,
    jo.seller_id,
    jo.price,
    jo.delivery_time,
    jo.delivery_time_unit,
    jp.client_id,
    jp.workers_needed,
    jo.status,
    jp.status,
    jp.title
  into
    v_post_id,
    v_seller,
    v_price,
    v_delivery_time,
    v_delivery_time_unit,
    v_client,
    v_workers_needed,
    v_offer_status,
    v_job_status,
    v_job_title
  from public.job_offers jo
  join public.job_posts jp on jp.id = jo.job_post_id
  where jo.id = p_offer_id;

  if not found then
    raise exception 'Offer not found';
  end if;

  if v_client is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  if lower(coalesce(v_job_status, '')) <> 'open' then
    raise exception 'This job is not open for new hires';
  end if;

  if lower(coalesce(v_offer_status, '')) <> 'pending' then
    raise exception 'This application is not pending';
  end if;

  v_workers_needed := greatest(1, coalesce(v_workers_needed, 1));

  select count(*)::int into v_accepted_before
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 then
    if v_accepted_before >= v_workers_needed then
      raise exception 'Hiring limit reached for this job';
    end if;
  end if;

  if v_delivery_time is null then
    v_deadline := null;
  else
    v_unit := lower(trim(coalesce(v_delivery_time_unit, 'days')));
    if v_unit = 'hours' then
      v_deadline := now() + make_interval(hours => greatest(1, v_delivery_time));
    else
      v_deadline := now() + make_interval(days => greatest(1, v_delivery_time));
    end if;
  end if;

  update public.job_offers set status = 'accepted' where id = p_offer_id;

  select count(*)::int into v_accepted_after
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 and v_accepted_after >= v_workers_needed then
    update public.job_posts set status = 'closed' where id = v_post_id;
  end if;

  insert into public.orders
    (job_offer_id, client_id, seller_id, price, status, delivery_deadline)
  values
    (p_offer_id, v_client, v_seller, v_price, 'pending', v_deadline)
  returning id into v_order_id;

  perform public.create_notification(
    v_seller,
    'Application accepted',
    coalesce('Your application for "' || v_job_title || '" was accepted.', 'Your application was accepted.'),
    'order',
    v_order_id
  );

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;

-- New bid on a job post → notify client
create or replace function public.notify_job_offer_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid;
  v_job_title text;
begin
  select jp.client_id, jp.title
    into v_client_id, v_job_title
    from public.job_posts jp
    where jp.id = new.job_post_id;

  perform public.create_notification(
    v_client_id,
    'New application',
    coalesce('Someone applied to "' || v_job_title || '".', 'You have a new application on your job post.'),
    'job_offer',
    new.id
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_job_offer_insert on public.job_offers;
create trigger trg_notify_job_offer_insert
  after insert on public.job_offers
  for each row
  execute function public.notify_job_offer_insert();

-- Offer rejected → notify seller
create or replace function public.notify_job_offer_rejected()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job_title text;
begin
  if lower(coalesce(old.status, '')) = lower(coalesce(new.status, '')) then
    return new;
  end if;
  if lower(coalesce(new.status, '')) <> 'rejected' then
    return new;
  end if;

  select jp.title into v_job_title
    from public.job_posts jp
    where jp.id = new.job_post_id;

  perform public.create_notification(
    new.seller_id,
    'Application not selected',
    coalesce('Your application for "' || v_job_title || '" was not selected.', 'Your application was not selected.'),
    'job_offer',
    new.id
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_job_offer_rejected on public.job_offers;
create trigger trg_notify_job_offer_rejected
  after update on public.job_offers
  for each row
  execute function public.notify_job_offer_rejected();

-- New service order → notify seller
create or replace function public.notify_order_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.service_id is null then
    return new;
  end if;

  perform public.create_notification(
    new.seller_id,
    'New order',
    'You received a new service order.',
    'order',
    new.id
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_order_insert on public.orders;
create trigger trg_notify_order_insert
  after insert on public.orders
  for each row
  execute function public.notify_order_insert();

-- Order status change → notify the other party
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

  case lower(coalesce(new.status, ''))
    when 'delivered' then
      v_title := 'Order delivered';
      v_body := 'The seller has delivered your order.';
    when 'completed' then
      v_title := 'Order completed';
      v_body := 'Your order has been marked completed.';
    when 'cancelled' then
      v_title := 'Order cancelled';
      v_body := 'An order was cancelled.';
    when 'in_progress' then
      v_title := 'Order in progress';
      v_body := 'Your order is now in progress.';
    else
      null;
  end case;

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

drop trigger if exists trg_notify_order_status_change on public.orders;
create trigger trg_notify_order_status_change
  after update on public.orders
  for each row
  execute function public.notify_order_status_change();

-- New review → notify reviewee
create or replace function public.notify_review_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.create_notification(
    new.reviewed_id,
    'New review',
    coalesce('You received a ' || new.rating::text || '-star review.', 'You received a new review.'),
    'review',
    new.order_id
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_review_insert on public.reviews;
create trigger trg_notify_review_insert
  after insert on public.reviews
  for each row
  execute function public.notify_review_insert();

-- Realtime for in-app badge refresh
alter publication supabase_realtime add table public.notifications;
