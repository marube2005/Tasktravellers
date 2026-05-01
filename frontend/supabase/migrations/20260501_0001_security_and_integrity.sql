-- Security and integrity patch
-- Addresses: private sacco-documents bucket, RLS policies, role/status constraints,
-- creator_id on rides, vehicles FK fix, capacity-check trigger,
-- server-side commission trigger, missing MVP tables, and transaction-update lockdown.
-- Safe to run multiple times (idempotent where possible).

-- =====================================================
-- 1. Make sacco-documents bucket PRIVATE
-- =====================================================

update storage.buckets
  set public = false
  where id = 'sacco-documents';

-- Remove the old catch-all public SELECT policy for sacco-documents if it exists.
do $$
begin
  -- Drop any pre-existing permissive select policies on the bucket so that only
  -- the new restricted policies below apply.
  if exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename  = 'objects'
      and policyname = 'Public read access for sacco-documents'
  ) then
    drop policy "Public read access for sacco-documents" on storage.objects;
  end if;
end $$;

-- Owners can read their own sacco documents (for resubmission / self-review).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename  = 'objects'
      and policyname = 'Owners can read their own sacco documents'
  ) then
    create policy "Owners can read their own sacco documents"
    on storage.objects
    for select
    to authenticated
    using (
      bucket_id = 'sacco-documents'
      and (storage.foldername(name))[1] = auth.uid()::text
    );
  end if;
end $$;

-- Admins can read ALL sacco documents (for verification review).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename  = 'objects'
      and policyname = 'Admins can read all sacco documents'
  ) then
    create policy "Admins can read all sacco documents"
    on storage.objects
    for select
    to authenticated
    using (
      bucket_id = 'sacco-documents'
      and exists (
        select 1 from public.users
        where id   = auth.uid()
          and role = 'admin'
      )
    );
  end if;
end $$;

-- =====================================================
-- 2. Role constraint on users (prevent arbitrary roles)
-- =====================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_users_role'
  ) then
    alter table public.users
      add constraint chk_users_role
      check (role in ('passenger', 'sacco', 'admin'));
  end if;
end $$;

-- =====================================================
-- 3. Status constraints on rides and transactions
-- =====================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_rides_status'
  ) then
    alter table public.rides
      add constraint chk_rides_status
      check (status in ('open', 'accepted', 'in_progress', 'completed', 'cancelled'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_transactions_status'
  ) then
    alter table public.transactions
      add constraint chk_transactions_status
      check (status in ('pending', 'completed', 'failed'));
  end if;
end $$;

-- =====================================================
-- 4. Add creator_id to rides
-- =====================================================

alter table public.rides
  add column if not exists creator_id uuid references public.users(id) on delete set null;

create index if not exists idx_rides_creator on public.rides(creator_id);

-- =====================================================
-- 5. Fix vehicles.sacco_id FK
--    Old: references public.users(id)
--    New: references public.sacco_profiles(user_id)
--    This ensures only registered sacco operators can own vehicles.
-- =====================================================

do $$
begin
  -- Drop old FK if it pointed at users
  if exists (
    select 1 from pg_constraint
    where conname = 'vehicles_sacco_id_fkey'
  ) then
    alter table public.vehicles drop constraint vehicles_sacco_id_fkey;
  end if;

  -- Add new FK pointing at sacco_profiles(user_id)
  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_sacco_id_sacco_profiles_fkey'
  ) then
    alter table public.vehicles
      add constraint vehicles_sacco_id_sacco_profiles_fkey
      foreign key (sacco_id)
      references public.sacco_profiles(user_id)
      on delete cascade;
  end if;
end $$;

-- =====================================================
-- 6. Booking capacity-check trigger
-- =====================================================

create or replace function public.check_booking_capacity()
returns trigger
language plpgsql
as $$
declare
  v_group_size     integer;
  v_current_count  integer;
begin
  select group_size into v_group_size
    from public.rides
    where id = new.ride_id;

  select count(*) into v_current_count
    from public.bookings
    where ride_id = new.ride_id;

  if v_current_count >= v_group_size then
    raise exception 'Ride is full. Maximum capacity of % passengers reached.', v_group_size
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'trg_bookings_capacity_check'
  ) then
    create trigger trg_bookings_capacity_check
      before insert on public.bookings
      for each row execute function public.check_booking_capacity();
  end if;
end $$;

-- =====================================================
-- 7. Server-side commission calculation trigger
--    The trigger overwrites any client-supplied commission
--    value, enforcing the 5 % rate server-side.
-- =====================================================

create or replace function public.calculate_commission()
returns trigger
language plpgsql
as $$
begin
  new.commission = round((new.amount * 0.05)::numeric, 2);
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'trg_transactions_commission'
  ) then
    create trigger trg_transactions_commission
      before insert or update of amount on public.transactions
      for each row execute function public.calculate_commission();
  end if;
end $$;

-- =====================================================
-- 8. Missing MVP tables
-- =====================================================

-- 8a. chat_messages
create table if not exists public.chat_messages (
  id         uuid        primary key default gen_random_uuid(),
  ride_id    uuid        not null references public.rides(id) on delete cascade,
  sender_id  uuid        not null references public.users(id) on delete cascade,
  content    text        not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_ride on public.chat_messages(ride_id);
create index if not exists idx_chat_messages_sender on public.chat_messages(sender_id);

-- 8b. ratings_reviews
create table if not exists public.ratings_reviews (
  id           uuid        primary key default gen_random_uuid(),
  ride_id      uuid        not null references public.rides(id) on delete cascade,
  reviewer_id  uuid        not null references public.users(id) on delete cascade,
  reviewee_id  uuid        not null references public.users(id) on delete cascade,
  rating       integer     not null check (rating between 1 and 5),
  comment      text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint uq_ratings_ride_reviewer unique (ride_id, reviewer_id)
);

create index if not exists idx_ratings_ride     on public.ratings_reviews(ride_id);
create index if not exists idx_ratings_reviewee on public.ratings_reviews(reviewee_id);

-- 8c. dispute_reports
create table if not exists public.dispute_reports (
  id               uuid        primary key default gen_random_uuid(),
  ride_id          uuid        not null references public.rides(id) on delete cascade,
  reporter_id      uuid        not null references public.users(id) on delete cascade,
  reason           text        not null,
  status           text        not null default 'open'
                               check (status in ('open', 'under_review', 'resolved', 'dismissed')),
  resolution_notes text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_disputes_ride     on public.dispute_reports(ride_id);
create index if not exists idx_disputes_reporter on public.dispute_reports(reporter_id);
create index if not exists idx_disputes_status   on public.dispute_reports(status);

-- 8d. ride_otps  (OTP confirmation for ride acceptance)
create table if not exists public.ride_otps (
  id         uuid        primary key default gen_random_uuid(),
  ride_id    uuid        not null references public.rides(id) on delete cascade,
  otp_code   text        not null,
  is_used    boolean     not null default false,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint uq_ride_otps_ride unique (ride_id)
);

create index if not exists idx_ride_otps_ride on public.ride_otps(ride_id);

-- 8e. updated_at triggers for new tables
do $$
declare
  t text;
begin
  foreach t in array array['ratings_reviews','dispute_reports']
  loop
    if not exists (
      select 1 from pg_trigger
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
-- 9. Enable Row-Level Security on all core tables
-- =====================================================

alter table public.users            enable row level security;
alter table public.sacco_profiles   enable row level security;
alter table public.vehicles         enable row level security;
alter table public.rides            enable row level security;
alter table public.bookings         enable row level security;
alter table public.transactions     enable row level security;
alter table public.vehicle_locations enable row level security;
alter table public.chat_messages    enable row level security;
alter table public.ratings_reviews  enable row level security;
alter table public.dispute_reports  enable row level security;
alter table public.ride_otps        enable row level security;

-- =====================================================
-- 10. RLS policies
-- =====================================================

-- Helper: check whether the current user is an admin
-- (inline in each policy to avoid a separate function dependency)

-- ─── users ────────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='users' and policyname='Users: read any profile') then
    create policy "Users: read any profile"
      on public.users for select to authenticated
      using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='users' and policyname='Users: update own profile') then
    create policy "Users: update own profile"
      on public.users for update to authenticated
      using (id = auth.uid())
      with check (id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='users' and policyname='Users: insert own row') then
    create policy "Users: insert own row"
      on public.users for insert to authenticated
      with check (id = auth.uid());
  end if;
end $$;

-- ─── sacco_profiles ──────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='sacco_profiles' and policyname='Sacco profiles: read all') then
    create policy "Sacco profiles: read all"
      on public.sacco_profiles for select to authenticated
      using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='sacco_profiles' and policyname='Sacco profiles: insert own') then
    create policy "Sacco profiles: insert own"
      on public.sacco_profiles for insert to authenticated
      with check (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='sacco_profiles' and policyname='Sacco profiles: update own') then
    create policy "Sacco profiles: update own"
      on public.sacco_profiles for update to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;

  -- Admins can update verification_status
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='sacco_profiles' and policyname='Admins: update any sacco profile') then
    create policy "Admins: update any sacco profile"
      on public.sacco_profiles for update to authenticated
      using (exists (select 1 from public.users where id = auth.uid() and role = 'admin'));
  end if;
end $$;

-- ─── vehicles ────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicles' and policyname='Vehicles: read available') then
    create policy "Vehicles: read available"
      on public.vehicles for select to authenticated
      using (is_available = true or sacco_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicles' and policyname='Vehicles: sacco insert own') then
    create policy "Vehicles: sacco insert own"
      on public.vehicles for insert to authenticated
      with check (sacco_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicles' and policyname='Vehicles: sacco update own') then
    create policy "Vehicles: sacco update own"
      on public.vehicles for update to authenticated
      using  (sacco_id = auth.uid())
      with check (sacco_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicles' and policyname='Vehicles: sacco delete own') then
    create policy "Vehicles: sacco delete own"
      on public.vehicles for delete to authenticated
      using (sacco_id = auth.uid());
  end if;
end $$;

-- ─── rides ───────────────────────────────────────────────────────────────────
do $$
begin
  -- Any authenticated user can read open rides (for discovery)
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='rides' and policyname='Rides: read open or own') then
    create policy "Rides: read open or own"
      on public.rides for select to authenticated
      using (
        status = 'open'
        or creator_id    = auth.uid()
        or provider_id   = auth.uid()
        or exists (select 1 from public.bookings where ride_id = rides.id and passenger_id = auth.uid())
      );
  end if;

  -- Only passengers can create rides
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='rides' and policyname='Rides: passenger insert') then
    create policy "Rides: passenger insert"
      on public.rides for insert to authenticated
      with check (
        creator_id = auth.uid()
        and exists (select 1 from public.users where id = auth.uid() and role = 'passenger')
      );
  end if;

  -- Saccos can update rides they have been assigned to (accepting, progressing, completing)
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='rides' and policyname='Rides: sacco update assigned') then
    create policy "Rides: sacco update assigned"
      on public.rides for update to authenticated
      using (provider_id = auth.uid() or (status = 'open' and exists (select 1 from public.users where id = auth.uid() and role = 'sacco')))
      with check (true);
  end if;

  -- Creators can cancel their own open ride
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='rides' and policyname='Rides: creator cancel') then
    create policy "Rides: creator cancel"
      on public.rides for update to authenticated
      using  (creator_id = auth.uid() and status = 'open')
      with check (status = 'cancelled');
  end if;
end $$;

-- ─── bookings ────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='bookings' and policyname='Bookings: read own or sacco') then
    create policy "Bookings: read own or sacco"
      on public.bookings for select to authenticated
      using (
        passenger_id = auth.uid()
        or exists (
          select 1 from public.rides
          where rides.id = bookings.ride_id
            and rides.provider_id = auth.uid()
        )
      );
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='bookings' and policyname='Bookings: passenger insert') then
    create policy "Bookings: passenger insert"
      on public.bookings for insert to authenticated
      with check (passenger_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='bookings' and policyname='Bookings: passenger delete own') then
    create policy "Bookings: passenger delete own"
      on public.bookings for delete to authenticated
      using (passenger_id = auth.uid());
  end if;
end $$;

-- ─── transactions ────────────────────────────────────────────────────────────
do $$
begin
  -- Passengers read their own; saccos read transactions linked to their rides
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='transactions' and policyname='Transactions: read own or sacco') then
    create policy "Transactions: read own or sacco"
      on public.transactions for select to authenticated
      using (
        payer_id = auth.uid()
        or exists (
          select 1 from public.rides
          where rides.id = transactions.ride_id
            and rides.provider_id = auth.uid()
        )
      );
  end if;

  -- Passengers can insert their own transactions
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='transactions' and policyname='Transactions: passenger insert') then
    create policy "Transactions: passenger insert"
      on public.transactions for insert to authenticated
      with check (payer_id = auth.uid());
  end if;

  -- NO direct UPDATE or DELETE by regular users.
  -- Transaction status must only be updated by the backend webhook (service role).
  -- Admins may update for dispute resolution.
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='transactions' and policyname='Transactions: admin update only') then
    create policy "Transactions: admin update only"
      on public.transactions for update to authenticated
      using (exists (select 1 from public.users where id = auth.uid() and role = 'admin'));
  end if;
end $$;

-- ─── vehicle_locations ───────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicle_locations' and policyname='Vehicle locations: authenticated read') then
    create policy "Vehicle locations: authenticated read"
      on public.vehicle_locations for select to authenticated
      using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicle_locations' and policyname='Vehicle locations: sacco upsert own') then
    create policy "Vehicle locations: sacco upsert own"
      on public.vehicle_locations for insert to authenticated
      with check (
        exists (
          select 1 from public.vehicles
          where vehicles.id = vehicle_locations.vehicle_id
            and vehicles.sacco_id = auth.uid()
        )
      );
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='vehicle_locations' and policyname='Vehicle locations: sacco update own') then
    create policy "Vehicle locations: sacco update own"
      on public.vehicle_locations for update to authenticated
      using (
        exists (
          select 1 from public.vehicles
          where vehicles.id = vehicle_locations.vehicle_id
            and vehicles.sacco_id = auth.uid()
        )
      );
  end if;
end $$;

-- ─── chat_messages ───────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='chat_messages' and policyname='Chat: read participants') then
    create policy "Chat: read participants"
      on public.chat_messages for select to authenticated
      using (
        exists (
          select 1 from public.bookings
          where bookings.ride_id = chat_messages.ride_id
            and bookings.passenger_id = auth.uid()
        )
        or exists (
          select 1 from public.rides
          where rides.id = chat_messages.ride_id
            and rides.provider_id = auth.uid()
        )
      );
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='chat_messages' and policyname='Chat: send as participant') then
    create policy "Chat: send as participant"
      on public.chat_messages for insert to authenticated
      with check (
        sender_id = auth.uid()
        and (
          exists (
            select 1 from public.bookings
            where bookings.ride_id = chat_messages.ride_id
              and bookings.passenger_id = auth.uid()
          )
          or exists (
            select 1 from public.rides
            where rides.id = chat_messages.ride_id
              and rides.provider_id = auth.uid()
          )
        )
      );
  end if;
end $$;

-- ─── ratings_reviews ─────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='ratings_reviews' and policyname='Ratings: authenticated read') then
    create policy "Ratings: authenticated read"
      on public.ratings_reviews for select to authenticated
      using (true);
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='ratings_reviews' and policyname='Ratings: insert own review') then
    create policy "Ratings: insert own review"
      on public.ratings_reviews for insert to authenticated
      with check (reviewer_id = auth.uid());
  end if;
end $$;

-- ─── dispute_reports ─────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='dispute_reports' and policyname='Disputes: read own or admin') then
    create policy "Disputes: read own or admin"
      on public.dispute_reports for select to authenticated
      using (
        reporter_id = auth.uid()
        or exists (select 1 from public.users where id = auth.uid() and role = 'admin')
      );
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='dispute_reports' and policyname='Disputes: reporter insert') then
    create policy "Disputes: reporter insert"
      on public.dispute_reports for insert to authenticated
      with check (reporter_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='dispute_reports' and policyname='Disputes: admin update') then
    create policy "Disputes: admin update"
      on public.dispute_reports for update to authenticated
      using (exists (select 1 from public.users where id = auth.uid() and role = 'admin'));
  end if;
end $$;

-- ─── ride_otps ───────────────────────────────────────────────────────────────
do $$
begin
  -- Saccos can read the OTP for rides they own (to verify passenger)
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='ride_otps' and policyname='Ride OTPs: sacco read own') then
    create policy "Ride OTPs: sacco read own"
      on public.ride_otps for select to authenticated
      using (
        exists (
          select 1 from public.rides
          where rides.id = ride_otps.ride_id
            and rides.provider_id = auth.uid()
        )
      );
  end if;

  -- Passengers can insert an OTP for a ride they created
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='ride_otps' and policyname='Ride OTPs: creator insert') then
    create policy "Ride OTPs: creator insert"
      on public.ride_otps for insert to authenticated
      with check (
        exists (
          select 1 from public.rides
          where rides.id = ride_otps.ride_id
            and rides.creator_id = auth.uid()
        )
      );
  end if;

  -- Saccos mark OTP as used
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='ride_otps' and policyname='Ride OTPs: sacco mark used') then
    create policy "Ride OTPs: sacco mark used"
      on public.ride_otps for update to authenticated
      using (
        exists (
          select 1 from public.rides
          where rides.id = ride_otps.ride_id
            and rides.provider_id = auth.uid()
        )
      );
  end if;
end $$;
