-- ============================================
-- Migration 0048 — QR attendance geofence
-- A QR punch is accepted only when the phone is within 200 meters
-- of the job site pin. Keep this radius in sync with
-- attendanceGeofenceMeters in lib/core/utils/attendance_location.dart.
-- ============================================

create or replace function public._attendance_distance_meters(
  p_lat1 double precision,
  p_lng1 double precision,
  p_lat2 double precision,
  p_lng2 double precision
)
returns double precision
language sql
immutable
as $$
  select 6371000 * 2 * asin(
    least(
      1,
      sqrt(
        power(sin(radians(p_lat2 - p_lat1) / 2), 2)
        + cos(radians(p_lat1)) * cos(radians(p_lat2))
          * power(sin(radians(p_lng2 - p_lng1) / 2), 2)
      )
    )
  );
$$;

revoke all on function public._attendance_distance_meters(
  double precision, double precision, double precision, double precision
) from public;

-- Client: refuse a new QR until the job has a site pin.
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
  v_lat double precision;
  v_lng double precision;
  v_token text;
  v_payload text;
begin
  select jp.client_id, jp.location_type, jp.attendance_mode, jp.latitude, jp.longitude
  into v_client_id, v_location_type, v_mode, v_lat, v_lng
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

  if v_lat is null or v_lng is null then
    raise exception 'ATTENDANCE_NO_SITE_PIN';
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

-- Freelancer: resolve token. A job without a pin cannot be punched.
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

  if v_lat is null or v_lng is null then
    raise exception 'ATTENDANCE_NO_SITE_PIN';
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

-- Freelancer: record punch via QR, only inside the site radius.
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
  v_lat double precision;
  v_lng double precision;
  v_last public.attendance_punches;
  v_punch_type text;
  v_distance double precision;
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

  select jp.client_id, jp.title, jp.attendance_mode, jp.latitude, jp.longitude
  into v_client_id, v_title, v_mode, v_lat, v_lng
  from public.job_posts jp
  where jp.id = v_job_post_id;

  if coalesce(v_mode, 'disabled') not in ('qr_in_out', 'qr_once') then
    raise exception 'QR attendance is not enabled for this job';
  end if;

  if v_lat is null or v_lng is null then
    raise exception 'ATTENDANCE_NO_SITE_PIN';
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

  if p_latitude is null or p_longitude is null
     or p_latitude < -90 or p_latitude > 90
     or p_longitude < -180 or p_longitude > 180 then
    raise exception 'ATTENDANCE_LOCATION_REQUIRED';
  end if;

  v_distance := public._attendance_distance_meters(
    v_lat, v_lng, p_latitude, p_longitude
  );

  if v_distance is null or v_distance > 200 then
    raise exception 'ATTENDANCE_TOO_FAR';
  end if;

  return public._attendance_record_punch(
    v_job_post_id, v_order_id, v_client_id, v_title,
    v_punch_type, p_latitude, p_longitude
  );
end;
$$;
