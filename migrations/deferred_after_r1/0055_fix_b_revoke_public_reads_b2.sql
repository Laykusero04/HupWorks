-- ============================================================================
-- Migration 0055 — FIX B, step B2 (T-0128). BREAKING FOR OLD APP VERSIONS.
--
-- !!  APPLY ONLY AFTER app R1 IS RELEASED (TestFlight + store) AND ENOUGH
-- !!  USERS HAVE UPDATED.  Requires 0053 and 0054 to be applied first.
-- !!  Not in migrations/ on purpose: db_tests/run.sh must not apply it.
--
-- Effect: other users (and anon) can no longer read private columns of
-- profiles / seller_profiles through the API. EVERY app build released before
-- R1 (build 5 and earlier) reads its own profile with select * on profiles and
-- will then fail with "permission denied for table/column" on own-profile,
-- home, chat list, edit-profile and public-profile screens.
-- Those old builds contain NO version gate, so they get NO "please update"
-- message, they simply break. Only R1 and later builds can show the update
-- screen (0057). Therefore apply 0055 only when you accept that, i.e. after
-- high R1 adoption, or as a deliberate forced cut-over (owner decision).
--
-- Rollback (instant): migrations/rollback/0055_fix_b_revoke_public_reads_b2_down.sql
-- ============================================================================

begin;

revoke select on public.profiles from anon, authenticated;
grant select (
  id, role, name, profile_image_url, bio, rating, created_at,
  country, city, gender,
  verification_status, profile_photo_status,
  company_name, company_website,
  chat_contact_policy
) on public.profiles to anon, authenticated;

revoke select on public.seller_profiles from anon, authenticated;
grant select (
  user_id, job_title, about, skills, languages, education, experience, show_age
) on public.seller_profiles to anon, authenticated;

-- Not public any more (own row is read through my_profile / my_seller_profile):
--   profiles: charity_cause (own row via my_profile), email, phone, balance, latitude, longitude, seller_onboarding_completed,
--     verification_reviewed_at, verification_rejection_reason,
--     profile_photo_reviewed_at, profile_photo_rejection_reason,
--     company_registration_number
--   seller_profiles: id, address, birth_year, birth_month, birth_day,
--     impressions_count, interactions_count, reach_count, created_at
-- The old seller_profiles.address / birth_* columns still exist until 0056.

commit;
