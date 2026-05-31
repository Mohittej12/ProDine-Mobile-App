-- Employee order persistence schema for Supabase/Postgres.
-- Create this table in the same project used by the app.

CREATE TABLE public.employee_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL UNIQUE,
  user_id UUID,
  employee_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  shop_id TEXT NOT NULL,
  shop_name TEXT NOT NULL,
  order_intent TEXT NOT NULL,
  items JSONB NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'ordered',
  pickup_slot TEXT,
  is_ticketing BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_employee_orders_employee_id ON public.employee_orders(employee_id);
CREATE INDEX idx_employee_orders_user_id ON public.employee_orders(user_id);

-- DISABLE RLS (Row Level Security) FOR DEVELOPMENT
-- This allows the app to insert/read orders without Supabase auth session
ALTER TABLE public.employee_orders DISABLE ROW LEVEL SECURITY;

-- GRANT PERMISSIONS FOR DEVELOPMENT
-- Allow both anonymous and authenticated users to insert, read, update, delete
GRANT ALL ON TABLE public.employee_orders TO anon, authenticated;
