-- Split profile-photo review from face+ID identity verification.
-- identity: profiles.verification_status + seller_identity_verifications (existing)
-- profile photo: profiles.profile_photo_status (new)

alter table public.profiles
  add column if not exists profile_photo_status text default 'unverified',
  add column if not exists profile_photo_reviewed_at timestamptz,
  add column if not exists profile_photo_rejection_reason text;

update public.profiles
set profile_photo_status = 'unverified'
where profile_photo_status is null;

-- Sellers who already have a photo but never got a separate review:
-- treat as pending so admin can accept/reject profile photo independently.
update public.profiles
set profile_photo_status = 'pending'
where coalesce(trim(profile_image_url), '') <> ''
  and profile_photo_status = 'unverified'
  and role = 'seller';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_profile_photo_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_profile_photo_status_check
      check (profile_photo_status in ('unverified', 'pending', 'verified', 'rejected'));
  end if;
end $$;

comment on column public.profiles.profile_photo_status is
  'Admin review of seller profile photo: unverified|pending|verified|rejected';
comment on column public.profiles.verification_status is
  'Admin review of face+ID selfie (synced from seller_identity_verifications)';
