-- ============================================
-- Migration 0022 — Favourites → saved job posts
-- Freelancers bookmark jobs (not services / clients).
-- Old service-based favourite rows are discarded.
-- ============================================

drop table if exists public.favourites cascade;

create table public.favourites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  job_post_id uuid not null references public.job_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, job_post_id)
);

create index if not exists favourites_user_id_idx on public.favourites (user_id);
create index if not exists favourites_job_post_id_idx on public.favourites (job_post_id);

alter table public.favourites enable row level security;

drop policy if exists "Users can view their own favourites" on public.favourites;
create policy "Users can view their own favourites"
  on public.favourites for select
  using (auth.uid() = user_id);

drop policy if exists "Users can add favourites" on public.favourites;
create policy "Users can add favourites"
  on public.favourites for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can remove favourites" on public.favourites;
create policy "Users can remove favourites"
  on public.favourites for delete
  using (auth.uid() = user_id);
