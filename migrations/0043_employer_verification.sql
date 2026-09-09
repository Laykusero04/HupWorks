-- Employer (client) verification — Option E hybrid:
-- 1) Profile completeness gate (app-side) before posting jobs
-- 2) Optional upgrade: personal ID selfie OR company registration doc
-- 3) Reuses profiles.profile_photo_status + profiles.verification_status for clients
-- 4) Admin reviews employers in a separate queue from sellers

alter table public.profiles
  add column if not exists company_name text,
  add column if not exists company_registration_number text,
  add column if not exists company_website text;

comment on column public.profiles.company_name is
  'Optional employer/company display name (clients)';
comment on column public.profiles.company_registration_number is
  'Optional business registration / KvK / CR number';
comment on column public.profiles.company_website is
  'Optional company website URL';

-- Clients who already have a photo but never got a separate review:
-- treat as pending so admin can accept/reject independently (mirrors sellers).
update public.profiles
set profile_photo_status = 'pending'
where coalesce(trim(profile_image_url), '') <> ''
  and coalesce(profile_photo_status, 'unverified') = 'unverified'
  and role = 'client';

create table if not exists public.employer_verifications (
  user_id uuid primary key references auth.users on delete cascade,
  verify_type text not null
    check (verify_type in ('personal_id', 'company')),
  id_selfie_path text,
  company_doc_path text,
  company_name text,
  company_registration_number text,
  company_website text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  rejection_reason text,
  constraint employer_verifications_doc_check check (
    (verify_type = 'personal_id' and coalesce(trim(id_selfie_path), '') <> '')
    or (verify_type = 'company' and coalesce(trim(company_doc_path), '') <> '')
  )
);

create index if not exists employer_verifications_status_idx
  on public.employer_verifications (status);

alter table public.employer_verifications enable row level security;

drop policy if exists "Employers read own verification" on public.employer_verifications;
create policy "Employers read own verification"
  on public.employer_verifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Employers insert own verification" on public.employer_verifications;
create policy "Employers insert own verification"
  on public.employer_verifications for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'client'
    )
  );

drop policy if exists "Employers update own verification" on public.employer_verifications;
create policy "Employers update own verification"
  on public.employer_verifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Keep profiles.verification_status in sync for clients (same columns sellers use).
create or replace function public.sync_employer_verification_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set
    verification_status = new.status,
    verification_reviewed_at = new.reviewed_at,
    verification_rejection_reason = new.rejection_reason,
    company_name = coalesce(nullif(trim(new.company_name), ''), company_name),
    company_registration_number = coalesce(
      nullif(trim(new.company_registration_number), ''),
      company_registration_number
    ),
    company_website = coalesce(nullif(trim(new.company_website), ''), company_website)
  where id = new.user_id
    and role = 'client';
  return new;
end;
$$;

drop trigger if exists trg_sync_employer_verification_status on public.employer_verifications;
create trigger trg_sync_employer_verification_status
  after insert or update of status, reviewed_at, rejection_reason,
    company_name, company_registration_number, company_website
  on public.employer_verifications
  for each row
  execute function public.sync_employer_verification_status();

-- Reuse private identity-docs bucket (created in 0034). Object names:
--   {userId}/id_selfie.jpg     — personal ID path
--   {userId}/company_doc.jpg   — company registration photo
