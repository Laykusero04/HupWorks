-- Rollback for 0053 (HOTFIX A). Only if HOTFIX A causes a problem.
-- Removes the new triggers/functions and restores the previous policy.
-- Ratings recalculated by A5 are NOT reverted (they are the correct values);
-- the previous values are recoverable only from a backup / PITR.
-- A1 was warn-only in the migration, so there is nothing to restore for it.
begin;

drop trigger if exists employer_verification_force_pending on public.employer_verifications;
drop trigger if exists seller_identity_force_pending    on public.seller_identity_verifications;
drop function if exists public.verification_force_pending();

drop trigger if exists profiles_protect_columns on public.profiles;
drop function if exists public.profiles_protect_columns();

drop trigger if exists reviews_recalc_rating on public.reviews;
drop function if exists public.reviews_recalc_rating_trg();
drop function if exists public.recalc_profile_rating(uuid);

-- Restore the policy as in the repo (no WITH CHECK). If Part 0 (0c) showed a
-- different name or condition in production, recreate that instead.
drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

commit;
