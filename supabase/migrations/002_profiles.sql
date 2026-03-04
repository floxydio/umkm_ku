-- ============================================================
-- UMKM KU — Profiles table (Supabase auth user metadata)
-- Jalankan di: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT        NOT NULL UNIQUE,
  full_name     TEXT        NOT NULL,
  store_name    TEXT        NOT NULL,
  business_type TEXT        NOT NULL,
  phone         TEXT        NOT NULL DEFAULT '',
  email         TEXT        NOT NULL DEFAULT '',
  plan          TEXT        NOT NULL DEFAULT 'free',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- Row-level security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone (including unauthenticated) can read profiles.
-- Needed for: username lookup during login, username availability check during register.
CREATE POLICY "public can read profiles" ON profiles
  FOR SELECT TO anon, authenticated USING (true);

-- Only the owner can insert/update their own row
CREATE POLICY "users can insert own profile" ON profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "users can update own profile" ON profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);
