-- Fix missing columns on group_rides table and reload schema cache
-- Run this in the Supabase SQL Editor if encountering PGRST204 schema cache errors

ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS origin TEXT;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS destination TEXT;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS origin_lat DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS origin_lng DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS dest_lat DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS dest_lng DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS destination_lat DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS destination_lng DOUBLE PRECISION;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS schedule_type TEXT DEFAULT 'Now';
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMPTZ;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS max_passengers INT DEFAULT 4;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS min_passengers INT DEFAULT 3;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS current_passengers INT DEFAULT 1;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'forming';
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS invite_code TEXT;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS invite_link TEXT;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS group_note TEXT;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE;
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.group_rides ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
