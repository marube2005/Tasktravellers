-- Migration: Auto-expire group rides older than 14 days that remain in forming or ready status
-- Run this query to clean up legacy stale group rides in Supabase.

UPDATE public.group_rides
SET status = 'expired',
    updated_at = NOW()
WHERE status IN ('forming', 'ready')
  AND created_at < NOW() - INTERVAL '14 days';

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
