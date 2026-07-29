-- Complete SQL Setup & Seeding Script for Group Pooling
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

-- 1. Create group_rides table if it does not exist
CREATE TABLE IF NOT EXISTS public.group_rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  origin TEXT NOT NULL,
  destination TEXT NOT NULL,
  origin_lat DOUBLE PRECISION,
  origin_lng DOUBLE PRECISION,
  dest_lat DOUBLE PRECISION,
  dest_lng DOUBLE PRECISION,
  destination_lat DOUBLE PRECISION,
  destination_lng DOUBLE PRECISION,
  schedule_type TEXT DEFAULT 'Now',
  scheduled_time TIMESTAMPTZ,
  max_passengers INT DEFAULT 4,
  min_passengers INT DEFAULT 3,
  current_passengers INT DEFAULT 1,
  status TEXT DEFAULT 'forming',
  invite_code TEXT UNIQUE,
  invite_link TEXT,
  group_note TEXT,
  is_locked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create group_members table if it does not exist
CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.group_rides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  joined_via TEXT DEFAULT 'invite_link',
  confirmed BOOLEAN DEFAULT TRUE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT group_members_group_user_unique UNIQUE (group_id, user_id)
);

-- 3. Create pending_invites table if it does not exist
CREATE TABLE IF NOT EXISTS public.pending_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.group_rides(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  invited_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and add basic open access policies
ALTER TABLE public.group_rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read group_rides" ON public.group_rides FOR SELECT USING (true);
CREATE POLICY "Allow insert group_rides" ON public.group_rides FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update group_rides" ON public.group_rides FOR UPDATE USING (true);

CREATE POLICY "Allow read group_members" ON public.group_members FOR SELECT USING (true);
CREATE POLICY "Allow insert group_members" ON public.group_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow delete group_members" ON public.group_members FOR DELETE USING (true);

CREATE POLICY "Allow read pending_invites" ON public.pending_invites FOR SELECT USING (true);
CREATE POLICY "Allow insert pending_invites" ON public.pending_invites FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update pending_invites" ON public.pending_invites FOR UPDATE USING (true);

-- 4. Seed Test Group Ride
DO $$
DECLARE
  v_user_id UUID;
  v_group_id UUID := '88888888-8888-8888-8888-888888888888'::UUID;
BEGIN
  SELECT id INTO v_user_id FROM public.users LIMIT 1;
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  END IF;

  DELETE FROM public.group_members WHERE group_id = v_group_id;
  DELETE FROM public.group_rides WHERE id = v_group_id;

  INSERT INTO public.group_rides (
    id, creator_id, origin, destination, origin_lat, origin_lng, dest_lat, dest_lng,
    schedule_type, max_passengers, min_passengers, current_passengers, status, invite_code, created_at, is_locked
  ) VALUES (
    v_group_id, v_user_id, 'Nairobi CBD (Archives)', 'Westlands Terminal',
    -1.286389, 36.817223, -1.268333, 36.809444,
    'Now', 4, 3, 1, 'forming', 'RIDE88', NOW(), FALSE
  );

  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.group_members (group_id, user_id, joined_via, confirmed, joined_at)
    VALUES (v_group_id, v_user_id, 'creator', TRUE, NOW())
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
