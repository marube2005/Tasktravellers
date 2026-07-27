-- SQL Script to Seed a Test Group Ride
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

DO $$
DECLARE
  v_user_id uuid;
  v_group_id uuid;
BEGIN
  -- Get any existing user ID from public.users table or auth.users
  SELECT id INTO v_user_id FROM public.users LIMIT 1;
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  END IF;

  -- Generate fixed test group ride ID
  v_group_id := '88888888-8888-8888-8888-888888888888'::uuid;

  -- Delete previous test seed if exists
  DELETE FROM public.group_members WHERE group_id = v_group_id;
  DELETE FROM public.group_rides WHERE id = v_group_id;

  -- Insert seeded group ride
  INSERT INTO public.group_rides (
    id,
    creator_id,
    origin,
    destination,
    origin_lat,
    origin_lng,
    dest_lat,
    dest_lng,
    schedule_type,
    max_passengers,
    min_passengers,
    current_passengers,
    status,
    invite_code,
    created_at,
    is_locked
  ) VALUES (
    v_group_id,
    v_user_id,
    'Nairobi CBD (Archives)',
    'Westlands Terminal',
    -1.286389,
    36.817223,
    -1.268333,
    36.809444,
    'Now',
    4,
    3,
    1,
    'forming',
    'RIDE88',
    NOW(),
    FALSE
  );

  -- Insert creator into group_members
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.group_members (
      group_id,
      user_id,
      joined_via,
      confirmed,
      joined_at
    ) VALUES (
      v_group_id,
      v_user_id,
      'creator',
      TRUE,
      NOW()
    ) ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE '✅ Successfully seeded test group ride ID: % with invite code: RIDE88', v_group_id;
END $$;
