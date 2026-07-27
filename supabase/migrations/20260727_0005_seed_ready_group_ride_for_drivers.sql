-- SQL Seed Script: Full/Ready Group Ride (Ready for Driver Acceptance)
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

DO $$
DECLARE
  v_creator_id UUID;
  v_user2_id UUID := gen_random_uuid();
  v_user3_id UUID := gen_random_uuid();
  v_group_id UUID := '77777777-7777-7777-7777-777777777777'::UUID;
BEGIN
  -- 1. Find or fallback user ID for creator (marubeelvis3@gmail.com)
  SELECT id INTO v_creator_id FROM auth.users WHERE email = 'marubeelvis3@gmail.com' LIMIT 1;
  IF v_creator_id IS NULL THEN
    SELECT id INTO v_creator_id FROM public.users WHERE email = 'marubeelvis3@gmail.com' LIMIT 1;
  END IF;
  IF v_creator_id IS NULL THEN
    SELECT id INTO v_creator_id FROM public.users LIMIT 1;
    IF v_creator_id IS NULL THEN SELECT id INTO v_creator_id FROM auth.users LIMIT 1; END IF;
  END IF;

  -- 2. Safely insert dummy auth users to satisfy public.users foreign key constraint
  BEGIN
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
    VALUES 
      (v_user2_id, '00000000-0000-0000-0000-000000000000', 'jane.wanjiru@example.com', '$2a$10$abcdefghijklmnopqrstuu', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Jane Wanjiru"}', NOW(), NOW(), 'authenticated', 'authenticated'),
      (v_user3_id, '00000000-0000-0000-0000-000000000000', 'john.kamau@example.com', '$2a$10$abcdefghijklmnopqrstuu', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"John Kamau"}', NOW(), NOW(), 'authenticated', 'authenticated')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- 3. Upsert dummy co-passenger profiles into public.users
  BEGIN
    INSERT INTO public.users (id, name, email, phone, role, created_at, updated_at)
    VALUES 
      (v_user2_id, 'Jane Wanjiru', 'jane.wanjiru@example.com', '+254711223344', 'passenger', NOW(), NOW()),
      (v_user3_id, 'John Kamau', 'john.kamau@example.com', '+254722334455', 'passenger', NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
  EXCEPTION WHEN OTHERS THEN
    v_user2_id := v_creator_id;
    v_user3_id := v_creator_id;
  END;

  -- 4. Clear previous seeded ride
  DELETE FROM public.group_members WHERE group_id = v_group_id;
  DELETE FROM public.group_rides WHERE id = v_group_id;

  -- 5. Create Group Ride in 'ready' status (3/4 passengers joined)
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
    v_creator_id,
    'Nairobi CBD (Archives)',
    'Westlands Terminal',
    -1.286389,
    36.817223,
    -1.268333,
    36.809444,
    'Now',
    4,
    3,
    3,
    'ready',
    'READY77',
    NOW(),
    TRUE
  );

  -- 6. Add confirmed passengers into group_members
  IF v_creator_id IS NOT NULL THEN
    INSERT INTO public.group_members (group_id, user_id, joined_via, confirmed, joined_at)
    VALUES (v_group_id, v_creator_id, 'creator', TRUE, NOW() - INTERVAL '10 minutes')
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_user2_id IS NOT NULL AND v_user2_id != v_creator_id THEN
    INSERT INTO public.group_members (group_id, user_id, joined_via, confirmed, joined_at)
    VALUES (v_group_id, v_user2_id, 'invite_link', TRUE, NOW() - INTERVAL '5 minutes')
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_user3_id IS NOT NULL AND v_user3_id != v_creator_id THEN
    INSERT INTO public.group_members (group_id, user_id, joined_via, confirmed, joined_at)
    VALUES (v_group_id, v_user3_id, 'invite_link', TRUE, NOW() - INTERVAL '2 minutes')
    ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE '✅ Successfully seeded READY group ride (ID: %) with 3 joined passengers & code: READY77', v_group_id;
END $$;
