-- ============================================
-- Migration 0013 — Per-hire onboarding packets
-- ============================================

-- Default section template (jsonb array)
create or replace function public._hire_onboarding_default_sections()
returns jsonb
language sql
immutable
as $$
  select jsonb_build_array(
    jsonb_build_object('key', 'where', 'title', 'Where to go', 'body', ''),
    jsonb_build_object('key', 'when', 'title', 'When to arrive', 'body', ''),
    jsonb_build_object('key', 'who', 'title', 'Who to contact', 'body', ''),
    jsonb_build_object('key', 'access', 'title', 'Building access', 'body', ''),
    jsonb_build_object('key', 'rules', 'title', 'Site rules', 'body', ''),
    jsonb_build_object('key', 'attendance', 'title', 'Attendance', 'body', ''),
    jsonb_build_object('key', 'emergency', 'title', 'Emergency', 'body', '')
  );
$$;

-- 1. Packets (one per order)
create table if not exists public.hire_onboarding_packets (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'draft' check (status in ('draft', 'published')),
  required_ack boolean not null default true,
  sections jsonb not null default public._hire_onboarding_default_sections(),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists hire_onboarding_packets_client_idx
  on public.hire_onboarding_packets (client_id);

create index if not exists hire_onboarding_packets_seller_idx
  on public.hire_onboarding_packets (seller_id);

alter table public.hire_onboarding_packets enable row level security;

create policy "Clients manage own hire onboarding packets"
  on public.hire_onboarding_packets
  for all
  using (auth.uid() = client_id)
  with check (auth.uid() = client_id);

create policy "Sellers view published hire onboarding packets"
  on public.hire_onboarding_packets
  for select
  using (auth.uid() = seller_id and status = 'published');

-- 2. Acknowledgments
create table if not exists public.hire_onboarding_acknowledgments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  acknowledged_at timestamptz not null default now(),
  unique (order_id, seller_id)
);

create index if not exists hire_onboarding_ack_order_idx
  on public.hire_onboarding_acknowledgments (order_id);

alter table public.hire_onboarding_acknowledgments enable row level security;

create policy "Order participants view hire onboarding acks"
  on public.hire_onboarding_acknowledgments
  for select
  using (
    auth.uid() in (
      select client_id from public.orders where id = order_id
      union
      select seller_id from public.orders where id = order_id
    )
  );

-- Inserts only via SECURITY DEFINER RPC.

-- 3. Create draft (idempotent)
create or replace function public.create_hire_onboarding_draft(p_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid;
  v_seller uuid;
  v_packet_id uuid;
begin
  select client_id, seller_id
    into v_client, v_seller
    from public.orders
    where id = p_order_id;

  if not found then
    raise exception 'Order not found';
  end if;

  if v_client is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  select id into v_packet_id
  from public.hire_onboarding_packets
  where order_id = p_order_id;

  if found then
    return v_packet_id;
  end if;

  insert into public.hire_onboarding_packets (order_id, client_id, seller_id, sections)
  values (p_order_id, v_client, v_seller, public._hire_onboarding_default_sections())
  returning id into v_packet_id;

  return v_packet_id;
end;
$$;

grant execute on function public.create_hire_onboarding_draft(uuid) to authenticated;

-- 4. Publish packet + notify seller
create or replace function public.publish_hire_onboarding(p_packet_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_packet record;
  v_job_title text;
begin
  select p.id, p.order_id, p.client_id, p.seller_id, p.status
    into v_packet
    from public.hire_onboarding_packets p
    where p.id = p_packet_id;

  if not found then
    raise exception 'Onboarding packet not found';
  end if;

  if v_packet.client_id is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  update public.hire_onboarding_packets
  set status = 'published',
      published_at = now(),
      updated_at = now()
  where id = p_packet_id;

  select coalesce(jp.title, 'your contract')
    into v_job_title
    from public.orders o
    left join public.job_offers jo on jo.id = o.job_offer_id
    left join public.job_posts jp on jp.id = jo.job_post_id
    where o.id = v_packet.order_id;

  perform public.create_notification(
    v_packet.seller_id,
    'First-day instructions',
    coalesce('Read site instructions for "' || v_job_title || '".', 'Your client published first-day instructions.'),
    'hire_onboarding',
    v_packet.order_id
  );
end;
$$;

grant execute on function public.publish_hire_onboarding(uuid) to authenticated;

-- 5. Seller acknowledge
create or replace function public.acknowledge_hire_onboarding(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_status text;
begin
  select seller_id into v_seller
    from public.orders
    where id = p_order_id;

  if not found then
    raise exception 'Order not found';
  end if;

  if v_seller is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  select status into v_status
    from public.hire_onboarding_packets
    where order_id = p_order_id;

  if not found or v_status <> 'published' then
    raise exception 'No published instructions for this contract';
  end if;

  insert into public.hire_onboarding_acknowledgments (order_id, seller_id)
  values (p_order_id, v_seller) 
  on conflict (order_id, seller_id) do update
    set acknowledged_at = now();
end;
$$;

grant execute on function public.acknowledge_hire_onboarding(uuid) to authenticated;

-- 6. Extend accept_job_offer: create draft packet after order insert
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

  perform public.create_hire_onboarding_draft(v_order_id);

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;
