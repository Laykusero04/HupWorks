-- Ensure signup always creates profiles (+ seller rows), including onboarding flag.
-- Also backfill auth users that somehow have no profiles row.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := lower(coalesce(new.raw_user_meta_data->>'role', 'client'));
  v_name text := coalesce(nullif(trim(new.raw_user_meta_data->>'name'), ''), split_part(new.email, '@', 1));
  v_phone text := nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), '');
begin
  if v_role not in ('client', 'seller') then
    v_role := 'client';
  end if;

  insert into public.profiles (
    id,
    role,
    name,
    email,
    phone,
    seller_onboarding_completed
  )
  values (
    new.id,
    v_role,
    v_name,
    coalesce(new.email, ''),
    v_phone,
    case when v_role = 'seller' then false else true end
  )
  on conflict (id) do nothing;

  if v_role = 'seller' then
    insert into public.seller_profiles (user_id)
    values (new.id)
    on conflict (user_id) do nothing;

    insert into public.seller_private_details (user_id)
    values (new.id)
    on conflict (user_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill missing profiles from auth.users metadata
insert into public.profiles (
  id,
  role,
  name,
  email,
  phone,
  seller_onboarding_completed
)
select
  u.id,
  case
    when lower(coalesce(u.raw_user_meta_data->>'role', 'client')) = 'seller' then 'seller'
    else 'client'
  end,
  coalesce(
    nullif(trim(u.raw_user_meta_data->>'name'), ''),
    split_part(coalesce(u.email, 'user'), '@', 1)
  ),
  coalesce(u.email, ''),
  nullif(trim(coalesce(u.raw_user_meta_data->>'phone', '')), ''),
  case
    when lower(coalesce(u.raw_user_meta_data->>'role', 'client')) = 'seller' then false
    else true
  end
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

insert into public.seller_profiles (user_id)
select p.id
from public.profiles p
where p.role = 'seller'
  and not exists (select 1 from public.seller_profiles sp where sp.user_id = p.id)
on conflict (user_id) do nothing;

insert into public.seller_private_details (user_id)
select p.id
from public.profiles p
where p.role = 'seller'
  and not exists (select 1 from public.seller_private_details spd where spd.user_id = p.id)
on conflict (user_id) do nothing;
