-- Real skill tags on job posts (replaces title/description text "skill" matching).
-- Safe to re-run.

create table if not exists public.job_post_skills (
  id uuid primary key default gen_random_uuid(),
  job_post_id uuid not null references public.job_posts (id) on delete cascade,
  skill_catalog_id uuid references public.skill_catalog (id) on delete set null,
  skill_name text not null,
  created_at timestamptz not null default now(),
  constraint job_post_skills_name_nonempty check (length(trim(skill_name)) > 0)
);

create unique index if not exists job_post_skills_job_name_unique
  on public.job_post_skills (job_post_id, lower(trim(skill_name)));

create index if not exists job_post_skills_job_post_id_idx
  on public.job_post_skills (job_post_id);

alter table public.job_post_skills enable row level security;

drop policy if exists "Job post skills are viewable by everyone" on public.job_post_skills;
create policy "Job post skills are viewable by everyone"
  on public.job_post_skills for select using (true);

drop policy if exists "Clients manage skills on own job posts" on public.job_post_skills;
create policy "Clients manage skills on own job posts"
  on public.job_post_skills for all
  using (
    auth.uid() in (
      select jp.client_id from public.job_posts jp where jp.id = job_post_id
    )
  )
  with check (
    auth.uid() in (
      select jp.client_id from public.job_posts jp where jp.id = job_post_id
    )
  );

-- Drop old matcher signature (text skills only) then recreate with job skill tags.
drop function if exists public.job_post_matches_alert_rule(
  text, text, text, uuid, text, text,
  double precision, double precision, double precision, double precision,
  uuid[], text[], text, numeric, boolean
);

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
  p_job_skill_names text[],
  p_rule_job_type text,
  p_max_distance_km numeric,
  p_include_remote boolean
) returns boolean
language plpgsql
immutable
as $$
declare
  v_skill text;
  v_skill_l text;
  v_matched_skill boolean := false;
begin
  if coalesce(array_length(p_category_ids, 1), 0) > 0 then
    if p_category_id is null or not (p_category_id = any (p_category_ids)) then
      return false;
    end if;
  end if;

  -- Skill rules match tagged job skills only (not title/description/category text).
  if coalesce(array_length(p_skill_names, 1), 0) > 0 then
    v_matched_skill := false;
    foreach v_skill in array p_skill_names loop
      v_skill_l := lower(trim(v_skill));
      if v_skill_l = '' then
        continue;
      end if;
      if exists (
        select 1
        from unnest(coalesce(p_job_skill_names, '{}'::text[])) as js(name)
        where lower(trim(js.name)) = v_skill_l
      ) then
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
  v_job_skills text[];
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

  select coalesce(array_agg(jps.skill_name order by jps.skill_name), '{}'::text[])
  into v_job_skills
  from public.job_post_skills jps
  where jps.job_post_id = p_job_post_id;

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
            v_job_skills,
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

create or replace function public.trg_job_post_skills_process_alerts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.process_job_post_alerts(
    coalesce(new.job_post_id, old.job_post_id)
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists job_post_skills_process_alerts on public.job_post_skills;
create trigger job_post_skills_process_alerts
  after insert or update or delete
  on public.job_post_skills
  for each row
  execute function public.trg_job_post_skills_process_alerts();
