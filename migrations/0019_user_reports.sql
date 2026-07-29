-- ============================================
-- Migration 0019 — User reports
-- Marketplace abuse / content reports from clients & sellers
-- ============================================

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

create index if not exists user_reports_reporter_id_idx
  on public.user_reports (reporter_id);

create index if not exists user_reports_reported_user_id_idx
  on public.user_reports (reported_user_id);

create index if not exists user_reports_status_created_at_idx
  on public.user_reports (status, created_at desc);

alter table public.user_reports enable row level security;

drop policy if exists "Users can insert own reports" on public.user_reports;
create policy "Users can insert own reports"
  on public.user_reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Users can view own reports" on public.user_reports;
create policy "Users can view own reports"
  on public.user_reports for select
  using (auth.uid() = reporter_id);
