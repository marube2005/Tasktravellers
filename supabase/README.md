# Supabase Setup and Missing Schema Fixes

This project expects several `public` tables and storage buckets.
If you see errors like `PGRST204 Could not find column ...`, apply the migration in this folder.

## Option A: Supabase SQL Editor (fastest)

1. Open your Supabase project dashboard.
2. Go to `SQL Editor`.
3. Open `supabase/migrations/20260419_0001_bootstrap_schema.sql`.
4. Paste and run the SQL.
5. Retry the app flow.

## Option B: Supabase CLI (recommended for team workflows)

1. Install Supabase CLI.
2. Login and link your project:

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

3. Push local migrations:

```bash
supabase db push
```

## Verify Required Objects

Run this in SQL Editor after migration:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'users', 'sacco_profiles', 'vehicles', 'rides',
    'bookings', 'transactions', 'vehicle_locations'
  )
order by table_name;
```

And verify user profile fields:

```sql
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'users'
  and column_name in (
    'home_area', 'preferred_routes',
    'emergency_contact_name', 'emergency_contact_phone',
    'avatar_url'
  )
order by column_name;
```

## Important Security Note

Do not put privileged keys (for example `SUPABASE_SERVICE_ROLE_KEY` or PayHero secret credentials) in client `.env` files.
Client apps are reverse-engineerable. Move privileged operations to Edge Functions or a backend service.
