-- Migration: Add psv_driver_profiles table and columns for PSV Driver onboarding

CREATE TABLE IF NOT EXISTS public.psv_driver_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone TEXT,
    email TEXT,
    vehicle_reg_number TEXT,
    psv_badge_url TEXT,
    driving_license_url TEXT,
    road_service_license_url TEXT,
    insurance_cert_url TEXT,
    verification_status TEXT DEFAULT 'pending',
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure explicit column additions for pre-existing tables per rules
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS vehicle_reg_number TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS psv_badge_url TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS driving_license_url TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS road_service_license_url TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS insurance_cert_url TEXT;
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';
ALTER TABLE public.psv_driver_profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
