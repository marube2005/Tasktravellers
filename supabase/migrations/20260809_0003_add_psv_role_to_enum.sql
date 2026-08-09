-- Migration: Add 'psv' to user_role enum and update trigger to respect role from metadata.
-- Run this in Supabase SQL Editor.

-- =====================================================
-- 1. Add 'psv' to the user_role enum if it exists
-- =====================================================
DO $$
BEGIN
  -- Check if user_role enum type exists and add 'psv' if missing
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    -- Add 'psv' value to the enum if not already present
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum
      WHERE enumtypid = 'user_role'::regtype
        AND enumlabel = 'psv'
    ) THEN
      ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'psv';
    END IF;

    -- Add 'driver' value as well (common alias)
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum
      WHERE enumtypid = 'user_role'::regtype
        AND enumlabel = 'driver'
    ) THEN
      ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'driver';
    END IF;
  END IF;
END;
$$;

-- =====================================================
-- 2. If role column is an enum, convert it to text so
--    any string value ('psv', 'passenger', 'driver') works.
-- =====================================================
DO $$
DECLARE
  col_type text;
BEGIN
  SELECT data_type INTO col_type
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'users'
    AND column_name = 'role';

  IF col_type = 'USER-DEFINED' THEN
    -- Convert enum column to text to allow free-form roles
    ALTER TABLE public.users
      ALTER COLUMN role TYPE text USING role::text;

    -- Restore default
    ALTER TABLE public.users
      ALTER COLUMN role SET DEFAULT 'passenger';
  END IF;
END;
$$;

-- =====================================================
-- 3. Update the handle_new_user trigger to read role
--    from auth metadata instead of always defaulting to 'passenger'
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_role text;
BEGIN
  -- Read role from signup metadata; default to 'passenger'
  v_role := coalesce(
    new.raw_user_meta_data->>'role',
    'passenger'
  );

  BEGIN
    INSERT INTO public.users (id, email, name, phone, role)
    VALUES (
      new.id,
      coalesce(new.email, new.raw_user_meta_data->>'email'),
      coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'New Traveler'),
      coalesce(new.phone, new.raw_user_meta_data->>'phone'),
      v_role
    )
    ON CONFLICT (id) DO UPDATE SET
      email = coalesce(excluded.email, public.users.email),
      name  = coalesce(excluded.name,  public.users.name),
      phone = coalesce(excluded.phone, public.users.phone),
      role  = CASE WHEN public.users.role = 'passenger' THEN excluded.role ELSE public.users.role END,
      updated_at = now();
  EXCEPTION WHEN others THEN
    RAISE WARNING 'handle_new_user trigger encountered an error: %', SQLERRM;
  END;

  RETURN new;
END;
$$;

NOTIFY pgrst, 'reload schema';
