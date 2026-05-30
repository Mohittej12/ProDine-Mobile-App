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

alter table public.employee_profiles enable row level security;
alter table public.verification_codes enable row level security;

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

drop policy if exists "No direct verification code access" on public.verification_codes;
create policy "No direct verification code access"
on public.verification_codes
for all
using (false)
with check (false);

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.employee_profiles to anon, authenticated;
grant execute on function public.employee_profile_exists(text, text, text)
  to anon, authenticated;
grant execute on function public.create_employee_profile(
  text, text, text, text, text, boolean
) to anon, authenticated;
grant execute on function public.login_employee(text, text, text)
  to anon, authenticated;

-- Manual Supabase Auth setting:
-- No Auth provider is required for this employee development flow.
-- This is intentionally table-backed and should be replaced before production.
