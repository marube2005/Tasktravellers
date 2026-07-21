-- Travelers App schema bootstrap / patch migration
-- Safe to run multiple times (idempotent where possible).

create extension if not exists pgcrypto;

-- Keep updated_at fresh on writes.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================
-- users
-- =====================================================
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  phone text,
  role text default 'passenger',
  is_verified boolean default false,
  home_area text,
  preferred_routes text,
  emergency_contact_name text,
  emergency_contact_phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.users add column if not exists name text;
alter table public.users add column if not exists email text;
alter table public.users add column if not exists phone text;
alter table public.users add column if not exists role text default 'passenger';
alter table public.users add column if not exists is_verified boolean default false;
alter table public.users add column if not exists home_area text;
alter table public.users add column if not exists preferred_routes text;
alter table public.users add column if not exists emergency_contact_name text;
alter table public.users add column if not exists emergency_contact_phone text;
alter table public.users add column if not exists avatar_url text;
alter table public.users add column if not exists created_at timestamptz not null default now();
alter table public.users add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_users_role on public.users(role);

-- =====================================================
-- sacco_profiles
-- =====================================================
create table if not exists public.sacco_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  sacco_name text not null,
  ntsa_license text,
  fleet_size integer default 0,
  contact_name text,
  contact_phone text,
  contact_email text,
  logo_url text,
  verification_status text not null default 'pending',
  rejection_reason text,
  ntsa_cert_url text,
  sacco_reg_url text,
  kra_pin_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_sacco_profiles_user unique(user_id)
);

alter table public.sacco_profiles add column if not exists id uuid default gen_random_uuid();
alter table public.sacco_profiles add column if not exists user_id uuid;
alter table public.sacco_profiles add column if not exists sacco_name text;
alter table public.sacco_profiles add column if not exists ntsa_license text;
alter table public.sacco_profiles add column if not exists fleet_size integer default 0;
alter table public.sacco_profiles add column if not exists contact_name text;
alter table public.sacco_profiles add column if not exists contact_phone text;
alter table public.sacco_profiles add column if not exists contact_email text;
alter table public.sacco_profiles add column if not exists logo_url text;
alter table public.sacco_profiles add column if not exists verification_status text default 'pending';
alter table public.sacco_profiles add column if not exists rejection_reason text;
alter table public.sacco_profiles add column if not exists ntsa_cert_url text;
alter table public.sacco_profiles add column if not exists sacco_reg_url text;
alter table public.sacco_profiles add column if not exists kra_pin_url text;
alter table public.sacco_profiles add column if not exists created_at timestamptz not null default now();
alter table public.sacco_profiles add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'uq_sacco_profiles_user'
  ) then
    alter table public.sacco_profiles add constraint uq_sacco_profiles_user unique(user_id);
  end if;
end $$;

create index if not exists idx_sacco_profiles_status on public.sacco_profiles(verification_status);

-- =====================================================
-- vehicles
-- =====================================================
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  sacco_id uuid not null references public.users(id) on delete cascade,
  plate_number text not null unique,
  capacity integer not null,
  route text,
  is_available boolean not null default true,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.vehicles add column if not exists id uuid default gen_random_uuid();
alter table public.vehicles add column if not exists sacco_id uuid;
alter table public.vehicles add column if not exists plate_number text;
alter table public.vehicles add column if not exists capacity integer;
alter table public.vehicles add column if not exists route text;
alter table public.vehicles add column if not exists is_available boolean not null default true;
alter table public.vehicles add column if not exists image_url text;
alter table public.vehicles add column if not exists created_at timestamptz not null default now();
alter table public.vehicles add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_vehicles_sacco on public.vehicles(sacco_id);
create index if not exists idx_vehicles_available on public.vehicles(is_available);

-- =====================================================
-- rides
-- =====================================================
create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),
  origin text not null,
  destination text not null,
  group_size integer not null default 1,
  estimated_fare numeric,
  invite_link text,
  status text not null default 'open',
  provider_id uuid references public.users(id) on delete set null,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  current_lat double precision,
  current_lng double precision,
  location_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.rides add column if not exists id uuid default gen_random_uuid();
alter table public.rides add column if not exists origin text;
alter table public.rides add column if not exists destination text;
alter table public.rides add column if not exists group_size integer not null default 1;
alter table public.rides add column if not exists estimated_fare numeric;
alter table public.rides add column if not exists invite_link text;
alter table public.rides add column if not exists status text not null default 'open';
alter table public.rides add column if not exists provider_id uuid;
alter table public.rides add column if not exists vehicle_id uuid;
alter table public.rides add column if not exists current_lat double precision;
alter table public.rides add column if not exists current_lng double precision;
alter table public.rides add column if not exists location_updated_at timestamptz;
alter table public.rides add column if not exists created_at timestamptz not null default now();
alter table public.rides add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_rides_status on public.rides(status);
create index if not exists idx_rides_provider on public.rides(provider_id);

-- =====================================================
-- bookings
-- =====================================================
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  passenger_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_bookings_ride_passenger unique(ride_id, passenger_id)
);

alter table public.bookings add column if not exists id uuid default gen_random_uuid();
alter table public.bookings add column if not exists ride_id uuid;
alter table public.bookings add column if not exists passenger_id uuid;
alter table public.bookings add column if not exists joined_at timestamptz not null default now();
alter table public.bookings add column if not exists created_at timestamptz not null default now();
alter table public.bookings add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'uq_bookings_ride_passenger'
  ) then
    alter table public.bookings add constraint uq_bookings_ride_passenger unique(ride_id, passenger_id);
  end if;
end $$;

create index if not exists idx_bookings_ride on public.bookings(ride_id);
create index if not exists idx_bookings_passenger on public.bookings(passenger_id);

-- =====================================================
-- transactions
-- =====================================================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  payer_id uuid not null references public.users(id) on delete cascade,
  amount numeric not null,
  commission numeric not null default 0,
  status text not null default 'pending',
  payhero_tx_id text,
  external_reference text,
  payhero_reference text,
  checkout_request_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.transactions add column if not exists id uuid default gen_random_uuid();
alter table public.transactions add column if not exists ride_id uuid;
alter table public.transactions add column if not exists payer_id uuid;
alter table public.transactions add column if not exists amount numeric;
alter table public.transactions add column if not exists commission numeric not null default 0;
alter table public.transactions add column if not exists status text not null default 'pending';
alter table public.transactions add column if not exists payhero_tx_id text;
alter table public.transactions add column if not exists external_reference text;
alter table public.transactions add column if not exists payhero_reference text;
alter table public.transactions add column if not exists checkout_request_id text;
alter table public.transactions add column if not exists created_at timestamptz not null default now();
alter table public.transactions add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_transactions_payer on public.transactions(payer_id);
create index if not exists idx_transactions_status on public.transactions(status);
create unique index if not exists uq_transactions_external_reference on public.transactions(external_reference);

-- =====================================================
-- vehicle_locations
-- =====================================================
create table if not exists public.vehicle_locations (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  heading double precision,
  speed double precision,
  updated_at timestamptz not null default now()
);

alter table public.vehicle_locations add column if not exists id uuid default gen_random_uuid();
alter table public.vehicle_locations add column if not exists vehicle_id uuid;
alter table public.vehicle_locations add column if not exists latitude double precision;
alter table public.vehicle_locations add column if not exists longitude double precision;
alter table public.vehicle_locations add column if not exists heading double precision;
alter table public.vehicle_locations add column if not exists speed double precision;
alter table public.vehicle_locations add column if not exists updated_at timestamptz not null default now();

create unique index if not exists uq_vehicle_locations_vehicle on public.vehicle_locations(vehicle_id);

-- =====================================================
-- Triggers
-- =====================================================

do $$
declare
  t text;
begin
  foreach t in array array['users','sacco_profiles','vehicles','rides','bookings','transactions']
  loop
    if not exists (
      select 1
      from pg_trigger
      where tgname = 'trg_' || t || '_set_updated_at'
    ) then
      execute format(
        'create trigger trg_%I_set_updated_at before update on public.%I for each row execute function public.set_updated_at()',
        t, t
      );
    end if;
  end loop;
end $$;

-- =====================================================
-- Storage buckets (create if absent)
-- =====================================================
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('vehicle-images', 'vehicle-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('sacco-documents', 'sacco-documents', true)
on conflict (id) do nothing;

-- Allow authenticated users to upload/update/delete their own assets in the
-- app-managed folder layout:
--   profile-photos/<uid>/...
--   vehicle-images/<uid>/...
--   sacco-documents/<uid>/...
-- NOTE: sacco-documents is still public here because the current app reads
-- public URLs directly. If you want private verification docs, switch the
-- bucket to private and migrate the app to signed URLs.

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated uploads to profile-photos'
  ) then
    create policy "Allow authenticated uploads to profile-photos"
    on storage.objects
    for insert
    to authenticated
    with check (
      bucket_id = 'profile-photos'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated updates to profile-photos'
  ) then
    create policy "Allow authenticated updates to profile-photos"
    on storage.objects
    for update
    to authenticated
    using (
      bucket_id = 'profile-photos'
      and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
      bucket_id = 'profile-photos'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated deletes from profile-photos'
  ) then
    create policy "Allow authenticated deletes from profile-photos"
    on storage.objects
    for delete
    to authenticated
    using (
      bucket_id = 'profile-photos'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated uploads to vehicle-images'
  ) then
    create policy "Allow authenticated uploads to vehicle-images"
    on storage.objects
    for insert
    to authenticated
    with check (
      bucket_id = 'vehicle-images'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated updates to vehicle-images'
  ) then
    create policy "Allow authenticated updates to vehicle-images"
    on storage.objects
    for update
    to authenticated
    using (
      bucket_id = 'vehicle-images'
      and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
      bucket_id = 'vehicle-images'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated deletes from vehicle-images'
  ) then
    create policy "Allow authenticated deletes from vehicle-images"
    on storage.objects
    for delete
    to authenticated
    using (
      bucket_id = 'vehicle-images'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated uploads to sacco-documents'
  ) then
    create policy "Allow authenticated uploads to sacco-documents"
    on storage.objects
    for insert
    to authenticated
    with check (
      bucket_id = 'sacco-documents'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated updates to sacco-documents'
  ) then
    create policy "Allow authenticated updates to sacco-documents"
    on storage.objects
    for update
    to authenticated
    using (
      bucket_id = 'sacco-documents'
      and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
      bucket_id = 'sacco-documents'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow authenticated deletes from sacco-documents'
  ) then
    create policy "Allow authenticated deletes from sacco-documents"
    on storage.objects
    for delete
    to authenticated
    using (
      bucket_id = 'sacco-documents'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;
end $$;
