-- Migration 0046 — Logistics, Gardening, Sailing categories (with photo icon keys).
-- App maps icon keys to images/categories/<icon>.png.

insert into public.categories (name, icon, description, name_i18n, description_i18n)
select
  'Logistics',
  'logistics',
  'Warehouse logistics, stock handlers, loaders, route helpers',
  jsonb_build_object(
    'en', 'Logistics',
    'nl', 'Logistiek',
    'bn', 'লজিস্টিক্স'
  ),
  jsonb_build_object(
    'en', 'Warehouse logistics, stock handlers, loaders, route helpers',
    'nl', 'Magazijnlogistiek, voorraadmedewerkers, laders, routehelpers',
    'bn', 'গুদাম লজিস্টিক্স, স্টক হ্যান্ডলার, লোডার, রুট সহায়ক'
  )
where not exists (
  select 1 from public.categories where lower(trim(name)) = lower('Logistics')
);

insert into public.categories (name, icon, description, name_i18n, description_i18n)
select
  'Gardening',
  'gardening',
  'Gardeners, landscapers, groundskeepers, plant care',
  jsonb_build_object(
    'en', 'Gardening',
    'nl', 'Tuinieren',
    'bn', 'বাগান'
  ),
  jsonb_build_object(
    'en', 'Gardeners, landscapers, groundskeepers, plant care',
    'nl', 'Tuinmannen, hoveniers, terreinknechten, plantenverzorging',
    'bn', 'মালি, ল্যান্ডস্কেপার, মাঠরক্ষক, গাছের যত্ন'
  )
where not exists (
  select 1 from public.categories where lower(trim(name)) = lower('Gardening')
);

insert into public.categories (name, icon, description, name_i18n, description_i18n)
select
  'Sailing',
  'sailing',
  'Deckhands, marina helpers, boat maintenance, sailing support',
  jsonb_build_object(
    'en', 'Sailing',
    'nl', 'Zeilen',
    'bn', 'নৌকা চালনা'
  ),
  jsonb_build_object(
    'en', 'Deckhands, marina helpers, boat maintenance, sailing support',
    'nl', 'Matrozen, jachthavenhelpers, bootonderhoud, zeilondersteuning',
    'bn', 'ডেকহ্যান্ড, মেরিনা সহায়ক, নৌকা রক্ষণাবেক্ষণ, পালতোলা সহায়তা'
  )
where not exists (
  select 1 from public.categories where lower(trim(name)) = lower('Sailing')
);

-- Optional skills for the new categories (idempotent via unique name index + helper if present).
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = '_seed_skill'
  ) then
    perform public._seed_skill('Warehouse picker', 'Logistics', 10);
    perform public._seed_skill('Forklift helper', 'Logistics', 20);
    perform public._seed_skill('Stock loader', 'Logistics', 30);
    perform public._seed_skill('Gardener', 'Gardening', 10);
    perform public._seed_skill('Hedge trimmer', 'Gardening', 20);
    perform public._seed_skill('Lawn care', 'Gardening', 30);
    perform public._seed_skill('Deckhand', 'Sailing', 10);
    perform public._seed_skill('Marina helper', 'Sailing', 20);
    perform public._seed_skill('Boat cleaner', 'Sailing', 30);
  end if;
end $$;
