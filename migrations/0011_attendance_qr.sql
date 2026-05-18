-- ============================================
-- Migration 0011 — QR attendance (time in / out)
-- Tables, RLS, and RPCs for client QR + freelancer punches
-- ============================================

-- 1. Attendance tokens (one active token per job post)
create table if not exists public.job_attendance_tokens (
  id uuid primary key default gen_random_uuid(),
  job_post_id uuid not null references public.job_posts(id) on delete cascade,
  token text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);

create unique index if not exists job_attendance_tokens_one_active_per_job
  on public.job_attendance_tokens (job_post_id)
  where is_active = true;

create index if not exists job_attendance_tokens_token_idx
  on public.job_attendance_tokens (token)
  where is_active = true;

alter table public.job_attendance_tokens enable row level security;

create policy "Clients manage attendance tokens for own jobs"
  on public.job_attendance_tokens
  for all
  using (
    auth.uid() in (
      select client_id from public.job_posts where id = job_post_id
    )
  )
  with check (
    auth.uid() in (
      select client_id from public.job_posts where id = job_post_id
    )
  );

-- 2. Punch log
create table if not exists public.attendance_punches (
  id uuid primary key default gen_random_uuid(),
  job_post_id uuid not null references public.job_posts(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  punch_type text not null check (punch_type in ('in', 'out')),
  punched_at timestamptz not null default now(),
  scan_latitude double precision,
  scan_longitude double precision,
  device_metadata jsonb
);

create index if not exists attendance_punches_seller_job_time_idx
  on public.attendance_punches (seller_id, job_post_id, punched_at desc);

create index if not exists attendance_punches_job_post_idx
  on public.attendance_punches (job_post_id, punched_at desc);

alter table public.attendance_punches enable row level security;

create policy "Order participants can view attendance punches"
  on public.attendance_punches
  for select
  using (auth.uid() = client_id or auth.uid() = seller_id);

-- Inserts only via SECURITY DEFINER RPC (no insert policy for authenticated).

-- Helper: URL-safe random token (uses gen_random_uuid only — no pgcrypto required)
create or replace function public._attendance_new_token()
returns text
language sql
as $$
  select replace(gen_random_uuid()::text, '-', '')
      || replace(gen_random_uuid()::text, '-', '');
$$;

-- Helper: last punch for seller on a job
create or replace function public._attendance_last_punch(
  p_seller_id uuid,
  p_job_post_id uuid
)
returns public.attendance_punches
language sql
stable
as $$
  select ap.*
  from public.attendance_punches ap
  where ap.seller_id = p_seller_id
    and ap.job_post_id = p_job_post_id
  order by ap.punched_at desc
  limit 1;
$$;

-- Client: create or rotate attendance QR token
create or replace function public.generate_job_attendance_token(p_job_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid;
  v_location_type text;
  v_token text;
  v_payload text;
begin
  select jp.client_id, jp.location_type
  into v_client_id, v_location_type
  from public.job_posts jp
  where jp.id = p_job_post_id;

  if not found then
    raise exception 'Job post not found';
  end if;

  if v_client_id is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  if coalesce(v_location_type, '') <> 'On-site' then
    raise exception 'Attendance QR is only available for on-site jobs';
  end if;

  update public.job_attendance_tokens
  set is_active = false, revoked_at = now()
  where job_post_id = p_job_post_id and is_active = true;

  v_token := public._attendance_new_token();

  insert into public.job_attendance_tokens (job_post_id, token, is_active)
  values (p_job_post_id, v_token, true);

  v_payload := 'hupworks://attendance/' || v_token;

  return jsonb_build_object(
    'token', v_token,
    'qr_payload', v_payload,
    'job_post_id', p_job_post_id
  );
end;
$$;

grant execute on function public.generate_job_attendance_token(uuid) to authenticated;

-- Client: fetch active token without rotating
create or replace function public.get_job_attendance_token(p_job_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid;
  v_token text;
  v_payload text;
begin
  select jp.client_id into v_client_id
  from public.job_posts jp
  where jp.id = p_job_post_id;

  if not found then
    raise exception 'Job post not found';
  end if;

  if v_client_id is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  select t.token into v_token
  from public.job_attendance_tokens t
  where t.job_post_id = p_job_post_id and t.is_active = true
  limit 1;

  if v_token is null then
    return jsonb_build_object('token', null, 'qr_payload', null, 'job_post_id', p_job_post_id);
  end if;

  v_payload := 'hupworks://attendance/' || v_token;

  return jsonb_build_object(
    'token', v_token,
    'qr_payload', v_payload,
    'job_post_id', p_job_post_id
  );
end;
$$;

grant execute on function public.get_job_attendance_token(uuid) to authenticated;

-- Freelancer: resolve token (read-only preview)
create or replace function public.resolve_attendance_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job_post_id uuid;
  v_order_id uuid;
  v_client_id uuid;
  v_title text;
  v_location text;
  v_location_type text;
  v_lat double precision;
  v_lng double precision;
  v_client_name text;
  v_last public.attendance_punches;
  v_suggested text;
  v_today_punches jsonb;
  v_is_clocked_in boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select t.job_post_id into v_job_post_id
  from public.job_attendance_tokens t
  where t.token = p_token and t.is_active = true;

  if v_job_post_id is null then
    raise exception 'Invalid or expired attendance QR code';
  end if;

  select
    jp.id, jp.client_id, jp.title, jp.location, jp.location_type,
    jp.latitude, jp.longitude
  into
    v_job_post_id, v_client_id, v_title, v_location, v_location_type,
    v_lat, v_lng
  from public.job_posts jp
  where jp.id = v_job_post_id;

  select p.name into v_client_name
  from public.profiles p
  where p.id = v_client_id;

  select o.id into v_order_id
  from public.orders o
  join public.job_offers jo on jo.id = o.job_offer_id
  where jo.job_post_id = v_job_post_id
    and o.seller_id = auth.uid()
    and lower(coalesce(o.status, '')) not in ('cancelled')
  order by o.created_at desc
  limit 1;

  if v_order_id is null then
    raise exception 'You are not hired on this job';
  end if;

  v_last := public._attendance_last_punch(auth.uid(), v_job_post_id);
  v_is_clocked_in := v_last.id is not null and v_last.punch_type = 'in';

  if v_is_clocked_in then
    v_suggested := 'out';
  else
    v_suggested := 'in';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', ap.id,
      'punch_type', ap.punch_type,
      'punched_at', ap.punched_at
    ) order by ap.punched_at asc
  ), '[]'::jsonb)
  into v_today_punches
  from public.attendance_punches ap
  where ap.seller_id = auth.uid()
    and ap.job_post_id = v_job_post_id
    and ap.punched_at::date = (now() at time zone 'utc')::date;

  return jsonb_build_object(
    'job_post_id', v_job_post_id,
    'order_id', v_order_id,
    'title', v_title,
    'location', v_location,
    'location_type', v_location_type,
    'latitude', v_lat,
    'longitude', v_lng,
    'client_name', coalesce(v_client_name, 'Client'),
    'suggested_action', v_suggested,
    'is_clocked_in', v_is_clocked_in,
    'last_punch_type', v_last.punch_type,
    'last_punched_at', v_last.punched_at,
    'today_punches', v_today_punches
  );
end;
$$;

grant execute on function public.resolve_attendance_token(text) to authenticated;

-- Freelancer: record punch
create or replace function public.record_attendance_punch(
  p_token text,
  p_punch_type text,
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job_post_id uuid;
  v_order_id uuid;
  v_client_id uuid;
  v_title text;
  v_last public.attendance_punches;
  v_punch_type text;
  v_punch_id uuid;
  v_minutes_today numeric;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_punch_type := lower(trim(coalesce(p_punch_type, '')));
  if v_punch_type not in ('in', 'out') then
    raise exception 'Invalid punch type';
  end if;

  select t.job_post_id into v_job_post_id
  from public.job_attendance_tokens t
  where t.token = p_token and t.is_active = true;

  if v_job_post_id is null then
    raise exception 'Invalid or expired attendance QR code';
  end if;

  select jp.client_id, jp.title
  into v_client_id, v_title
  from public.job_posts jp
  where jp.id = v_job_post_id;

  select o.id into v_order_id
  from public.orders o
  join public.job_offers jo on jo.id = o.job_offer_id
  where jo.job_post_id = v_job_post_id
    and o.seller_id = auth.uid()
    and lower(coalesce(o.status, '')) not in ('cancelled')
  order by o.created_at desc
  limit 1;

  if v_order_id is null then
    raise exception 'You are not hired on this job';
  end if;

  v_last := public._attendance_last_punch(auth.uid(), v_job_post_id);

  if v_punch_type = 'in' then
    if v_last.id is not null and v_last.punch_type = 'in' then
      raise exception 'Already clocked in. Clock out first.';
    end if;
  elsif v_punch_type = 'out' then
    if v_last.id is null or v_last.punch_type <> 'in' then
      raise exception 'Not clocked in';
    end if;
  end if;

  insert into public.attendance_punches (
    job_post_id, order_id, seller_id, client_id,
    punch_type, scan_latitude, scan_longitude
  )
  values (
    v_job_post_id, v_order_id, auth.uid(), v_client_id,
    v_punch_type, p_latitude, p_longitude
  )
  returning id into v_punch_id;

  perform public.create_notification(
    v_client_id,
    case when v_punch_type = 'in' then 'Worker clocked in' else 'Worker clocked out' end,
    coalesce(
      (select name from public.profiles where id = auth.uid()),
      'A worker'
    ) || ' ' || case when v_punch_type = 'in' then 'clocked in' else 'clocked out' end
      || ' for "' || coalesce(v_title, 'your job') || '".',
    'attendance',
    v_order_id
  );

  -- Sum completed in/out pairs today (minutes)
  select coalesce(sum(
    extract(epoch from (out_p.punched_at - in_p.punched_at)) / 60.0
  ), 0)
  into v_minutes_today
  from public.attendance_punches in_p
  join public.attendance_punches out_p
    on out_p.seller_id = in_p.seller_id
   and out_p.job_post_id = in_p.job_post_id
   and out_p.punch_type = 'out'
   and out_p.punched_at > in_p.punched_at
   and out_p.punched_at = (
     select min(ap.punched_at)
     from public.attendance_punches ap
     where ap.seller_id = in_p.seller_id
       and ap.job_post_id = in_p.job_post_id
       and ap.punch_type = 'out'
       and ap.punched_at > in_p.punched_at
   )
  where in_p.seller_id = auth.uid()
    and in_p.job_post_id = v_job_post_id
    and in_p.punch_type = 'in'
    and in_p.punched_at::date = (now() at time zone 'utc')::date;

  return jsonb_build_object(
    'success', true,
    'punch_id', v_punch_id,
    'punch_type', v_punch_type,
    'punched_at', now(),
    'is_clocked_in', v_punch_type = 'in',
    'minutes_worked_today', round(coalesce(v_minutes_today, 0)::numeric, 1),
    'job_post_id', v_job_post_id,
    'order_id', v_order_id
  );
end;
$$;

grant execute on function public.record_attendance_punch(text, text, double precision, double precision) to authenticated;
