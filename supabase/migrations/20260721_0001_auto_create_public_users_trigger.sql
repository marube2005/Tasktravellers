-- Auto-create public.users row whenever a user signs up in auth.users
-- Uses SECURITY DEFINER to bypass RLS restrictions during signup.

-- Grant full usage/create permissions on public schema to all database roles
grant usage on schema public to public, postgres, anon, authenticated, service_role, supabase_admin;
grant all privileges on schema public to postgres, service_role, supabase_admin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
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
  exception when others then
    raise warning 'handle_new_user trigger encountered an error: %', SQLERRM;
  end;
  return new;
end;
$$;

-- Grant execution permission on the trigger function
grant execute on function public.handle_new_user() to public, postgres, anon, authenticated, service_role;

-- Create the trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
