-- Profile avatars: public bucket + authenticated own-folder policies.
-- Run in Supabase SQL Editor after deleting the wizard "anon JPG folder" policies
-- (or the DROP statements below remove those known template names).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Remove Supabase wizard template policies if present
drop policy if exists "Give anon users access to JPG images in folder 1oj01fe_0" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1oj01fe_1" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1oj01fe_2" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1oj01fe_3" on storage.objects;

drop policy if exists "Public read avatars" on storage.objects;
drop policy if exists "Users upload own avatar" on storage.objects;
drop policy if exists "Users update own avatar" on storage.objects;
drop policy if exists "Users delete own avatar" on storage.objects;

-- Anyone can view (bucket is public; getPublicUrl used by the app)
create policy "Public read avatars"
on storage.objects for select
using (bucket_id = 'avatars');

-- Logged-in users may write only under {auth.uid()}/...
create policy "Users upload own avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users update own avatar"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users delete own avatar"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
