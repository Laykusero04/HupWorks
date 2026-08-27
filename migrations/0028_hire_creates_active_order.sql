-- Hire should start work as active (Active tab / "In progress"), not pending.
-- Safe to re-run.

-- 1. Backfill stuck hire (and marketplace) contracts still sitting on pending.
update public.orders
set status = 'active'
where lower(status) = 'pending';

-- 2. accept_job_offer: new hires insert as active.
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
    (p_offer_id, v_client, v_seller, v_price, 'active', v_deadline)
  returning id into v_order_id;

  perform public.create_notification(
    v_seller,
    'Application accepted',
    coalesce('Your application for "' || v_job_title || '" was accepted.', 'Your application was accepted.'),
    'order',
    v_order_id
  );

  perform public.create_hire_onboarding_draft(v_order_id);

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;
