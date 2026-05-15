-- Run only if 0006 was already applied with 'Flexible' in the check constraint.
alter table public.job_posts drop constraint if exists job_posts_location_type_check;
alter table public.job_posts
  add constraint job_posts_location_type_check
  check (location_type in ('On-site', 'Remote'));

update public.job_posts set location_type = 'Remote' where location_type = 'Flexible';
