-- ============================================
-- EMPLOYEE AUTHENTICATION DATABASE SCHEMA (FIXED)
-- ============================================
-- Run these queries in your Supabase SQL Editor
-- This version disables RLS for development

-- ============================================
-- 1. DROP EXISTING TABLES (if needed)
-- ============================================
DROP TABLE IF EXISTS public.verification_codes CASCADE;
DROP TABLE IF EXISTS public.employee_profiles CASCADE;

-- ============================================
-- 2. CREATE EMPLOYEE PROFILES TABLE
-- ============================================
CREATE TABLE public.employee_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  employee_id VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  mobile_number VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  user_type VARCHAR(50) DEFAULT 'employee',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Add indexes
CREATE INDEX idx_employee_profiles_user_id ON public.employee_profiles(user_id);
CREATE INDEX idx_employee_profiles_employee_id ON public.employee_profiles(employee_id);
CREATE INDEX idx_employee_profiles_mobile_number ON public.employee_profiles(mobile_number);

-- ============================================
-- 3. CREATE VERIFICATION CODES TABLE
-- ============================================
CREATE TABLE public.verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Add indexes
CREATE INDEX idx_verification_codes_phone_number ON public.verification_codes(phone_number);

-- ============================================
-- 4. DISABLE RLS FOR DEVELOPMENT
-- ============================================
ALTER TABLE public.employee_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_codes DISABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. GRANT PERMISSIONS
-- ============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.employee_profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.verification_codes TO anon, authenticated;

-- Done! Tables are now ready for use.
