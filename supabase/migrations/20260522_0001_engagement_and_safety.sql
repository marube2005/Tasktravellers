-- Engagement, safety, and ride-acceptance support
-- Adds chat, SOS alerts, and ride acceptance codes for in-app flows.

alter table public.rides
  add column if not exists acceptance_code text,
  add column if not exists acceptance_code_expires_at timestamptz,
  add column if not exists group_note text,
  add column if not exists creator_id uuid references public.users(id) on delete set null;

create index if not exists idx_rides_acceptance_code on public.rides(acceptance_code);
create index if not exists idx_rides_creator on public.rides(creator_id);

create table if not exists public.ride_messages (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.ride_messages add column if not exists id uuid default gen_random_uuid();
alter table public.ride_messages add column if not exists ride_id uuid;
alter table public.ride_messages add column if not exists sender_id uuid;
alter table public.ride_messages add column if not exists message text;
alter table public.ride_messages add column if not exists created_at timestamptz not null default now();
alter table public.ride_messages add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_ride_messages_ride on public.ride_messages(ride_id);
create index if not exists idx_ride_messages_sender on public.ride_messages(sender_id);

create table if not exists public.emergency_alerts (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides(id) on delete set null,
  user_id uuid not null references public.users(id) on delete cascade,
  emergency_contact_name text,
  emergency_contact_phone text,
  location_label text,
  latitude double precision,
  longitude double precision,
  message text not null,
  status text not null default 'sent',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.emergency_alerts add column if not exists id uuid default gen_random_uuid();
alter table public.emergency_alerts add column if not exists ride_id uuid;
alter table public.emergency_alerts add column if not exists user_id uuid;
alter table public.emergency_alerts add column if not exists emergency_contact_name text;
alter table public.emergency_alerts add column if not exists emergency_contact_phone text;
alter table public.emergency_alerts add column if not exists location_label text;
alter table public.emergency_alerts add column if not exists latitude double precision;
alter table public.emergency_alerts add column if not exists longitude double precision;
alter table public.emergency_alerts add column if not exists message text;
alter table public.emergency_alerts add column if not exists status text not null default 'sent';
alter table public.emergency_alerts add column if not exists created_at timestamptz not null default now();
alter table public.emergency_alerts add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_emergency_alerts_user on public.emergency_alerts(user_id);
create index if not exists idx_emergency_alerts_ride on public.emergency_alerts(ride_id);

do $$
declare
  t text;
begin
  foreach t in array array['rides', 'ride_messages', 'emergency_alerts']
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
