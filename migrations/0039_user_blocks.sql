-- ============================================
-- Migration 0039 — Soft blocks with open-obligation protection
-- Directional blocks; messaging/discovery hide is mutual.
-- Active / unpaid shared orders stay usable for both parties.
-- ============================================

-- Ensure report tables exist (idempotent if 0019/0023 already applied)
create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  reason text not null,
  details text,
  profile_url text,
  content_url text,
  status text not null default 'open'
    check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  constraint user_reports_not_self check (
    reported_user_id is null or reported_user_id <> reporter_id
  )
);

alter table public.user_reports
  add column if not exists job_post_id uuid references public.job_posts(id) on delete set null,
  add column if not exists order_id uuid references public.orders(id) on delete set null;

create index if not exists user_reports_reporter_id_idx
  on public.user_reports (reporter_id);
create index if not exists user_reports_reported_user_id_idx
  on public.user_reports (reported_user_id);
create index if not exists user_reports_status_created_at_idx
  on public.user_reports (status, created_at desc);
create index if not exists user_reports_job_post_id_idx
  on public.user_reports (job_post_id)
  where job_post_id is not null;
create index if not exists user_reports_order_id_idx
  on public.user_reports (order_id)
  where order_id is not null;

alter table public.user_reports enable row level security;

drop policy if exists "Users can insert own reports" on public.user_reports;
create policy "Users can insert own reports"
  on public.user_reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Users can view own reports" on public.user_reports;
create policy "Users can view own reports"
  on public.user_reports for select
  using (auth.uid() = reporter_id);

-- Soft blocks
create table if not exists public.user_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  constraint user_blocks_not_self check (blocker_id <> blocked_id),
  constraint user_blocks_unique_pair unique (blocker_id, blocked_id)
);

create index if not exists user_blocks_blocker_id_idx
  on public.user_blocks (blocker_id);

create index if not exists user_blocks_blocked_id_idx
  on public.user_blocks (blocked_id);

alter table public.user_blocks enable row level security;

drop policy if exists "Users can insert own blocks" on public.user_blocks;
create policy "Users can insert own blocks"
  on public.user_blocks for insert
  with check (auth.uid() = blocker_id);

drop policy if exists "Users can view own blocks" on public.user_blocks;
create policy "Users can view own blocks"
  on public.user_blocks for select
  using (auth.uid() = blocker_id or auth.uid() = blocked_id);

drop policy if exists "Users can delete own blocks" on public.user_blocks;
create policy "Users can delete own blocks"
  on public.user_blocks for delete
  using (auth.uid() = blocker_id);

-- Open obligation: active workflow OR completed without payment confirmation
create or replace function public.pair_open_order_ids(
  p_user_a uuid,
  p_user_b uuid
)
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(o.id order by o.created_at desc), '{}'::uuid[])
  from public.orders o
  where (
      (o.client_id = p_user_a and o.seller_id = p_user_b)
      or (o.client_id = p_user_b and o.seller_id = p_user_a)
    )
    and (
      lower(coalesce(o.status, '')) in (
        'pending', 'active', 'delivered', 'cancellation_requested'
      )
      or (
        lower(coalesce(o.status, '')) = 'completed'
        and o.payment_received_at is null
      )
    );
$$;

create or replace function public.pair_has_open_obligation(
  p_user_a uuid,
  p_user_b uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select cardinality(public.pair_open_order_ids(p_user_a, p_user_b)) > 0;
$$;

create or replace function public.pair_is_blocked(
  p_user_a uuid,
  p_user_b uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_blocks b
    where (b.blocker_id = p_user_a and b.blocked_id = p_user_b)
       or (b.blocker_id = p_user_b and b.blocked_id = p_user_a)
  );
$$;

-- True when messaging / new contact should be refused
create or replace function public.pair_contact_blocked(
  p_user_a uuid,
  p_user_b uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.pair_is_blocked(p_user_a, p_user_b)
    and not public.pair_has_open_obligation(p_user_a, p_user_b);
$$;

grant execute on function public.pair_open_order_ids(uuid, uuid) to authenticated;
grant execute on function public.pair_has_open_obligation(uuid, uuid) to authenticated;
grant execute on function public.pair_is_blocked(uuid, uuid) to authenticated;
grant execute on function public.pair_contact_blocked(uuid, uuid) to authenticated;

create or replace function public.block_user(
  p_blocked_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_blocker uuid := auth.uid();
  v_order_ids uuid[];
begin
  if v_blocker is null then
    raise exception 'Not authenticated';
  end if;
  if p_blocked_id is null then
    raise exception 'blocked_id is required';
  end if;
  if p_blocked_id = v_blocker then
    raise exception 'You cannot block yourself';
  end if;
  if not exists (select 1 from public.profiles where id = p_blocked_id) then
    raise exception 'User not found';
  end if;

  insert into public.user_blocks (blocker_id, blocked_id, reason)
  values (v_blocker, p_blocked_id, nullif(trim(coalesce(p_reason, '')), ''))
  on conflict (blocker_id, blocked_id) do update
    set reason = coalesce(excluded.reason, public.user_blocks.reason);

  v_order_ids := public.pair_open_order_ids(v_blocker, p_blocked_id);

  return jsonb_build_object(
    'ok', true,
    'has_open_obligation', cardinality(v_order_ids) > 0,
    'open_order_ids', to_jsonb(v_order_ids)
  );
end;
$$;

create or replace function public.unblock_user(
  p_blocked_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_blocker uuid := auth.uid();
begin
  if v_blocker is null then
    raise exception 'Not authenticated';
  end if;
  if p_blocked_id is null then
    raise exception 'blocked_id is required';
  end if;

  delete from public.user_blocks
  where blocker_id = v_blocker
    and blocked_id = p_blocked_id;

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.block_user(uuid, text) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;

notify pgrst, 'reload schema';
