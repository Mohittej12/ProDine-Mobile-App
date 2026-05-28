-- ============================================
-- Employee Authentication Tables
-- Fresh Setup - RLS DISABLED for Development
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS verification_codes CASCADE;
DROP TABLE IF EXISTS employee_profiles CASCADE;

-- ============================================
-- 1. EMPLOYEE PROFILES TABLE
-- ============================================
CREATE TABLE public.employee_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  employee_id VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  mobile_number VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  user_type VARCHAR(50) DEFAULT 'employee',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT employee_profiles_user_id_key UNIQUE (user_id),
  CONSTRAINT employee_profiles_employee_id_key UNIQUE (employee_id),
  CONSTRAINT employee_profiles_mobile_number_key UNIQUE (mobile_number),
  CONSTRAINT employee_profiles_email_key UNIQUE (email)
);

-- Create indexes for better performance
CREATE INDEX idx_employee_profiles_user_id ON public.employee_profiles(user_id);
CREATE INDEX idx_employee_profiles_employee_id ON public.employee_profiles(employee_id);
CREATE INDEX idx_employee_profiles_mobile_number ON public.employee_profiles(mobile_number);
CREATE INDEX idx_employee_profiles_email ON public.employee_profiles(email);

-- ============================================
-- 2. VERIFICATION CODES TABLE
-- ============================================
CREATE TABLE public.verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT verification_codes_otp_check CHECK (otp ~ '^\d{6}$'),
  CONSTRAINT verification_codes_attempts_check CHECK (attempts >= 0)
);

-- Create indexes for better performance
CREATE INDEX idx_verification_codes_phone_number ON public.verification_codes(phone_number);
CREATE INDEX idx_verification_codes_otp ON public.verification_codes(otp);
CREATE INDEX idx_verification_codes_expires_at ON public.verification_codes(expires_at);

-- ============================================
-- DISABLE RLS (Row Level Security)
-- This allows anonymous/unauthenticated inserts from the app
-- ============================================
ALTER TABLE public.employee_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_codes DISABLE ROW LEVEL SECURITY;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT ALL ON TABLE public.employee_profiles TO authenticated;
GRANT ALL ON TABLE public.employee_profiles TO anon;

GRANT ALL ON TABLE public.verification_codes TO authenticated;
GRANT ALL ON TABLE public.verification_codes TO anon;

-- ============================================
-- VERIFY SETUP
-- ============================================
-- Run these to verify tables were created correctly:
-- SELECT * FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT * FROM pg_tables WHERE schemaname = 'public';
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('employee_profiles', 'verification_codes');
