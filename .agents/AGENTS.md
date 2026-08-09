# Project Rules & Architecture Standards

## Repository Structure & Tooling
- The Flutter application is located at the project root (`pubspec.yaml`, `lib/`, `android/`, `ios/`, `web/`, `.env`).
- Always run Flutter CLI commands (`flutter run`, `flutter pub get`, `flutter analyze`, `flutter test`) directly from the workspace root directory.
- Backend SQL migrations and database setup documentation reside in `/supabase/migrations`.

## Supabase Authentication & Profile Management
- When signing up users via email or verifying phone OTP, always upsert/sync their profile into the `public.users` table with `id`, `name`, `email`, `phone`, and `role`.
- Sanitize emails (`email.trim().toLowerCase()`) during registration and login to ensure consistent credentials matching.

## Database Migrations & Supabase Schema Drift
- Always use explicit `ALTER TABLE public.<table_name> ADD COLUMN IF NOT EXISTS <column_name> <type>;` statements when introducing new fields. Do not rely on modifying `CREATE TABLE IF NOT EXISTS` blocks to update pre-existing tables.
- When diagnosing PostgREST `PGRST204` errors ("Could not find column in schema cache"), ensure the column is safely added via `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` in migrations, and notify PostgREST to reload its schema cache (`NOTIFY pgrst, 'reload schema'`).

