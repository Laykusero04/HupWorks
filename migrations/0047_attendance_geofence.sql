-- ============================================
-- Migration 0047 — Attendance QR geofence (200 m)
-- ============================================
-- record_attendance_punch requires scan GPS and rejects punches when the
-- job has no site pin or the worker is more than 200 m away (haversine).
--
-- Requires: 0011 (attendance_punches), 0014 (attendance_mode / helpers),
--           0020 (haversine_km), 0032 (_attendance_record_punch).
-- ============================================

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
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_punch_type := lower(trim(coalesce(p_punch_type, '')));
  if v_punch_type not in ('in', 'out') then
    raise exception 'Invalid punch type';
  end if;

  -- Stable client-facing codes (mapped in the app).
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

  -- Scalars only (avoids composite type public.attendance_punches).
  select ap.id, ap.punch_type
  into v_last_id, v_last_punch_type
  from public.attendance_punches ap
  where ap.seller_id = auth.uid()
    and ap.job_post_id = v_job_post_id
  order by ap.punched_at desc
  limit 1;

  if v_mode = 'qr_once' then
    if v_punch_type <> 'in' then
      raise exception 'This job only requires a daily check-in scan';
    end if;
    if public._attendance_has_checkin_today(auth.uid(), v_job_post_id) then
      raise exception 'You already checked in today for this job';
    end if;
  else
    if v_punch_type = 'in' then
      if v_last_id is not null and v_last_punch_type = 'in' then
        raise exception 'Already clocked in. Clock out first.';
      end if;
    elsif v_punch_type = 'out' then
      if v_last_id is null or v_last_punch_type <> 'in' then
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

comment on function public.record_attendance_punch(text, text, double precision, double precision) is
  'Records a QR attendance punch. Requires scan GPS within 200 m of job_posts lat/lng.';
