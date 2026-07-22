# Project Rules & Architecture Standards

## Repository Structure & Tooling
- The Flutter application is located at the project root (`pubspec.yaml`, `lib/`, `android/`, `ios/`, `web/`, `.env`).
- Always run Flutter CLI commands (`flutter run`, `flutter pub get`, `flutter analyze`, `flutter test`) directly from the workspace root directory.
- Backend SQL migrations and database setup documentation reside in `/supabase/migrations`.

## Supabase Authentication & Profile Management
- When signing up users via email or verifying phone OTP, always upsert/sync their profile into the `public.users` table with `id`, `name`, `email`, `phone`, and `role`.
- Sanitize emails (`email.trim().toLowerCase()`) during registration and login to ensure consistent credentials matching.
