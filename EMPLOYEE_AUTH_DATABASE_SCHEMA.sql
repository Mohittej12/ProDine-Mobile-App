-- ============================================
-- Employee Authentication Database Schema
-- ============================================
-- Run this complete script in the Supabase SQL Editor.
-- It reuses public.employee_profiles and does not drop employee data.

create extension if not exists pgcrypto;

create table if not exists public.employee_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  employee_id text not null unique,
  full_name text not null,
  mobile_number text not null unique,
  email text unique,
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

alter table public.employee_profiles
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

-- Kept for the existing phone verification service, even though employee
-- registration/login currently skip OTP and email verification.
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
set search_path = public, auth
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
  p_user_id uuid,
  p_employee_id text,
  p_full_name text,
  p_mobile_number text,
  p_email text default null,
  p_terms_accepted boolean default true
)
returns setof public.employee_profiles
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile public.employee_profiles%rowtype;
begin
  if p_user_id is null then
    raise exception 'User id is required';
  end if;

  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'Auth user does not exist';
  end if;

  if nullif(trim(p_employee_id), '') is null then
    raise exception 'Employee ID is required';
  end if;

  if nullif(trim(p_full_name), '') is null then
    raise exception 'Full Name is required';
  end if;

  if nullif(trim(p_mobile_number), '') is null then
    raise exception 'Mobile Number is required';
  end if;

  if p_terms_accepted is not true then
    raise exception 'Terms must be accepted';
  end if;

  if exists (
    select 1 from public.employee_profiles
    where user_id <> p_user_id
      and lower(employee_id) = lower(trim(p_employee_id))
  ) then
    raise exception 'Employee ID already registered';
  end if;

  if exists (
    select 1 from public.employee_profiles
    where user_id <> p_user_id
      and mobile_number = trim(p_mobile_number)
  ) then
    raise exception 'Phone number already registered';
  end if;

  if p_email is not null and exists (
    select 1 from public.employee_profiles
    where user_id <> p_user_id
      and lower(email) = lower(trim(p_email))
  ) then
    raise exception 'Email already registered';
  end if;

  insert into public.employee_profiles (
    user_id,
    employee_id,
    full_name,
    mobile_number,
    email,
    terms_accepted,
    terms_accepted_at,
    is_phone_verified,
    user_type
  )
  values (
    p_user_id,
    trim(p_employee_id),
    trim(p_full_name),
    trim(p_mobile_number),
    nullif(lower(trim(p_email)), ''),
    true,
    timezone('utc', now()),
    false,
    'employee'
  )
  on conflict (user_id) do update
  set employee_id = excluded.employee_id,
      full_name = excluded.full_name,
      mobile_number = excluded.mobile_number,
      email = excluded.email,
      terms_accepted = excluded.terms_accepted,
      terms_accepted_at = excluded.terms_accepted_at,
      user_type = 'employee'
  returning * into v_profile;

  return next v_profile;
end;
$$;

alter table public.employee_profiles enable row level security;
alter table public.verification_codes enable row level security;

drop policy if exists "Employees can read own profile" on public.employee_profiles;
create policy "Employees can read own profile"
on public.employee_profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Employees can update own profile" on public.employee_profiles;
create policy "Employees can update own profile"
on public.employee_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "No direct verification code access" on public.verification_codes;
create policy "No direct verification code access"
on public.verification_codes
for all
using (false)
with check (false);

grant usage on schema public to anon, authenticated;
grant select, update on public.employee_profiles to authenticated;
grant execute on function public.employee_profile_exists(text, text, text)
  to anon, authenticated;
grant execute on function public.create_employee_profile(
  uuid, text, text, text, text, boolean
) to anon, authenticated;

-- Required manual Auth setting:
-- Supabase Dashboard -> Authentication -> Sign In / Providers -> Email:
-- Keep Email provider enabled and disable email confirmation while verification is ignored.
