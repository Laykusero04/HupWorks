-- Job / order shift schedule (foundation for hour approval + timed chat).
-- work_date: optional calendar day for the shift
-- shift_start / shift_end: clock times (e.g. 06:00–15:00); overnight allowed when end < start
-- Safe to re-run.

alter table public.job_posts
  add column if not exists work_date date,
  add column if not exists shift_start time,
  add column if not exists shift_end time;

alter table public.orders
  add column if not exists work_date date,
  add column if not exists shift_start time,
  add column if not exists shift_end time;

comment on column public.job_posts.work_date is 'Optional work day for the shift';
comment on column public.job_posts.shift_start is 'Daily/shift start time (local clock)';
comment on column public.job_posts.shift_end is 'Daily/shift end time (local clock)';
comment on column public.orders.work_date is 'Snapshot of job work_date at hire';
comment on column public.orders.shift_start is 'Snapshot of job shift_start at hire';
comment on column public.orders.shift_end is 'Snapshot of job shift_end at hire';

-- Copy shift fields onto the order when hiring.
create or replace function public.accept_job_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_id uuid;
  v_client uuid;
  v_seller uuid;
  v_price numeric;
  v_delivery_time int;
  v_delivery_time_unit text;
  v_workers_needed int;
  v_offer_status text;
  v_job_status text;
  v_job_title text;
  v_deadline timestamptz;
  v_unit text;
  v_accepted_before int;
  v_accepted_after int;
  v_order_id uuid;
  v_work_date date;
  v_shift_start time;
  v_shift_end time;
begin
  select
    jo.job_post_id,
    jo.seller_id,
    jo.price,
    jo.delivery_time,
    jo.delivery_time_unit,
    jp.client_id,
    jp.workers_needed,
    jo.status,
    jp.status,
    jp.title,
    jp.work_date,
    jp.shift_start,
    jp.shift_end
  into
    v_post_id,
    v_seller,
    v_price,
    v_delivery_time,
    v_delivery_time_unit,
    v_client,
    v_workers_needed,
    v_offer_status,
    v_job_status,
    v_job_title,
    v_work_date,
    v_shift_start,
    v_shift_end
  from public.job_offers jo
  join public.job_posts jp on jp.id = jo.job_post_id
  where jo.id = p_offer_id;

  if not found then
    raise exception 'Offer not found';
  end if;

  if v_client is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  if lower(coalesce(v_job_status, '')) <> 'open' then
    raise exception 'This job is not open for new hires';
  end if;

  if lower(coalesce(v_offer_status, '')) <> 'pending' then
    raise exception 'This application is not pending';
  end if;

  v_workers_needed := greatest(1, coalesce(v_workers_needed, 1));

  select count(*)::int into v_accepted_before
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 then
    if v_accepted_before >= v_workers_needed then
      raise exception 'Hiring limit reached for this job';
    end if;
  end if;

  if v_delivery_time is null then
    v_deadline := null;
  else
    v_unit := lower(trim(coalesce(v_delivery_time_unit, 'days')));
    if v_unit = 'hours' then
      v_deadline := now() + make_interval(hours => greatest(1, v_delivery_time));
    else
      v_deadline := now() + make_interval(days => greatest(1, v_delivery_time));
    end if;
  end if;

  update public.job_offers set status = 'accepted' where id = p_offer_id;

  select count(*)::int into v_accepted_after
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 and v_accepted_after >= v_workers_needed then
    update public.job_posts set status = 'closed' where id = v_post_id;
  end if;

  insert into public.orders
    (job_offer_id, client_id, seller_id, price, status, delivery_deadline,
     work_date, shift_start, shift_end)
  values
    (p_offer_id, v_client, v_seller, v_price, 'active', v_deadline,
     v_work_date, v_shift_start, v_shift_end)
  returning id into v_order_id;

  perform public.create_notification(
    v_seller,
    'Application accepted',
    coalesce('Your application for "' || v_job_title || '" was accepted.', 'Your application was accepted.'),
    'order',
    v_order_id
  );

  perform public.create_hire_onboarding_draft(v_order_id);

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;

-- Include shift fields in Find Jobs browse payload.
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
        else jsonb_build_object('name', c.name)
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
