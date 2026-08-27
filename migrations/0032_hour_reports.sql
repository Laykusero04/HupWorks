-- Auto hour reports from clock-out + employer accept/decline.
-- Safe to re-run.

-- 1. Table
create table if not exists public.hour_reports (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  job_post_id uuid not null references public.job_posts(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  work_date date not null,
  minutes numeric(10,1) not null check (minutes > 0),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  decline_reason text,
  in_punch_id uuid references public.attendance_punches(id) on delete set null,
  out_punch_id uuid references public.attendance_punches(id) on delete set null,
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles(id)
);

create unique index if not exists hour_reports_out_punch_uidxa
  on public.hour_reports (out_punch_id)
  where out_punch_id is not null;

create index if not exists hour_reports_client_status_idx
  on public.hour_reports (client_id, status, created_at desc);

create index if not exists hour_reports_order_idx
  on public.hour_reports (order_id, created_at desc);

create index if not exists hour_reports_seller_idx
  on public.hour_reports (seller_id, created_at desc);

alter table public.hour_reports enable row level security;

drop policy if exists "Hour reports visible to participants" on public.hour_reports;
create policy "Hour reports visible to participants"
  on public.hour_reports for select
  using (auth.uid() = client_id or auth.uid() = seller_id);

-- Inserts/updates only via SECURITY DEFINER RPCs.

-- 2. Auto-create hour report on clock-out (shared punch helper)
create or replace function public._attendance_record_punch(
  p_job_post_id uuid,
  p_order_id uuid,
  p_client_id uuid,
  p_title text,
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
  v_punch_id uuid;
  v_minutes_today numeric;
  v_out_at timestamptz;
  v_in_id uuid;
  v_in_at timestamptz;
  v_segment_minutes numeric;
  v_work_date date;
  v_report_id uuid;
  v_seller_name text;
begin
  insert into public.attendance_punches (
    job_post_id, order_id, seller_id, client_id,
    punch_type, scan_latitude, scan_longitude
  )
  values (
    p_job_post_id, p_order_id, auth.uid(), p_client_id,
    p_punch_type, p_latitude, p_longitude
  )
  returning id, punched_at into v_punch_id, v_out_at;

  perform public.create_notification(
    p_client_id,
    case when p_punch_type = 'in' then 'Worker clocked in' else 'Worker clocked out' end,
    coalesce(
      (select name from public.profiles where id = auth.uid()),
      'A worker'
    ) || ' ' || case when p_punch_type = 'in' then 'clocked in' else 'clocked out' end
      || ' for "' || coalesce(p_title, 'your job') || '".',
    'attendance',
    p_order_id
  );

  if p_punch_type = 'out' then
    select ap.id, ap.punched_at
    into v_in_id, v_in_at
    from public.attendance_punches ap
    where ap.seller_id = auth.uid()
      and ap.job_post_id = p_job_post_id
      and ap.punch_type = 'in'
      and ap.punched_at < v_out_at
    order by ap.punched_at desc
    limit 1;

    if v_in_id is not null then
      v_segment_minutes := round(
        (extract(epoch from (v_out_at - v_in_at)) / 60.0)::numeric,
        1
      );

      if v_segment_minutes > 0 then
        select coalesce(o.work_date, (v_out_at at time zone 'utc')::date)
        into v_work_date
        from public.orders o
        where o.id = p_order_id;

        if v_work_date is null then
          v_work_date := (v_out_at at time zone 'utc')::date;
        end if;

        begin
          insert into public.hour_reports (
            order_id, job_post_id, seller_id, client_id,
            work_date, minutes, status, in_punch_id, out_punch_id
          )
          values (
            p_order_id, p_job_post_id, auth.uid(), p_client_id,
            v_work_date, v_segment_minutes, 'pending', v_in_id, v_punch_id
          )
          returning id into v_report_id;
        exception
          when unique_violation then
            select hr.id into v_report_id
            from public.hour_reports hr
            where hr.out_punch_id = v_punch_id
            limit 1;
        end;

        if v_report_id is not null then
          select coalesce(name, 'A worker') into v_seller_name
          from public.profiles where id = auth.uid();

          perform public.create_notification(
            p_client_id,
            'Hours submitted for review',
            v_seller_name || ' submitted hours for "'
              || coalesce(p_title, 'your job')
              || '". Accept or decline in the order.',
            'hour_report',
            p_order_id
          );
        end if;
      end if;
    end if;
  end if;

  select coalesce(sum(
    extract(epoch from (out_p.punched_at - in_p.punched_at)) / 60.0
  ), 0)
  into v_minutes_today
  from public.attendance_punches in_p
  join public.attendance_punches out_p
    on out_p.seller_id = in_p.seller_id
   and out_p.job_post_id = in_p.job_post_id
   and out_p.punch_type = 'out'
   and out_p.punched_at > in_p.punched_at
   and out_p.punched_at = (
     select min(ap.punched_at)
     from public.attendance_punches ap
     where ap.seller_id = in_p.seller_id
       and ap.job_post_id = in_p.job_post_id
       and ap.punch_type = 'out'
       and ap.punched_at > in_p.punched_at
   )
  where in_p.seller_id = auth.uid()
    and in_p.job_post_id = p_job_post_id
    and in_p.punch_type = 'in'
    and in_p.punched_at::date = (now() at time zone 'utc')::date;

  return jsonb_build_object(
    'success', true,
    'punch_id', v_punch_id,
    'punch_type', p_punch_type,
    'punched_at', now(),
    'is_clocked_in', p_punch_type = 'in',
    'minutes_worked_today', round(coalesce(v_minutes_today, 0)::numeric, 1),
    'job_post_id', p_job_post_id,
    'order_id', p_order_id,
    'hour_report_id', v_report_id
  );
end;
$$;

-- 3. Client accepts hours
create or replace function public.accept_hour_report(p_report_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_report public.hour_reports%rowtype;
  v_title text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_report
  from public.hour_reports
  where id = p_report_id
  for update;

  if not found then
    raise exception 'Hour report not found';
  end if;

  if v_report.client_id is distinct from auth.uid() then
    raise exception 'Only the employer can accept hours';
  end if;

  if lower(coalesce(v_report.status, '')) <> 'pending' then
    raise exception 'This hour report is no longer pending';
  end if;

  update public.hour_reports
  set
    status = 'accepted',
    decided_at = now(),
    decided_by = auth.uid(),
    decline_reason = null
  where id = p_report_id;

  select jp.title into v_title
  from public.job_posts jp
  where jp.id = v_report.job_post_id;

  perform public.create_notification(
    v_report.seller_id,
    'Hours accepted',
    'Your hours for "' || coalesce(v_title, 'the job')
      || '" were accepted. Arrange payment outside the app.',
    'hour_report',
    v_report.order_id
  );
end;
$$;

grant execute on function public.accept_hour_report(uuid) to authenticated;

-- 4. Client declines hours
create or replace function public.decline_hour_report(
  p_report_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_report public.hour_reports%rowtype;
  v_title text;
  v_reason text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_report
  from public.hour_reports
  where id = p_report_id
  for update;

  if not found then
    raise exception 'Hour report not found';
  end if;

  if v_report.client_id is distinct from auth.uid() then
    raise exception 'Only the employer can decline hours';
  end if;

  if lower(coalesce(v_report.status, '')) <> 'pending' then
    raise exception 'This hour report is no longer pending';
  end if;

  v_reason := nullif(trim(coalesce(p_reason, '')), '');
  if v_reason is not null and char_length(v_reason) > 500 then
    raise exception 'Decline reason is too long';
  end if;

  update public.hour_reports
  set
    status = 'declined',
    decided_at = now(),
    decided_by = auth.uid(),
    decline_reason = v_reason
  where id = p_report_id;

  select jp.title into v_title
  from public.job_posts jp
  where jp.id = v_report.job_post_id;

  perform public.create_notification(
    v_report.seller_id,
    'Hours declined',
    coalesce(
      'Your hours for "' || coalesce(v_title, 'the job') || '" were declined'
        || case when v_reason is null then '.' else ': ' || v_reason end,
      'Your hours were declined.'
    ),
    'hour_report',
    v_report.order_id
  );
end;
$$;

grant execute on function public.decline_hour_report(uuid, text) to authenticated;
