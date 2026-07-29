-- SQL Migration: Add missing coordinate columns to group_rides table
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

ALTER TABLE public.group_rides
  ADD COLUMN IF NOT EXISTS dest_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS dest_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS destination_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS destination_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS origin_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS origin_lng DOUBLE PRECISION;
