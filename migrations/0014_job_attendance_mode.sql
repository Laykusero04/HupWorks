-- ============================================
-- Migration 0014 — Per-job attendance modes
-- qr_in_out | qr_once | self_report | disabled
-- ============================================

alter table public.job_posts
  add column if not exists attendance_mode text not null default 'qr_in_out'
  check (attendance_mode in ('qr_in_out', 'qr_once', 'self_report', 'disabled'));

update public.job_posts
set attendance_mode = 'disabled'
where coalesce(location_type, '') = 'Remote';

update public.job_posts
set attendance_mode = 'qr_in_out'
where coalesce(location_type, '') = 'On-site'
  and attendance_mode = 'disabled';

-- Has a clock-in punch today (UTC date)
create or replace function public._attendance_has_checkin_today(
  p_seller_id uuid,
  p_job_post_id uuid
)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.attendance_punches ap
    where ap.seller_id = p_seller_id
      and ap.job_post_id = p_job_post_id
      and ap.punch_type = 'in'
      and ap.punched_at::date = (now() at time zone 'utc')::date
  );
$$;

-- Shared punch insert + notification
create or replace function public._attendance_record_punch(
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
as $$
declare
  v_punch_id uuid;
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
  returning id into v_punch_id;

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
    and in_p.punched_at::date = (now() at time zone 'utc')::date;

  return jsonb_build_object(
    'success', true,
    'punch_id', v_punch_id,
    'punch_type', p_punch_type,
    'punched_at', now(),
    'is_clocked_in', p_punch_type = 'in',
    'minutes_worked_today', round(coalesce(v_minutes_today, 0)::numeric, 1),
    'job_post_id', p_job_post_id,
    'order_id', p_order_id
  );
end;
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
  v_mode text;
  v_token text;
  v_payload text;
begin
  select jp.client_id, jp.location_type, jp.attendance_mode
  into v_client_id, v_location_type, v_mode
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

  if coalesce(v_mode, 'disabled') not in ('qr_in_out', 'qr_once') then
    raise exception 'QR attendance is not enabled for this job';
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

-- Freelancer: resolve token
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
  v_last public.attendance_punches;
  v_suggested text;
  v_today_punches jsonb;
  v_is_clocked_in boolean;
  v_checked_in_today boolean;
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

  v_last := public._attendance_last_punch(auth.uid(), v_job_post_id);
  v_is_clocked_in := v_last.id is not null and v_last.punch_type = 'in';
  v_checked_in_today := public._attendance_has_checkin_today(auth.uid(), v_job_post_id);

  if v_mode = 'qr_once' then
    if v_checked_in_today then
      v_suggested := 'in';
      v_is_clocked_in := false;
    else
      v_suggested := 'in';
    end if;
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
    'attendance_mode', v_mode,
    'suggested_action', v_suggested,
    'is_clocked_in', v_is_clocked_in,
    'checked_in_today', v_checked_in_today,
    'last_punch_type', v_last.punch_type,
    'last_punched_at', v_last.punched_at,
    'today_punches', v_today_punches
  );
end;
$$;

-- Freelancer: record punch via QR
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
  v_last public.attendance_punches;
  v_punch_type text;
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

  select jp.client_id, jp.title, jp.attendance_mode
  into v_client_id, v_title, v_mode
  from public.job_posts jp
  where jp.id = v_job_post_id;

  if coalesce(v_mode, 'disabled') not in ('qr_in_out', 'qr_once') then
    raise exception 'QR attendance is not enabled for this job';
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

  v_last := public._attendance_last_punch(auth.uid(), v_job_post_id);

  if v_mode = 'qr_once' then
    if v_punch_type <> 'in' then
      raise exception 'This job only requires a daily check-in scan';
    end if;
    if public._attendance_has_checkin_today(auth.uid(), v_job_post_id) then
      raise exception 'You already checked in today for this job';
    end if;
  else
    if v_punch_type = 'in' then
      if v_last.id is not null and v_last.punch_type = 'in' then
        raise exception 'Already clocked in. Clock out first.';
      end if;
    elsif v_punch_type = 'out' then
      if v_last.id is null or v_last.punch_type <> 'in' then
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

-- Freelancer: self-report punch (no QR)
create or replace function public.record_self_report_punch(
  p_order_id uuid,
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
  v_client_id uuid;
  v_title text;
  v_mode text;
  v_location_type text;
  v_last public.attendance_punches;
  v_punch_type text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_punch_type := lower(trim(coalesce(p_punch_type, '')));
  if v_punch_type not in ('in', 'out') then
    raise exception 'Invalid punch type';
  end if;

  select
    jo.job_post_id,
    jp.client_id,
    jp.title,
    jp.attendance_mode,
    jp.location_type
  into
    v_job_post_id,
    v_client_id,
    v_title,
    v_mode,
    v_location_type
  from public.orders o
  join public.job_offers jo on jo.id = o.job_offer_id
  join public.job_posts jp on jp.id = jo.job_post_id
  where o.id = p_order_id
    and o.seller_id = auth.uid();

  if v_job_post_id is null then
    raise exception 'Order not found';
  end if;

  if coalesce(v_location_type, '') <> 'On-site' then
    raise exception 'Self-report attendance is only for on-site jobs';
  end if;

  if coalesce(v_mode, 'disabled') <> 'self_report' then
    raise exception 'Self-report attendance is not enabled for this job';
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

  return public._attendance_record_punch(
    v_job_post_id, p_order_id, v_client_id, v_title,
    v_punch_type, p_latitude, p_longitude
  );
end;
$$;

grant execute on function public.record_self_report_punch(uuid, text, double precision, double precision) to authenticated;
