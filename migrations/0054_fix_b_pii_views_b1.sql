-- ============================================
-- Migration 0054 — FIX B, step B1 (T-0119 / T-0128). ADDITIVE.
-- Safe to apply BEFORE the app release R1 and with today's app: nothing that
-- exists stops working. Idempotent.
--
-- Adds:
--   * seller_profiles.show_age (age consent, off by default; finding F7)
--   * views my_profile / my_seller_profile (owner-only full row) and
--     seller_public_age (whole-year age, only for sellers who opted in)
--   * browse_nearby_sellers: no longer returns latitude/longitude, and runs
--     as SECURITY DEFINER so it keeps working after step B2 (0055) removes
--     the callers' column access to profiles.latitude/longitude
--   * app_config + get_min_app_build(): minimum app build gate (read by R1;
--     min values stay 0 = no gate until 0057 is applied)
--
-- Apply order: 0053 -> 0054 -> (release app R1) -> 0055 -> 0057 -> later 0056.
-- Rollback: migrations/rollback/0054_fix_b_pii_views_b1_down.sql
--   (roll back together with R1; R1 reads these views).
--
-- Notes:
--  * The views are owned by the migration role and read the base tables with
--    the owner's rights (default Postgres view semantics, NOT security_invoker).
--    That is intentional: after B2 the API roles can no longer read the private
--    columns directly, only through these views, filtered to auth.uid().
--    Supabase's linter will flag them as "security definer view"; expected.
--  * Column lists are explicit (no select *), so that B3 can drop the old
--    seller_profiles.address / birth_* columns without breaking a view.
--  * Supabase grants new objects in public to anon/authenticated by default,
--    so every object below is revoked first and then granted explicitly.
-- ============================================

begin;

-- ---------------------------------------------------------------------
-- 1. Age consent
-- ---------------------------------------------------------------------
alter table public.seller_profiles
  add column if not exists show_age boolean not null default false;

-- ---------------------------------------------------------------------
-- 2. Owner-only views
-- ---------------------------------------------------------------------
create or replace view public.my_profile
  with (security_barrier = true) as
  select
    p.id, p.role, p.name, p.email, p.phone,
    p.country, p.city, p.gender, p.profile_image_url, p.bio,
    p.rating, p.balance, p.chat_contact_policy, p.charity_cause,
    p.created_at, p.seller_onboarding_completed,
    p.verification_status, p.verification_reviewed_at, p.verification_rejection_reason,
    p.profile_photo_status, p.profile_photo_reviewed_at, p.profile_photo_rejection_reason,
    p.company_name, p.company_registration_number, p.company_website,
    p.latitude, p.longitude
  from public.profiles p
  where p.id = auth.uid();

create or replace view public.my_seller_profile
  with (security_barrier = true) as
  select
    sp.id, sp.user_id, sp.job_title, sp.about, sp.skills, sp.languages,
    sp.education, sp.experience, sp.show_age,
    sp.impressions_count, sp.interactions_count, sp.reach_count, sp.created_at
  from public.seller_profiles sp
  where sp.user_id = auth.uid();

-- Public age: whole years, only when the seller turned show_age on.
create or replace view public.seller_public_age
  with (security_barrier = true) as
  select
    sp.user_id,
    case
      when sp.show_age and pd.date_of_birth is not null
        then date_part('year', age(pd.date_of_birth))::int
    end as age_years
  from public.seller_profiles sp
  left join public.seller_private_details pd on pd.user_id = sp.user_id;

revoke all on public.my_profile, public.my_seller_profile, public.seller_public_age
  from public, anon, authenticated;
grant select on public.my_profile, public.my_seller_profile to authenticated;
grant select on public.seller_public_age to anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. browse_nearby_sellers: same signature and result shape, minus
--    latitude/longitude. SECURITY DEFINER so it does not depend on the
--    caller's column grants (B2). Requires a signed-in caller as before.
-- ---------------------------------------------------------------------
create or replace function public.browse_nearby_sellers(
  p_query text default null,
  p_max_distance_km numeric default null,
  p_client_lat double precision default null,
  p_client_lng double precision default null,
  p_limit int default 48,
  p_offset int default 0
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 48), 100));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_query text := nullif(trim(coalesce(p_query, '')), '');
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_max_distance_km is not null and p_max_distance_km <= 0 then
    raise exception 'max_distance_km must be > 0';
  end if;

  if p_max_distance_km is not null
    and (p_client_lat is null or p_client_lng is null) then
    raise exception 'client location required for distance filter';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'profile_image_url', s.profile_image_url,
        'country', s.country,
        'city', s.city,
        'rating', s.rating,
        'verification_status', s.verification_status,
        'profile_photo_status', s.profile_photo_status,
        'distance_km', s.distance_km,
        'seller_profiles', s.seller_profiles
      )
      order by s.sort_distance asc, s.rating desc nulls last
    ),
    '[]'::jsonb
  )
  into v_result
  from (
    select
      p.id,
      p.name,
      p.profile_image_url,
      p.country,
      p.city,
      p.rating,
      p.verification_status,
      p.profile_photo_status,
      case
        when p_client_lat is not null
          and p_client_lng is not null
          and p.latitude is not null
          and p.longitude is not null
        then public.haversine_km(
          p_client_lat,
          p_client_lng,
          p.latitude,
          p.longitude
        )
        else null::double precision
      end as distance_km,
      coalesce(
        case
          when p_client_lat is not null
            and p_client_lng is not null
            and p.latitude is not null
            and p.longitude is not null
          then public.haversine_km(
            p_client_lat,
            p_client_lng,
            p.latitude,
            p.longitude
          )
          else null::double precision
        end,
        1e12::double precision
      ) as sort_distance,
      jsonb_build_object(
        'job_title', sp.job_title,
        'about', sp.about,
        'skills', sp.skills
      ) as seller_profiles
    from public.profiles p
    inner join public.seller_profiles sp on sp.user_id = p.id
    where p.role = 'seller'
      and (
        v_query is null
        or p.name ilike '%' || v_query || '%'
        or coalesce(sp.job_title, '') ilike '%' || v_query || '%'
      )
      and (
        p_max_distance_km is null
        or (
          p.latitude is not null
          and p.longitude is not null
          and public.haversine_km(
            p_client_lat,
            p_client_lng,
            p.latitude,
            p.longitude
          ) <= p_max_distance_km::double precision
        )
      )
    order by sort_distance asc, p.rating desc nulls last
    limit v_limit
    offset v_offset
  ) as s;

  return v_result;
end;
$$;

revoke all on function public.browse_nearby_sellers(
  text, numeric, double precision, double precision, int, int
) from public, anon;
grant execute on function public.browse_nearby_sellers(
  text, numeric, double precision, double precision, int, int
) to authenticated;

comment on function public.browse_nearby_sellers is
  'Employer talent browse: optional text query + optional haversine distance from client pin. Does not return coordinates.';

-- ---------------------------------------------------------------------
-- 4. Minimum app build gate. Single-row config, no direct client access;
--    the app calls get_min_app_build(platform). Values start at 0 (no gate).
--    Raising them is migration 0057 (apply only after R1 is released).
-- ---------------------------------------------------------------------
create table if not exists public.app_config (
  id int primary key default 1 check (id = 1),
  min_build_ios int not null default 0,
  min_build_android int not null default 0,
  update_url_ios text,
  update_url_android text,
  updated_at timestamptz not null default now()
);
insert into public.app_config (id) values (1) on conflict (id) do nothing;

alter table public.app_config enable row level security;
revoke all on table public.app_config from public, anon, authenticated;

create or replace function public.get_min_app_build(p_platform text)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'min_build',
      case lower(coalesce(p_platform, ''))
        when 'ios' then c.min_build_ios
        when 'android' then c.min_build_android
        else 0
      end,
    'update_url',
      case lower(coalesce(p_platform, ''))
        when 'ios' then c.update_url_ios
        when 'android' then c.update_url_android
        else null
      end
  )
  from public.app_config c
  where c.id = 1;
$$;

revoke all on function public.get_min_app_build(text) from public;
grant execute on function public.get_min_app_build(text) to anon, authenticated;

commit;
