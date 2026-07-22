-- Auto-create public.users row whenever a user signs up in auth.users
-- Uses SECURITY DEFINER to bypass RLS restrictions during signup.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, email, name, phone, role)
  values (
    new.id,
    coalesce(new.email, new.raw_user_meta_data->>'email'),
    coalesce(new.raw_user_meta_data->>'name', 'New Traveler'),
    coalesce(new.phone, new.raw_user_meta_data->>'phone'),
    'passenger'
  )
  on conflict (id) do update set
    email = coalesce(excluded.email, public.users.email),
    name = coalesce(excluded.name, public.users.name),
    phone = coalesce(excluded.phone, public.users.phone),
    updated_at = now();
  return new;
end;
$$;

-- Create the trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
