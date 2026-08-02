-- ============================================
-- Migration 0021 — Public seller work trust (completed onsite + attendance)
-- Aggregates only; no raw punch rows exposed
-- ============================================

create or replace function public.get_seller_public_work_trust(p_seller_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_role text;
  v_completed int := 0;
  v_checkins int := 0;
  v_shift_days int := 0;
  v_with_attendance int := 0;
  v_highlights jsonb := '[]'::jsonb;
  v_empty jsonb := jsonb_build_object(
    'completed_onsite_jobs', 0,
    'verified_checkins', 0,
    'verified_shift_days', 0,
    'jobs_with_attendance', 0,
    'highlights', '[]'::jsonb
  );
begin
  if p_seller_id is null then
    return v_empty;
  end if;

  select role into v_role
  from public.profiles
  where id = p_seller_id;

  if v_role is distinct from 'seller' then
    return v_empty;
  end if;

  with eligible_orders as (
    select
      o.id as order_id,
      o.completed_at,
      jp.id as job_post_id,
      jp.title as job_title,
      jp.attendance_mode,
      c.name as category_name
    from public.orders o
    inner join public.job_offers jo on jo.id = o.job_offer_id
    inner join public.job_posts jp on jp.id = jo.job_post_id
    left join public.categories c on c.id = jp.category_id
    where o.seller_id = p_seller_id
      and o.status = 'completed'
      and coalesce(jp.location_type, '') = 'On-site'
  ),
  attendance_enabled_orders as (
    select order_id
    from eligible_orders
    where coalesce(attendance_mode, 'disabled') <> 'disabled'
  )
  select
    (select count(*)::int from eligible_orders),
    (
      select count(*)::int
      from public.attendance_punches ap
      where ap.seller_id = p_seller_id
        and ap.punch_type = 'in'
        and ap.order_id in (select order_id from attendance_enabled_orders)
    ),
    (
      select count(distinct (ap.job_post_id, ap.punched_at::date))::int
      from public.attendance_punches ap
      where ap.seller_id = p_seller_id
        and ap.punch_type = 'in'
        and ap.order_id in (select order_id from attendance_enabled_orders)
    ),
    (
      select count(distinct eo.order_id)::int
      from eligible_orders eo
      where exists (
        select 1
        from public.attendance_punches ap
        where ap.order_id = eo.order_id
          and ap.seller_id = p_seller_id
      )
    )
  into v_completed, v_checkins, v_shift_days, v_with_attendance;

  with eligible_orders as (
    select
      o.id as order_id,
      o.completed_at,
      jp.title as job_title,
      c.name as category_name
    from public.orders o
    inner join public.job_offers jo on jo.id = o.job_offer_id
    inner join public.job_posts jp on jp.id = jo.job_post_id
    left join public.categories c on c.id = jp.category_id
    where o.seller_id = p_seller_id
      and o.status = 'completed'
      and coalesce(jp.location_type, '') = 'On-site'
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'job_title', h.job_title,
        'completed_month', to_char(h.completed_at, 'YYYY-MM'),
        'had_attendance', h.had_attendance,
        'category_name', h.category_name
      )
      order by h.completed_at desc nulls last
    ),
    '[]'::jsonb
  )
  into v_highlights
  from (
    select
      eo.job_title,
      eo.completed_at,
      eo.category_name,
      exists (
        select 1
        from public.attendance_punches ap
        where ap.order_id = eo.order_id
          and ap.seller_id = p_seller_id
      ) as had_attendance
    from eligible_orders eo
    order by eo.completed_at desc nulls last
    limit 5
  ) h;

  return jsonb_build_object(
    'completed_onsite_jobs', coalesce(v_completed, 0),
    'verified_checkins', coalesce(v_checkins, 0),
    'verified_shift_days', coalesce(v_shift_days, 0),
    'jobs_with_attendance', coalesce(v_with_attendance, 0),
    'highlights', coalesce(v_highlights, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.get_seller_public_work_trust(uuid) to authenticated;
grant execute on function public.get_seller_public_work_trust(uuid) to anon;
