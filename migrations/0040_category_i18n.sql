-- Migration 0040 — Multi-language category names/descriptions
-- Keeps canonical English `name` / `description` for uniqueness + matching.
-- Locale maps: {"en":"...","nl":"...","bn":"..."} (app language codes).

alter table public.categories
  add column if not exists name_i18n jsonb not null default '{}'::jsonb,
  add column if not exists description_i18n jsonb not null default '{}'::jsonb;

comment on column public.categories.name_i18n is
  'Localized display names keyed by language code (en, nl, bn). English name column remains canonical.';
comment on column public.categories.description_i18n is
  'Localized descriptions keyed by language code (en, nl, bn).';

-- Backfill English from existing columns for every row.
update public.categories
set
  name_i18n = coalesce(name_i18n, '{}'::jsonb) || jsonb_build_object('en', name),
  description_i18n = case
    when description is null or trim(description) = '' then coalesce(description_i18n, '{}'::jsonb)
    else coalesce(description_i18n, '{}'::jsonb) || jsonb_build_object('en', description)
  end
where true;

-- Seed NL / BN for known presets (match on English canonical name).
update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Schoonmaak & Facility',
    'bn', 'পরিষ্কার ও জ্যানিটোরিয়াল'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Conciërges, schoonmakers, gebouwonderhoud',
    'bn', 'জ্যানিটর, ক্লিনার, বিল্ডিং রক্ষণাবেক্ষণ'
  )
where lower(trim(name)) = lower('Cleaning & Janitorial');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Fabriek & Magazijn',
    'bn', 'কারখানা ও গুদাম'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Fabrieksarbeiders, inpakkers, magazijnmedewerkers',
    'bn', 'কারখানা শ্রমিক, প্যাকার, গুদাম কর্মী'
  )
where lower(trim(name)) = lower('Factory & Warehouse');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Ambachtelijke beroepen',
    'bn', 'দক্ষ ট্রেড'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Vakmensen, timmerlieden, elektriciens, loodgieters',
    'bn', 'কারিগর, ছুতার, ইলেকট্রিশিয়ান, প্লাম্বার'
  )
where lower(trim(name)) = lower('Skilled Trades');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Beauty & Salon',
    'bn', 'বিউটি ও সেলুন'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Kappers, barbiers, nagelstylisten, stylisten',
    'bn', 'হেয়ারড্রেসার, বারবার, নেইল টেক, স্টাইলিস্ট'
  )
where lower(trim(name)) = lower('Beauty & Salon');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Horeca',
    'bn', 'খাদ্য সেবা'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Kelners, koks, bakkers, keukenpersoneel',
    'bn', 'ওয়েটার, রাঁধুনি, বেকার, রান্নাঘরের কর্মী'
  )
where lower(trim(name)) = lower('Food Service');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Retail & Verkoop',
    'bn', 'খুচরা ও বিক্রয়'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Kassamedewerkers, winkelassistenten, vloerpersoneel',
    'bn', 'ক্যাশিয়ার, দোকান সহায়ক, ফ্লোর স্টাফ'
  )
where lower(trim(name)) = lower('Retail & Sales');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Bezorging & Rijden',
    'bn', 'ডেলিভারি ও ড্রাইভিং'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Chauffeurs, koeriers, bezorghelpers',
    'bn', 'ড্রাইভার, কুরিয়ার, ডেলিভারি সহায়ক'
  )
where lower(trim(name)) = lower('Delivery & Driving');

update public.categories set
  name_i18n = name_i18n || jsonb_build_object(
    'nl', 'Algemeen werk',
    'bn', 'সাধারণ শ্রম'
  ),
  description_i18n = description_i18n || jsonb_build_object(
    'nl', 'Bouwhelpers, verhuizers, klusjesmannen, onsite helpers',
    'bn', 'নির্মাণ সহায়ক, মুভার, হ্যান্ডম্যান, অনসাইট সহায়ক'
  )
where lower(trim(name)) = lower('General Labor');

-- Include i18n maps in browse RPC nested category payload (same signature as 0031).
create or replace function public.browse_open_job_posts(
  p_title_query text default null,
  p_category_ids uuid[] default null,
  p_skill_names text[] default null,
  p_job_type text default null,
  p_max_distance_km numeric default null,
  p_include_remote boolean default true,
  p_seller_lat double precision default null,
  p_seller_lng double precision default null,
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 100));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_title text := nullif(trim(coalesce(p_title_query, '')), '');
  v_result jsonb;
begin
  if p_job_type is not null
    and p_job_type not in ('gig', 'full_time', 'part_time') then
    raise exception 'invalid job_type';
  end if;

  if p_max_distance_km is not null and p_max_distance_km <= 0 then
    raise exception 'max_distance_km must be > 0';
  end if;

  select coalesce(jsonb_agg(to_jsonb(row_data) order by row_data.created_at desc), '[]'::jsonb)
  into v_result
  from (
    select
      jp.id,
      jp.client_id,
      jp.title,
      jp.description,
      jp.category_id,
      jp.budget_min,
      jp.budget_max,
      jp.budget_basis,
      jp.deadline,
      jp.status,
      jp.job_type,
      jp.location,
      jp.location_type,
      jp.latitude,
      jp.longitude,
      jp.workers_needed,
      jp.attendance_mode,
      jp.work_date,
      jp.shift_start,
      jp.shift_end,
      jp.created_at,
      case
        when c.id is null then null
        else jsonb_build_object(
          'name', c.name,
          'name_i18n', coalesce(c.name_i18n, '{}'::jsonb),
          'description', c.description,
          'description_i18n', coalesce(c.description_i18n, '{}'::jsonb)
        )
      end as categories,
      (
        select coalesce(
          jsonb_agg(
            jsonb_build_object(
              'skill_name', jps.skill_name,
              'skill_catalog_id', jps.skill_catalog_id
            )
            order by jps.skill_name
          ),
          '[]'::jsonb
        )
        from public.job_post_skills jps
        where jps.job_post_id = jp.id
      ) as job_post_skills,
      case
        when p.id is null then null
        else jsonb_build_object(
          'id', p.id,
          'name', p.name,
          'profile_image_url', p.profile_image_url,
          'rating', p.rating,
          'created_at', p.created_at,
          'country', p.country,
          'city', p.city
        )
      end as profiles
    from public.job_posts jp
    left join public.categories c on c.id = jp.category_id
    left join public.profiles p on p.id = jp.client_id
    where jp.status = 'open'
      and (v_title is null or jp.title ilike '%' || v_title || '%')
      and (
        coalesce(array_length(p_category_ids, 1), 0) = 0
        or jp.category_id = any (p_category_ids)
      )
      and (p_job_type is null or jp.job_type = p_job_type)
      and (
        coalesce(array_length(p_skill_names, 1), 0) = 0
        or exists (
          select 1
          from public.job_post_skills jps
          cross join lateral unnest(p_skill_names) as sn(name)
          where jps.job_post_id = jp.id
            and lower(trim(jps.skill_name)) = lower(trim(sn.name))
        )
      )
      and (
        case
          when coalesce(jp.location_type, '') = 'Remote' then
            coalesce(p_include_remote, true)
          when p_max_distance_km is null then
            true
          when p_seller_lat is null
            or p_seller_lng is null
            or jp.latitude is null
            or jp.longitude is null then
            false
          else
            public.haversine_km(
              p_seller_lat,
              p_seller_lng,
              jp.latitude,
              jp.longitude
            ) <= p_max_distance_km::double precision
        end
      )
    order by jp.created_at desc
    limit v_limit
    offset v_offset
  ) as row_data;

  return v_result;
end;
$$;

grant execute on function public.browse_open_job_posts(
  text, uuid[], text[], text, numeric, boolean,
  double precision, double precision, int, int
) to authenticated;
