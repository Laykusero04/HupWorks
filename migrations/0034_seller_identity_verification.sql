-- Seller identity verification (admin review later).
-- Public-safe status on profiles for badges; private selfie storage in identity-docs.

alter table public.profiles
  add column if not exists verification_status text
    default 'unverified',
  add column if not exists verification_reviewed_at timestamptz,
  add column if not exists verification_rejection_reason text;

-- Backfill nulls then constrain
update public.profiles
set verification_status = 'unverified'
where verification_status is null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_verification_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_verification_status_check
      check (verification_status in ('unverified', 'pending', 'verified', 'rejected'));
  end if;
end $$;

create table if not exists public.seller_identity_verifications (
  user_id uuid primary key references auth.users on delete cascade,
  id_selfie_path text not null,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  rejection_reason text
);

alter table public.seller_identity_verifications enable row level security;

drop policy if exists "Sellers read own identity verification" on public.seller_identity_verifications;
create policy "Sellers read own identity verification"
  on public.seller_identity_verifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Sellers insert own identity verification" on public.seller_identity_verifications;
create policy "Sellers insert own identity verification"
  on public.seller_identity_verifications for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Sellers update own identity verification" on public.seller_identity_verifications;
create policy "Sellers update own identity verification"
  on public.seller_identity_verifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Keep profiles.verification_status in sync when seller submits / when admin updates later
create or replace function public.sync_profile_verification_status()
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
    verification_rejection_reason = new.rejection_reason
  where id = new.user_id;
  return new;
end;
$$;

drop trigger if exists trg_sync_profile_verification_status on public.seller_identity_verifications;
create trigger trg_sync_profile_verification_status
  after insert or update of status, reviewed_at, rejection_reason
  on public.seller_identity_verifications
  for each row
  execute function public.sync_profile_verification_status();

-- Private storage bucket for ID+face selfies
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'identity-docs',
  'identity-docs',
  false,
  8388608,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users read own identity docs" on storage.objects;
create policy "Users read own identity docs"
on storage.objects for select
to authenticated
using (
  bucket_id = 'identity-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users upload own identity docs" on storage.objects;
create policy "Users upload own identity docs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'identity-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users update own identity docs" on storage.objects;
create policy "Users update own identity docs"
on storage.objects for update
to authenticated
using (
  bucket_id = 'identity-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'identity-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users delete own identity docs" on storage.objects;
create policy "Users delete own identity docs"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'identity-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);
