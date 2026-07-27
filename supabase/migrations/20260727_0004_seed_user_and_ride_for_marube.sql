-- SQL Migration & Seed Script for user: marubeelvis3@gmail.com
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

DO $$
DECLARE
  v_user_id UUID;
  v_group_id UUID := '88888888-8888-8888-8888-888888888888'::UUID;
BEGIN
  -- 1. Find user ID for marubeelvis3@gmail.com in auth.users or public.users
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'marubeelvis3@gmail.com' LIMIT 1;
  
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.users WHERE email = 'marubeelvis3@gmail.com' LIMIT 1;
  END IF;

  -- If user doesn't exist in auth.users yet, raise notice
  IF v_user_id IS NULL THEN
    -- Fallback: Use existing user or create public user entry
    SELECT id INTO v_user_id FROM public.users LIMIT 1;
    IF v_user_id IS NULL THEN
      SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    END IF;
  END IF;

  -- 2. Upsert profile into public.users with passenger role
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.users (
      id,
      name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      'Marube Elvis',
      'marubeelvis3@gmail.com',
      'passenger',
      NOW(),
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      role = 'passenger',
      updated_at = NOW();
  END IF;

  -- 3. Clear previous seeded ride
  DELETE FROM public.group_members WHERE group_id = v_group_id;
  DELETE FROM public.group_rides WHERE id = v_group_id;

  -- 4. Insert group ride linked to marubeelvis3@gmail.com
  INSERT INTO public.group_rides (
    id, creator_id, origin, destination, origin_lat, origin_lng, dest_lat, dest_lng,
    schedule_type, max_passengers, min_passengers, current_passengers, status, invite_code, created_at, is_locked
  ) VALUES (
    v_group_id, v_user_id, 'Nairobi CBD (Archives)', 'Westlands Terminal',
    -1.286389, 36.817223, -1.268333, 36.809444,
    'Now', 4, 3, 1, 'forming', 'RIDE88', NOW(), FALSE
  );

  -- 5. Insert creator into group_members
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.group_members (group_id, user_id, joined_via, confirmed, joined_at)
    VALUES (v_group_id, v_user_id, 'creator', TRUE, NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE '✅ Successfully seeded group ride RIDE88 for user marubeelvis3@gmail.com (ID: %)', v_user_id;
END $$;
