-- Nearby freelancer browse for employers (mirrors browse_open_job_posts distance).
-- Uses profiles.latitude/longitude + public.haversine_km (0020).

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
security invoker
set search_path = public
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 48), 100));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_query text := nullif(trim(coalesce(p_query, '')), '');
  v_result jsonb;
begin
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
        'latitude', s.latitude,
        'longitude', s.longitude,
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
      p.latitude,
      p.longitude,
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

grant execute on function public.browse_nearby_sellers(
  text, numeric, double precision, double precision, int, int
) to authenticated;

comment on function public.browse_nearby_sellers is
  'Employer talent browse: optional text query + optional haversine distance from client pin.';
