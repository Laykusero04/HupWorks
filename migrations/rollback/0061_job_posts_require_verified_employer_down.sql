-- Rollback for 0061. Restores the original INSERT policy (any client may post)
-- and drops the first_verified_at marker + trigger (the stamp is lost).
begin;

drop policy if exists "Clients can create job posts" on public.job_posts;
create policy "Clients can create job posts"
  on public.job_posts
  for insert
  with check (auth.uid() = client_id);

drop trigger if exists employer_verification_stamp_first_verified
  on public.employer_verifications;
drop function if exists public.employer_verification_stamp_first_verified();
alter table public.employer_verifications drop column if exists first_verified_at;

commit;
