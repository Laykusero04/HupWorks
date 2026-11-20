-- Rollback for 0060. DESTROYS all rows in user_private_details (legal name, DOB,
-- address, consent proof). Take a backup first if any real data was collected.
-- Restores delete_own_account() to its 0044 definition and seller_public_age to
-- its 0054 definition (age from seller_private_details only).
begin;

-- The view must stop reading user_private_details before the table is dropped.
create or replace view public.seller_public_age
  with (security_barrier = true) as
  select
    sp.user_id,
    case
      when sp.show_age and pd.date_of_birth is not null
        then date_part('year', age(pd.date_of_birth))::int
    end as age_years
  from public.seller_profiles sp
  left join public.seller_private_details pd on pd.user_id = sp.user_id;

revoke all on public.seller_public_age from public, anon, authenticated;
grant select on public.seller_public_age to anon, authenticated;

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  perform public.prepare_account_deletion(uid);

  -- Cascades most marketplace rows (seller_profiles, chat, jobs, etc.).
  delete from public.profiles where id = uid;

  -- Remove Auth identity (also cascades verification tables → auth.users).
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
grant execute on function public.delete_own_account() to service_role;

drop table if exists public.user_private_details;
drop function if exists public.trg_user_private_details_updated_at();

commit;
