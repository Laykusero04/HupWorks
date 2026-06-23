-- ============================================
-- Migration 0016 — Freelancer profile fields
-- Skills (jsonb tiers), job title, private age/address
-- ============================================

-- 1. Add job_title and skills_jsonb to seller_profiles
alter table public.seller_profiles
  add column if not exists job_title text,
  add column if not exists skills_jsonb jsonb not null default '[]'::jsonb;

-- 2. Migrate legacy skills text[] into skills_jsonb (best-effort)
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'seller_profiles'
      and column_name = 'skills'
      and udt_name = '_text'
  ) then
    update public.seller_profiles sp
    set skills_jsonb = coalesce(
      (
        select jsonb_agg(jsonb_build_object('name', s, 'stars', 5))
        from unnest(sp.skills) as s
        where s is not null and trim(s) <> ''
      ),
      '[]'::jsonb
    )
    where skills_jsonb = '[]'::jsonb
      and coalesce(array_length(sp.skills, 1), 0) > 0;

    alter table public.seller_profiles drop column if exists skills;
  end if;
end $$;

-- Drop legacy single skill_level if present
alter table public.seller_profiles drop column if exists skill_level;

-- Rename skills_jsonb -> skills for cleaner API (only if skills column absent)
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'seller_profiles'
      and column_name = 'skills_jsonb'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'seller_profiles'
      and column_name = 'skills'
  ) then
    alter table public.seller_profiles rename column skills_jsonb to skills;
  end if;
end $$;

-- 3. Private seller details (age/address — owner-only)
create table if not exists public.seller_private_details (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  date_of_birth date,
  street_address text,
  state text,
  postal_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.seller_private_details enable row level security;

drop policy if exists "Sellers can view own private details" on public.seller_private_details;
create policy "Sellers can view own private details"
  on public.seller_private_details for select
  using (auth.uid() = user_id);

drop policy if exists "Sellers can insert own private details" on public.seller_private_details;
create policy "Sellers can insert own private details"
  on public.seller_private_details for insert
  with check (auth.uid() = user_id);

drop policy if exists "Sellers can update own private details" on public.seller_private_details;
create policy "Sellers can update own private details"
  on public.seller_private_details for update
  using (auth.uid() = user_id);
