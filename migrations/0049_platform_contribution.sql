-- ============================================
-- Migration 0049 — platform contribution share
-- Returns the signed-in user's share of completed work.
-- Totals only: no other profiles, orders, or hour rows.
-- This is contribution, not equity and not a payout.
-- ============================================

create or replace function public.my_platform_contribution()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_shifts int := 0;
  v_platform_shifts int := 0;
  v_minutes numeric := 0;
  v_platform_minutes numeric := 0;
  v_value numeric := 0;
  v_platform_value numeric := 0;
  v_share numeric := 0;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select p.role
  into v_role
  from public.profiles p
  where p.id = v_uid;

  if v_role is null or v_role not in ('client', 'seller') then
    raise exception 'Profile not found';
  end if;

  select count(*)::int, coalesce(sum(o.price), 0)
  into v_platform_shifts, v_platform_value
  from public.orders o
  where o.status = 'completed';

  if v_role = 'seller' then
    select count(*)::int, coalesce(sum(o.price), 0)
    into v_shifts, v_value
    from public.orders o
    where o.status = 'completed'
      and o.seller_id = v_uid;

    select coalesce(sum(hr.minutes), 0)
    into v_minutes
    from public.hour_reports hr
    where hr.status = 'accepted'
      and hr.seller_id = v_uid;
  else
    select count(*)::int, coalesce(sum(o.price), 0)
    into v_shifts, v_value
    from public.orders o
    where o.status = 'completed'
      and o.client_id = v_uid;

    select coalesce(sum(hr.minutes), 0)
    into v_minutes
    from public.hour_reports hr
    where hr.status = 'accepted'
      and hr.client_id = v_uid;
  end if;

  select coalesce(sum(hr.minutes), 0)
  into v_platform_minutes
  from public.hour_reports hr
  where hr.status = 'accepted';

  if v_platform_value > 0 then
    v_share := round((v_value / v_platform_value) * 100, 2);
  end if;

  return jsonb_build_object(
    'role', v_role,
    'shifts_completed', v_shifts,
    'platform_shifts', v_platform_shifts,
    'hours_minutes', v_minutes,
    'platform_hours_minutes', v_platform_minutes,
    'work_value', v_value,
    'platform_work_value', v_platform_value,
    'share_percent', v_share
  );
end;
$$;

revoke all on function public.my_platform_contribution() from public;
grant execute on function public.my_platform_contribution() to authenticated;
