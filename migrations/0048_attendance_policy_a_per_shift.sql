-- ============================================
-- Migration 0048 — Attendance Policy A (per-worker / per-shift)
-- ============================================
-- Product choice: Policy A (not single-use token B).
--
-- Shared site QR stays valid for all hired workers on the job.
-- Each worker may punch at most one "in" and one "out" per shift window.
-- Single-use tokens (B) are intentionally NOT used — they break multi-hire sites.
--
-- Shift window (order snapshot, else job_posts):
--   • work_date + shift_start + shift_end → [start−60m, end+60m]
--     (overnight when end < start → end on next calendar day)
--   • otherwise calendar day of coalesce(work_date, today UTC)
-- Times are interpreted as UTC clock values (no per-job timezone column yet).
--
-- Bootstrap: create attendance tables if 0011 was never applied on this DB.
-- ============================================

-- 0) Ensure base tables exist (safe no-op when 0011 already ran)
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

do $$ begin
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
exception
  when duplicate_object then null;
end $$;

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

do $$ begin
  create policy "Order participants can view attendance punches"
    on public.attendance_punches
    for select
    using (auth.uid() = client_id or auth.uid() = seller_id);
exception
  when duplicate_object then null;
end $$;

-- Ensure attendance_mode exists (0014) for mode checks below.
alter table public.job_posts
  add column if not exists attendance_mode text not null default 'qr_in_out';

alter table public.job_posts
  add column if not exists work_date date,
  add column if not exists shift_start time,
  add column if not exists shift_end time,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_type text;

alter table public.orders
  add column if not exists work_date date,
  add column if not exists shift_start time,
  add column if not exists shift_end time;

do $$ begin
  alter table public.job_posts
    add constraint job_posts_attendance_mode_check
    check (attendance_mode in ('qr_in_out', 'qr_once', 'self_report', 'disabled'));
exception
  when duplicate_object then null;
end $$;

-- Geofence helper (0020) used by record_attendance_punch.
create or replace function public.haversine_km(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) returns double precision
language sql
immutable
as $$
  select 2 * 6371 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) *
    power(sin(radians(lon2 - lon1) / 2), 2)
  ));
$$;

-- Minimal shared punch writer only if 0014/0032 never landed (0048 calls it).
-- Do not replace a richer version that already creates hour_reports (0032).
do $bootstrap$
begin
  if to_regprocedure(
    'public._attendance_record_punch(uuid,uuid,uuid,text,text,double precision,double precision)'
  ) is null then
    execute $fn$
      create function public._attendance_record_punch(
        p_job_post_id uuid,
        p_order_id uuid,
        p_client_id uuid,
        p_title text,
        p_punch_type text,
        p_latitude double precision default null,
        p_longitude double precision default null
      )
      returns jsonb
      language plpgsql
      security definer
      set search_path = public
      as $body$
      declare
        v_punch_id uuid;
        v_punched_at timestamptz;
        v_minutes_today numeric;
      begin
        insert into public.attendance_punches (
          job_post_id, order_id, seller_id, client_id,
          punch_type, scan_latitude, scan_longitude
        )
        values (
          p_job_post_id, p_order_id, auth.uid(), p_client_id,
          p_punch_type, p_latitude, p_longitude
        )
        returning id, punched_at into v_punch_id, v_punched_at;

        begin
          perform public.create_notification(
            p_client_id,
            case when p_punch_type = 'in' then 'Worker clocked in' else 'Worker clocked out' end,
            coalesce(
              (select name from public.profiles where id = auth.uid()),
              'A worker'
            ) || ' ' || case when p_punch_type = 'in' then 'clocked in' else 'clocked out' end
              || ' for "' || coalesce(p_title, 'your job') || '".',
            'attendance',
            p_order_id
          );
        exception
          when undefined_function then null;
        end;

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
          and in_p.job_post_id = p_job_post_id
          and in_p.punch_type = 'in'
          and in_p.punched_at::date = (timezone('utc', now()))::date;

        return jsonb_build_object(
          'success', true,
          'punch_id', v_punch_id,
          'punch_type', p_punch_type,
          'punched_at', v_punched_at,
          'is_clocked_in', p_punch_type = 'in',
          'minutes_worked_today', round(coalesce(v_minutes_today, 0)::numeric, 1),
          'job_post_id', p_job_post_id,
          'order_id', p_order_id
        );
      end;
      $body$;
    $fn$;
  end if;
end;
$bootstrap$;

-- Bounds for the order's current shift window.
create or replace function public._attendance_shift_window(p_order_id uuid)
returns table(window_start timestamptz, window_end timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_work_date date;
  v_start time;
  v_end time;
  v_base date;
  v_ws timestamptz;
  v_we timestamptz;
begin
  select
    coalesce(o.work_date, jp.work_date),
    coalesce(o.shift_start, jp.shift_start),
    coalesce(o.shift_end, jp.shift_end)
  into v_work_date, v_start, v_end
  from public.orders o
  join public.job_offers jo on jo.id = o.job_offer_id
  join public.job_posts jp on jp.id = jo.job_post_id
  where o.id = p_order_id;

  v_base := coalesce(v_work_date, (timezone('utc', now()))::date);

  if v_start is not null and v_end is not null then
    v_ws := ((v_base + v_start) at time zone 'utc') - interval '60 minutes';
    if v_end <= v_start then
      v_we := (((v_base + 1) + v_end) at time zone 'utc') + interval '60 minutes';
    else
      v_we := ((v_base + v_end) at time zone 'utc') + interval '60 minutes';
    end if;
  else
    v_ws := (v_base::timestamp at time zone 'utc');
    v_we := ((v_base + 1)::timestamp at time zone 'utc');
  end if;

  window_start := v_ws;
  window_end := v_we;
  return next;
end;
$$;

create or replace function public._attendance_has_punch_in_window(
  p_seller_id uuid,
  p_job_post_id uuid,
  p_punch_type text,
  p_window_start timestamptz,
  p_window_end timestamptz
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return exists (
    select 1
    from public.attendance_punches ap
    where ap.seller_id = p_seller_id
      and ap.job_post_id = p_job_post_id
      and ap.punch_type = p_punch_type
      and ap.punched_at >= p_window_start
      and ap.punched_at < p_window_end
  );
end;
$$;

-- Resolve token + per-shift status for the scanner.
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
  v_mode text;
  v_lat double precision;
  v_lng double precision;
  v_client_name text;
  v_last_id uuid;
  v_last_punch_type text;
  v_last_punched_at timestamptz;
  v_suggested text;
  v_today_punches jsonb;
  v_is_clocked_in boolean;
  v_checked_in_today boolean;
  v_checked_out_shift boolean;
  v_shift_complete boolean;
  v_window_start timestamptz;
  v_window_end timestamptz;
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
    jp.latitude, jp.longitude, jp.attendance_mode
  into
    v_job_post_id, v_client_id, v_title, v_location, v_location_type,
    v_lat, v_lng, v_mode
  from public.job_posts jp
  where jp.id = v_job_post_id;

  if coalesce(v_mode, 'disabled') not in ('qr_in_out', 'qr_once') then
    raise exception 'QR attendance is not enabled for this job';
  end if;

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

  select w.window_start, w.window_end
  into v_window_start, v_window_end
  from public._attendance_shift_window(v_order_id) w;

  v_checked_in_today := public._attendance_has_punch_in_window(
    auth.uid(), v_job_post_id, 'in', v_window_start, v_window_end
  );
  v_checked_out_shift := public._attendance_has_punch_in_window(
    auth.uid(), v_job_post_id, 'out', v_window_start, v_window_end
  );

  select ap.id, ap.punch_type, ap.punched_at
  into v_last_id, v_last_punch_type, v_last_punched_at
  from public.attendance_punches ap
  where ap.seller_id = auth.uid()
    and ap.job_post_id = v_job_post_id
    and ap.punched_at >= v_window_start
    and ap.punched_at < v_window_end
  order by ap.punched_at desc
  limit 1;

  v_is_clocked_in := v_last_id is not null and v_last_punch_type = 'in';
  v_shift_complete := case
    when v_mode = 'qr_once' then v_checked_in_today
    else v_checked_in_today and v_checked_out_shift
  end;

  if v_mode = 'qr_once' then
    v_suggested := 'in';
    v_is_clocked_in := false;
  elsif v_shift_complete then
    v_suggested := 'out';
    v_is_clocked_in := false;
  elsif v_is_clocked_in then
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
    and ap.punched_at >= v_window_start
    and ap.punched_at < v_window_end;

  return jsonb_build_object(
    'job_post_id', v_job_post_id,
    'order_id', v_order_id,
    'title', v_title,
    'location', v_location,
    'location_type', v_location_type,
    'latitude', v_lat,
    'longitude', v_lng,
    'client_name', coalesce(v_client_name, 'Client'),
    'attendance_mode', v_mode,
    'suggested_action', v_suggested,
    'is_clocked_in', v_is_clocked_in,
    'checked_in_today', v_checked_in_today,
    'checked_out_this_shift', v_checked_out_shift,
    'shift_complete', v_shift_complete,
    'shift_window_start', v_window_start,
    'shift_window_end', v_window_end,
    'last_punch_type', v_last_punch_type,
    'last_punched_at', v_last_punched_at,
    'today_punches', v_today_punches
  );
end;
$$;

-- Record punch with Policy A + existing geofence (0047).
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
  v_mode text;
  v_job_lat double precision;
  v_job_lng double precision;
  v_distance_km double precision;
  v_last_id uuid;
  v_last_punch_type text;
  v_punch_type text;
  v_window_start timestamptz;
  v_window_end timestamptz;
  v_has_in boolean;
  v_has_out boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_punch_type := lower(trim(coalesce(p_punch_type, '')));
  if v_punch_type not in ('in', 'out') then
    raise exception 'Invalid punch type';
  end if;

  if p_latitude is null or p_longitude is null then
    raise exception 'Location required';
  end if;

  select t.job_post_id into v_job_post_id
  from public.job_attendance_tokens t
  where t.token = p_token and t.is_active = true;

  if v_job_post_id is null then
    raise exception 'Invalid or expired attendance QR code';
  end if;

  select
    jp.client_id,
    jp.title,
    jp.attendance_mode,
    jp.latitude,
    jp.longitude
  into
    v_client_id,
    v_title,
    v_mode,
    v_job_lat,
    v_job_lng
  from public.job_posts jp
  where jp.id = v_job_post_id;

  if coalesce(v_mode, 'disabled') not in ('qr_in_out', 'qr_once') then
    raise exception 'QR attendance is not enabled for this job';
  end if;

  if v_job_lat is null or v_job_lng is null then
    raise exception 'Job site not set';
  end if;

  v_distance_km := public.haversine_km(
    p_latitude, p_longitude, v_job_lat, v_job_lng
  );
  if v_distance_km is null or v_distance_km > 0.2 then
    raise exception 'Too far from site';
  end if;

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

  select w.window_start, w.window_end
  into v_window_start, v_window_end
  from public._attendance_shift_window(v_order_id) w;

  if now() < v_window_start or now() >= v_window_end then
    raise exception 'Outside shift window';
  end if;

  v_has_in := public._attendance_has_punch_in_window(
    auth.uid(), v_job_post_id, 'in', v_window_start, v_window_end
  );
  v_has_out := public._attendance_has_punch_in_window(
    auth.uid(), v_job_post_id, 'out', v_window_start, v_window_end
  );

  select ap.id, ap.punch_type
  into v_last_id, v_last_punch_type
  from public.attendance_punches ap
  where ap.seller_id = auth.uid()
    and ap.job_post_id = v_job_post_id
    and ap.punched_at >= v_window_start
    and ap.punched_at < v_window_end
  order by ap.punched_at desc
  limit 1;

  if v_mode = 'qr_once' then
    if v_punch_type <> 'in' then
      raise exception 'This job only requires a daily check-in scan';
    end if;
    if v_has_in then
      raise exception 'You already checked in for this shift';
    end if;
  else
    -- Policy A: one in + one out per worker per shift window.
    if v_has_in and v_has_out then
      raise exception 'Already completed attendance for this shift';
    end if;

    if v_punch_type = 'in' then
      if v_has_in then
        raise exception 'You already checked in for this shift';
      end if;
      if v_last_id is not null and v_last_punch_type = 'in' then
        raise exception 'Already clocked in. Clock out first.';
      end if;
    elsif v_punch_type = 'out' then
      if v_has_out then
        raise exception 'Already clocked out for this shift';
      end if;
      if not v_has_in or v_last_id is null or v_last_punch_type <> 'in' then
        raise exception 'Not clocked in';
      end if;
    end if;
  end if;

  return public._attendance_record_punch(
    v_job_post_id, v_order_id, v_client_id, v_title,
    v_punch_type, p_latitude, p_longitude
  );
end;
$$;

comment on function public._attendance_shift_window(uuid) is
  'Policy A shift bounds for an order (work_date/times with 60m grace, else UTC day).';
comment on function public.record_attendance_punch(text, text, double precision, double precision) is
  'QR punch: geofence 200m + Policy A (shared token; one in/out per worker per shift).';
comment on function public.resolve_attendance_token(text) is
  'Resolve QR token with Policy A per-shift punch status for the current worker.';
