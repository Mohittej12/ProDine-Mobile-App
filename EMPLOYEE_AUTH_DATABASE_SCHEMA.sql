-- ============================================
-- Employee Authentication Database Schema
-- Development flow: no OTP, SMS verification, email verification, or Supabase Auth signup.
-- Run this complete script in the Supabase SQL Editor.
-- ============================================

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.employee_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique default gen_random_uuid(),
  employee_id text not null unique,
  full_name text not null,
  mobile_number text not null unique,
  email text unique,
  password_hash text,
  terms_accepted boolean not null default false,
  terms_accepted_at timestamptz,
  is_phone_verified boolean not null default false,
  user_type text not null default 'employee',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint employee_profiles_user_type_check check (user_type = 'employee'),
  constraint employee_profiles_terms_check check (
    terms_accepted = false or terms_accepted_at is not null
  )
);

-- If an earlier Supabase Auth-based schema exists, remove the dependency on auth.users.
alter table public.employee_profiles
  drop constraint if exists employee_profiles_user_id_fkey;

alter table public.employee_profiles
  alter column user_id set default gen_random_uuid(),
  add column if not exists password_hash text,
  add column if not exists terms_accepted boolean not null default false,
  add column if not exists terms_accepted_at timestamptz,
  add column if not exists is_phone_verified boolean not null default false,
  add column if not exists user_type text not null default 'employee',
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

create unique index if not exists employee_profiles_user_id_uidx
  on public.employee_profiles(user_id);
create unique index if not exists employee_profiles_employee_id_uidx
  on public.employee_profiles(lower(employee_id));
create unique index if not exists employee_profiles_mobile_number_uidx
  on public.employee_profiles(mobile_number);
create unique index if not exists employee_profiles_email_uidx
  on public.employee_profiles(lower(email))
  where email is not null;
create index if not exists employee_profiles_created_at_idx
  on public.employee_profiles(created_at);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_employee_profiles_updated_at on public.employee_profiles;
create trigger set_employee_profiles_updated_at
before update on public.employee_profiles
for each row execute function public.set_updated_at();

create table if not exists public.verification_codes (
  id uuid primary key default gen_random_uuid(),
  phone_number text not null,
  otp text not null,
  is_verified boolean not null default false,
  attempts integer not null default 0,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint verification_codes_otp_check check (otp ~ '^[0-9]{6}$'),
  constraint verification_codes_attempts_check check (attempts >= 0)
);

create index if not exists verification_codes_phone_number_idx
  on public.verification_codes(phone_number);
create index if not exists verification_codes_expires_at_idx
  on public.verification_codes(expires_at);

-- Admin profiles table
create table if not exists public.admin_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique default gen_random_uuid(),
  admin_id text not null unique,
  full_name text not null,
  mobile_number text not null unique,
  email text unique,
  password_hash text,
  is_active boolean not null default true,
  user_type text not null default 'admin',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint admin_profiles_user_type_check check (user_type = 'admin')
);

create unique index if not exists admin_profiles_user_id_uidx
  on public.admin_profiles(user_id);
create unique index if not exists admin_profiles_admin_id_uidx
  on public.admin_profiles(lower(admin_id));
create unique index if not exists admin_profiles_mobile_number_uidx
  on public.admin_profiles(mobile_number);
create unique index if not exists admin_profiles_email_uidx
  on public.admin_profiles(lower(email))
  where email is not null;

-- Vendor profiles table
create table if not exists public.vendor_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique default gen_random_uuid(),
  vendor_id text not null unique,
  shop_name text not null,
  mobile_number text not null unique,
  email text unique,
  password_hash text,
  is_active boolean not null default true,
  user_type text not null default 'vendor',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint vendor_profiles_user_type_check check (user_type = 'vendor')
);

create unique index if not exists vendor_profiles_user_id_uidx
  on public.vendor_profiles(user_id);
create unique index if not exists vendor_profiles_vendor_id_uidx
  on public.vendor_profiles(lower(vendor_id));
create unique index if not exists vendor_profiles_mobile_number_uidx
  on public.vendor_profiles(mobile_number);
create unique index if not exists vendor_profiles_email_uidx
  on public.vendor_profiles(lower(email))
  where email is not null;

-- Triggers for updated_at on admin_profiles
drop trigger if exists set_admin_profiles_updated_at on public.admin_profiles;
create trigger set_admin_profiles_updated_at
before update on public.admin_profiles
for each row execute function public.set_updated_at();

-- Triggers for updated_at on vendor_profiles
drop trigger if exists set_vendor_profiles_updated_at on public.vendor_profiles;
create trigger set_vendor_profiles_updated_at
before update on public.vendor_profiles
for each row execute function public.set_updated_at();

create or replace function public.employee_profile_exists(
  p_employee_id text default null,
  p_mobile_number text default null,
  p_email text default null
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.employee_profiles ep
    where (p_employee_id is not null and lower(ep.employee_id) = lower(p_employee_id))
       or (p_mobile_number is not null and ep.mobile_number = p_mobile_number)
       or (p_email is not null and lower(ep.email) = lower(p_email))
  );
$$;

create or replace function public.create_employee_profile(
  p_employee_id text,
  p_full_name text,
  p_mobile_number text,
  p_email text default null,
  p_password text default null,
  p_terms_accepted boolean default true
)
returns setof public.employee_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.employee_profiles%rowtype;
begin
  if nullif(trim(p_employee_id), '') is null then
    raise exception 'Employee ID is required';
  end if;

  if nullif(trim(p_full_name), '') is null then
    raise exception 'Full Name is required';
  end if;

  if nullif(trim(p_mobile_number), '') is null then
    raise exception 'Mobile Number is required';
  end if;

  if nullif(p_password, '') is null then
    raise exception 'Password is required';
  end if;

  if length(p_password) < 8 then
    raise exception 'Password must be at least 8 characters';
  end if;

  if p_terms_accepted is not true then
    raise exception 'Terms must be accepted';
  end if;

  if exists (
    select 1 from public.employee_profiles
    where lower(employee_id) = lower(trim(p_employee_id))
  ) then
    raise exception 'Employee ID already registered';
  end if;

  if exists (
    select 1 from public.employee_profiles
    where mobile_number = trim(p_mobile_number)
  ) then
    raise exception 'Phone number already registered';
  end if;

  if nullif(trim(coalesce(p_email, '')), '') is not null and exists (
    select 1 from public.employee_profiles
    where lower(email) = lower(trim(p_email))
  ) then
    raise exception 'Email already registered';
  end if;

  insert into public.employee_profiles (
    user_id,
    employee_id,
    full_name,
    mobile_number,
    email,
    password_hash,
    terms_accepted,
    terms_accepted_at,
    is_phone_verified,
    user_type
  )
  values (
    gen_random_uuid(),
    trim(p_employee_id),
    trim(p_full_name),
    trim(p_mobile_number),
    nullif(lower(trim(coalesce(p_email, ''))), ''),
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    true,
    timezone('utc', now()),
    false,
    'employee'
  )
  returning * into v_profile;

  return next v_profile;
end;
$$;

create or replace function public.login_employee(
  p_mobile_number text default null,
  p_email text default null,
  p_password text default null
)
returns setof public.employee_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.employee_profiles%rowtype;
begin
  if nullif(p_password, '') is null then
    raise exception 'Password is required';
  end if;

  select *
  into v_profile
  from public.employee_profiles ep
  where (
      p_mobile_number is not null
      and ep.mobile_number = trim(p_mobile_number)
    )
    or (
      p_email is not null
      and lower(ep.email) = lower(trim(p_email))
    )
  limit 1;

  if v_profile.id is null or v_profile.password_hash is null then
    raise exception 'Invalid login credentials';
  end if;

  if v_profile.password_hash <> extensions.crypt(p_password, v_profile.password_hash) then
    raise exception 'Invalid login credentials';
  end if;

  return next v_profile;
end;
$$;

create or replace function public.change_employee_password(
  p_current_password text,
  p_new_password text,
  p_mobile_number text default null,
  p_email text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.employee_profiles%rowtype;
begin
  if nullif(p_current_password, '') is null then
    raise exception 'Current password is required';
  end if;

  if nullif(p_new_password, '') is null then
    raise exception 'New password is required';
  end if;

  select *
  into v_profile
  from public.employee_profiles ep
  where (
      p_mobile_number is not null
      and ep.mobile_number = trim(p_mobile_number)
    )
    or (
      p_email is not null
      and lower(ep.email) = lower(trim(p_email))
    )
  limit 1;

  if v_profile.id is null or v_profile.password_hash is null then
    raise exception 'Invalid credentials';
  end if;

  if v_profile.password_hash <> extensions.crypt(p_current_password, v_profile.password_hash) then
    raise exception 'Invalid credentials';
  end if;

  update public.employee_profiles
  set password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
  where id = v_profile.id;

  return true;
end;
$$;

create or replace function public.delete_employee_profile(
  p_user_id text default null,
  p_mobile_number text default null,
  p_email text default null,
  p_employee_id text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if (nullif(trim(coalesce(p_user_id, '')), '') is null)
    and (nullif(trim(coalesce(p_mobile_number, '')), '') is null)
    and (nullif(trim(coalesce(p_email, '')), '') is null)
    and (nullif(trim(coalesce(p_employee_id, '')), '') is null) then
    raise exception 'At least one identifier is required';
  end if;

  delete from public.employee_profiles
  where (
    p_user_id is not null and trim(p_user_id) <> '' and user_id::text = trim(p_user_id)
  ) or (
    p_mobile_number is not null and trim(p_mobile_number) <> '' and mobile_number = trim(p_mobile_number)
  ) or (
    p_email is not null and trim(p_email) <> '' and lower(email) = lower(trim(p_email))
  ) or (
    p_employee_id is not null and trim(p_employee_id) <> '' and lower(employee_id) = lower(trim(p_employee_id))
  );

  return true;
end;
$$;

-- Admin login function
create or replace function public.login_admin(
  p_mobile_number text default null,
  p_email text default null,
  p_password text default null
)
returns setof public.admin_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.admin_profiles%rowtype;
begin
  if nullif(p_password, '') is null then
    raise exception 'Password is required';
  end if;

  select *
  into v_profile
  from public.admin_profiles ap
  where (
      p_mobile_number is not null
      and ap.mobile_number = trim(p_mobile_number)
    )
    or (
      p_email is not null
      and lower(ap.email) = lower(trim(p_email))
    )
  limit 1;

  if v_profile.id is null or v_profile.password_hash is null then
    raise exception 'Invalid login credentials';
  end if;

  if v_profile.password_hash <> extensions.crypt(p_password, v_profile.password_hash) then
    raise exception 'Invalid login credentials';
  end if;

  return next v_profile;
end;
$$;

-- Vendor login function
create or replace function public.login_vendor(
  p_mobile_number text default null,
  p_email text default null,
  p_password text default null
)
returns setof public.vendor_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.vendor_profiles%rowtype;
begin
  if nullif(p_password, '') is null then
    raise exception 'Password is required';
  end if;

  select *
  into v_profile
  from public.vendor_profiles vp
  where (
      (
        p_mobile_number is not null
        and vp.mobile_number = trim(p_mobile_number)
      )
      or (
        p_email is not null
        and lower(vp.email) = lower(trim(p_email))
      )
    )
    and vp.is_active = true
  limit 1;

  if v_profile.id is null or v_profile.password_hash is null then
    raise exception 'Invalid login credentials';
  end if;

  if v_profile.password_hash <> extensions.crypt(p_password, v_profile.password_hash) then
    raise exception 'Invalid login credentials';
  end if;

  return next v_profile;
end;
$$;

-- Create admin profile (for initial setup)
create or replace function public.create_admin_profile(
  p_admin_id text,
  p_full_name text,
  p_mobile_number text,
  p_email text default null,
  p_password text default null
)
returns setof public.admin_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.admin_profiles%rowtype;
begin
  if nullif(trim(p_admin_id), '') is null then
    raise exception 'Admin ID is required';
  end if;

  if nullif(trim(p_full_name), '') is null then
    raise exception 'Full Name is required';
  end if;

  if nullif(trim(p_mobile_number), '') is null then
    raise exception 'Mobile Number is required';
  end if;

  if nullif(p_password, '') is null then
    raise exception 'Password is required';
  end if;

  if length(p_password) < 8 then
    raise exception 'Password must be at least 8 characters';
  end if;

  if exists (
    select 1 from public.admin_profiles
    where lower(admin_id) = lower(trim(p_admin_id))
  ) then
    raise exception 'Admin ID already registered';
  end if;

  if exists (
    select 1 from public.admin_profiles
    where mobile_number = trim(p_mobile_number)
  ) then
    raise exception 'Phone number already registered';
  end if;

  insert into public.admin_profiles (
    user_id,
    admin_id,
    full_name,
    mobile_number,
    email,
    password_hash,
    is_active,
    user_type
  )
  values (
    gen_random_uuid(),
    trim(p_admin_id),
    trim(p_full_name),
    trim(p_mobile_number),
    nullif(lower(trim(coalesce(p_email, ''))), ''),
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    true,
    'admin'
  )
  returning * into v_profile;

  return next v_profile;
end;
$$;

alter table public.employee_profiles enable row level security;
alter table public.verification_codes enable row level security;
alter table public.admin_profiles enable row level security;
alter table public.vendor_profiles enable row level security;

drop policy if exists "Development can create employee profiles" on public.employee_profiles;
create policy "Development can create employee profiles"
on public.employee_profiles
for insert
to anon, authenticated
with check (true);

drop policy if exists "Development can read employee profiles" on public.employee_profiles;
create policy "Development can read employee profiles"
on public.employee_profiles
for select
to anon, authenticated
using (true);

drop policy if exists "Development can update employee profiles" on public.employee_profiles;
create policy "Development can update employee profiles"
on public.employee_profiles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "Development can create admin profiles" on public.admin_profiles;
create policy "Development can create admin profiles"
on public.admin_profiles
for insert
to anon, authenticated
with check (true);

drop policy if exists "Development can read admin profiles" on public.admin_profiles;
create policy "Development can read admin profiles"
on public.admin_profiles
for select
to anon, authenticated
using (true);

drop policy if exists "Development can update admin profiles" on public.admin_profiles;
create policy "Development can update admin profiles"
on public.admin_profiles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "Development can create vendor profiles" on public.vendor_profiles;
create policy "Development can create vendor profiles"
on public.vendor_profiles
for insert
to anon, authenticated
with check (true);

drop policy if exists "Development can read vendor profiles" on public.vendor_profiles;
create policy "Development can read vendor profiles"
on public.vendor_profiles
for select
to anon, authenticated
using (true);

drop policy if exists "Development can update vendor profiles" on public.vendor_profiles;
create policy "Development can update vendor profiles"
on public.vendor_profiles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "No direct verification code access" on public.verification_codes;
create policy "No direct verification code access"
on public.verification_codes
for all
using (false)
with check (false);

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.employee_profiles to anon, authenticated;
grant select, insert, update on public.admin_profiles to anon, authenticated;
grant select, insert, update on public.vendor_profiles to anon, authenticated;
grant execute on function public.employee_profile_exists(text, text, text)
  to anon, authenticated;
grant execute on function public.create_employee_profile(
  text, text, text, text, text, boolean
) to anon, authenticated;
grant execute on function public.login_employee(text, text, text)
  to anon, authenticated;
grant execute on function public.change_employee_password(
  text, text, text, text
) to anon, authenticated;
grant execute on function public.delete_employee_profile(
  text, text, text, text
) to anon, authenticated;
grant execute on function public.login_admin(text, text, text)
  to anon, authenticated;
grant execute on function public.create_admin_profile(
  text, text, text, text, text
) to anon, authenticated;
grant execute on function public.login_vendor(text, text, text)
  to anon, authenticated;

-- Manual Supabase Auth setting:
-- No Auth provider is required for this employee development flow.
-- This is intentionally table-backed and should be replaced before production.

-- ============================================
-- Initial Admin Profile Setup
-- ============================================
-- Insert admin profile with phone 7382260206 and password Mohittej@123
insert into public.admin_profiles (
  user_id,
  admin_id,
  full_name,
  mobile_number,
  email,
  password_hash,
  is_active,
  user_type
)
values (
  gen_random_uuid(),
  'admin_001',
  'G. Mohit Tej',
  '+917382260206',
  'admin@prodine.com',
  extensions.crypt('Mohittej@123', extensions.gen_salt('bf')),
  true,
  'admin'
)
on conflict (mobile_number) do nothing;

-- ============================================
-- Initial Vendor Profile Setup
-- ============================================
-- App login normalizes 10-digit Indian phone numbers to +91 format.
-- Only these two active vendor accounts should be able to log in.
update public.vendor_profiles
set is_active = false
where mobile_number not in ('+918838489010', '+919176674776');

insert into public.vendor_profiles (
  user_id,
  vendor_id,
  shop_name,
  mobile_number,
  email,
  password_hash,
  is_active,
  user_type
)
values
  (
    gen_random_uuid(),
    'meal_counter',
    'Meal Counter',
    '+918838489010',
    'meal.counter@prodine.com',
    extensions.crypt('Varshini@123', extensions.gen_salt('bf')),
    true,
    'vendor'
  ),
  (
    gen_random_uuid(),
    'tuck_shop',
    'Tuck Shop',
    '+919176674776',
    'tuck.shop@prodine.com',
    extensions.crypt('Devika@123', extensions.gen_salt('bf')),
    true,
    'vendor'
  )
on conflict (mobile_number) do update
set
  vendor_id = excluded.vendor_id,
  shop_name = excluded.shop_name,
  email = excluded.email,
  password_hash = excluded.password_hash,
  is_active = true,
  user_type = 'vendor';

-- ============================================
