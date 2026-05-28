-- ============================================
-- EMPLOYEE AUTHENTICATION DATABASE SCHEMA
-- ============================================
-- Run these queries in your Supabase SQL Editor

-- ============================================
-- 1. EMPLOYEE PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.employee_profiles (
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

-- Add indexes for better query performance
CREATE INDEX idx_employee_profiles_user_id ON public.employee_profiles(user_id);
CREATE INDEX idx_employee_profiles_employee_id ON public.employee_profiles(employee_id);
CREATE INDEX idx_employee_profiles_mobile_number ON public.employee_profiles(mobile_number);
CREATE INDEX idx_employee_profiles_email ON public.employee_profiles(email);

-- ============================================
-- 2. VERIFICATION CODES TABLE (for OTP)
-- ============================================
CREATE TABLE IF NOT EXISTS public.verification_codes (
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
CREATE INDEX idx_verification_codes_created_at ON public.verification_codes(created_at);

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on employee_profiles
ALTER TABLE public.employee_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own employee profile
CREATE POLICY "Users can read their own profile" ON public.employee_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update their own employee profile
CREATE POLICY "Users can update their own profile" ON public.employee_profiles
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Allow inserts during signup (authenticated users only)
CREATE POLICY "Users can create their own profile" ON public.employee_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Enable RLS on verification_codes (restrict access - usually accessed via functions)
ALTER TABLE public.verification_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Disable direct access from client (use functions instead)
CREATE POLICY "Verification codes are not directly accessible" ON public.verification_codes
  FOR ALL
  USING (FALSE);

-- ============================================
-- 4. CREATE HELPER FUNCTIONS (Optional)
-- ============================================

-- Function to validate OTP and mark as verified
CREATE OR REPLACE FUNCTION validate_otp(
  p_phone_number VARCHAR,
  p_otp VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
  v_record RECORD;
BEGIN
  SELECT * INTO v_record FROM public.verification_codes
  WHERE phone_number = p_phone_number
    AND otp = p_otp
    AND is_verified = FALSE
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1;

  IF FOUND THEN
    UPDATE public.verification_codes
    SET is_verified = TRUE
    WHERE phone_number = p_phone_number
      AND otp = p_otp;
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired verification codes
CREATE OR REPLACE FUNCTION cleanup_expired_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.verification_codes
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. SAMPLE DATA (FOR TESTING - DELETE IN PRODUCTION)
-- ============================================
-- Do NOT run this in production!
-- This is for testing the authentication flow

-- Note: In production, use actual Supabase Auth for user creation
-- The following is just for demonstration of the schema structure

/*
-- Create a test user (via Supabase Auth first, then insert profile)
INSERT INTO public.employee_profiles (
  user_id,
  employee_id,
  full_name,
  mobile_number,
  email,
  is_phone_verified,
  user_type
) VALUES (
  '00000000-0000-0000-0000-000000000001'::UUID,
  'EMP001',
  'John Doe',
  '9876543210',
  'john@prodine.com',
  FALSE,
  'employee'
);
*/

-- ============================================
-- END OF SCHEMA
-- ============================================
