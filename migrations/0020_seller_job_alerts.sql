-- ============================================
-- Migration 0020 — Seller job match alerts
-- Profile coordinates, alert rules, matcher + trigger
-- ============================================

alter table public.profiles
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

-- ---------------------------------------------------------------------------
-- Alert rules (sellers CRUD own rows)
-- ---------------------------------------------------------------------------

create table if not exists public.seller_job_alert_rules (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  name text,
  enabled boolean not null default true,
  category_ids uuid[] not null default '{}',
  skill_names text[] not null default '{}',
  job_type text check (job_type is null or job_type in ('gig', 'full_time', 'part_time')),
  max_distance_km numeric(8, 2) check (max_distance_km is null or max_distance_km > 0),
  include_remote boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists seller_job_alert_rules_seller_enabled_idx
  on public.seller_job_alert_rules (seller_id)
  where enabled;

alter table public.seller_job_alert_rules enable row level security;

drop policy if exists "Sellers manage own job alert rules" on public.seller_job_alert_rules;
create policy "Sellers manage own job alert rules"
  on public.seller_job_alert_rules
  for all
  using (auth.uid() = seller_id)
  with check (auth.uid() = seller_id);

-- ---------------------------------------------------------------------------
-- One notification per seller per job post
-- ---------------------------------------------------------------------------

create table if not exists public.seller_job_alert_deliveries (
  seller_id uuid not null references public.profiles(id) on delete cascade,
  job_post_id uuid not null references public.job_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (seller_id, job_post_id)
);

alter table public.seller_job_alert_deliveries enable row level security;

drop policy if exists "Sellers read own alert deliveries" on public.seller_job_alert_deliveries;
create policy "Sellers read own alert deliveries"
  on public.seller_job_alert_deliveries
  for select
  using (auth.uid() = seller_id);

-- Inserts only via security definer matcher (no client insert policy).

-- ---------------------------------------------------------------------------
-- Geo + matching helpers
-- ---------------------------------------------------------------------------

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

create or replace function public.job_post_matches_alert_rule(
  p_title text,
  p_description text,
  p_category_name text,
  p_category_id uuid,
  p_job_type text,
  p_location_type text,
  p_job_lat double precision,
  p_job_lng double precision,
  p_seller_lat double precision,
  p_seller_lng double precision,
  p_category_ids uuid[],
  p_skill_names text[],
  p_rule_job_type text,
  p_max_distance_km numeric,
  p_include_remote boolean
) returns boolean
language plpgsql
immutable
as $$
declare
  v_skill text;
  v_title_l text := lower(coalesce(p_title, ''));
  v_desc_l text := lower(coalesce(p_description, ''));
  v_cat_l text := lower(coalesce(p_category_name, ''));
  v_skill_l text;
  v_matched_skill boolean := false;
begin
  if coalesce(array_length(p_category_ids, 1), 0) > 0 then
    if p_category_id is null or not (p_category_id = any (p_category_ids)) then
      return false;
    end if;
  end if;

  if coalesce(array_length(p_skill_names, 1), 0) > 0 then
    v_matched_skill := false;
    foreach v_skill in array p_skill_names loop
      v_skill_l := lower(trim(v_skill));
      if v_skill_l = '' then
        continue;
      end if;
      if v_title_l like '%' || v_skill_l || '%'
        or v_desc_l like '%' || v_skill_l || '%'
        or v_cat_l like '%' || v_skill_l || '%' then
        v_matched_skill := true;
        exit;
      end if;
    end loop;
    if not v_matched_skill then
      return false;
    end if;
  end if;

  if p_rule_job_type is not null and p_rule_job_type is distinct from p_job_type then
    return false;
  end if;

  if coalesce(p_location_type, '') = 'Remote' then
    return coalesce(p_include_remote, true);
  end if;

  if p_max_distance_km is null then
    return true;
  end if;

  if p_seller_lat is null or p_seller_lng is null
    or p_job_lat is null or p_job_lng is null then
    return false;
  end if;

  return public.haversine_km(p_seller_lat, p_seller_lng, p_job_lat, p_job_lng)
    <= p_max_distance_km::double precision;
end;
$$;

create or replace function public.process_job_post_alerts(p_job_post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job record;
  v_seller_id uuid;
  v_title text;
  v_body text;
  v_inserted boolean;
begin
  select
    jp.id,
    jp.status,
    jp.client_id,
    jp.category_id,
    jp.title,
    jp.description,
    jp.job_type,
    jp.location_type,
    jp.latitude,
    jp.longitude,
    c.name as category_name
  into v_job
  from public.job_posts jp
  left join public.categories c on c.id = jp.category_id
  where jp.id = p_job_post_id;

  if not found or v_job.status is distinct from 'open' then
    return;
  end if;

  for v_seller_id in
    select distinct r.seller_id
    from public.seller_job_alert_rules r
    where r.enabled
      and r.seller_id is distinct from v_job.client_id
      and not exists (
        select 1
        from public.seller_job_alert_deliveries d
        where d.seller_id = r.seller_id
          and d.job_post_id = p_job_post_id
      )
      and exists (
        select 1
        from public.seller_job_alert_rules r2
        join public.profiles p2 on p2.id = r2.seller_id
        where r2.seller_id = r.seller_id
          and r2.enabled
          and public.job_post_matches_alert_rule(
            v_job.title,
            v_job.description,
            v_job.category_name,
            v_job.category_id,
            v_job.job_type,
            v_job.location_type,
            v_job.latitude,
            v_job.longitude,
            p2.latitude,
            p2.longitude,
            r2.category_ids,
            r2.skill_names,
            r2.job_type,
            r2.max_distance_km,
            r2.include_remote
          )
      )
  loop
    v_inserted := false;
    begin
      insert into public.seller_job_alert_deliveries (seller_id, job_post_id)
      values (v_seller_id, p_job_post_id);
      v_inserted := true;
    exception
      when unique_violation then
        v_inserted := false;
    end;

    if v_inserted then
      v_title := coalesce(nullif(trim(v_job.title), ''), 'New job match');
      v_body := 'A new job matches your saved alert. Tap to view details.';
      perform public.create_notification(
        v_seller_id,
        v_title,
        v_body,
        'job_match',
        p_job_post_id
      );
    end if;
  end loop;
end;
$$;

create or replace function public.trg_job_posts_process_alerts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.process_job_post_alerts(new.id);
  return new;
end;
$$;

drop trigger if exists job_posts_process_alerts on public.job_posts;
create trigger job_posts_process_alerts
  after insert or update of status, category_id, title, description, job_type, location_type, latitude, longitude
  on public.job_posts
  for each row
  execute function public.trg_job_posts_process_alerts();

create or replace function public.trg_seller_job_alert_rules_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists seller_job_alert_rules_updated_at on public.seller_job_alert_rules;
create trigger seller_job_alert_rules_updated_at
  before update on public.seller_job_alert_rules
  for each row
  execute function public.trg_seller_job_alert_rules_updated_at();
