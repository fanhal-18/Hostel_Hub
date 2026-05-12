-- ============================================================
-- HOSTEL MANAGEMENT SYSTEM — SUPABASE SCHEMA
-- Run this in: Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 1. PROFILES ───────────────────────────────────────────────
-- Extended user profile linked to auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT,
  role          TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin')),
  student_id    TEXT,
  hostel_name   TEXT,
  block         TEXT,
  room_no       TEXT,
  academic_year TEXT DEFAULT '2025-2026',
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. ROOMS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rooms (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_number  TEXT NOT NULL,
  block        TEXT NOT NULL,
  floor        INT NOT NULL DEFAULT 1,
  room_type    TEXT NOT NULL DEFAULT 'single' CHECK (room_type IN ('single','double','triple')),
  capacity     INT NOT NULL DEFAULT 1,
  occupied     INT NOT NULL DEFAULT 0,
  status       TEXT NOT NULL DEFAULT 'vacant' CHECK (status IN ('occupied','vacant','maintenance')),
  monthly_rent NUMERIC(10,2) NOT NULL DEFAULT 3000,
  amenities    TEXT[] DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. FEES ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fees (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fee_type    TEXT NOT NULL CHECK (fee_type IN ('room_rent','mess_fee','electricity','other')),
  amount      NUMERIC(10,2) NOT NULL,
  month       TEXT NOT NULL,       -- e.g. 'April 2026'
  due_date    DATE NOT NULL,
  paid        BOOLEAN NOT NULL DEFAULT FALSE,
  paid_at     TIMESTAMPTZ,
  txn_ref     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. COMPLAINTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.complaints (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category     TEXT NOT NULL CHECK (category IN ('plumbing','electrical','carpentry','network','cleaning','other')),
  title        TEXT NOT NULL,
  description  TEXT,
  priority     TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high')),
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','in_progress','resolved')),
  assigned_to  TEXT,
  resolved_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. NOTICES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notices (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  priority    TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal','important','urgent')),
  target      TEXT NOT NULL DEFAULT 'all' CHECK (target IN ('all','block_a','block_b','block_c','block_d')),
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. GATE PASSES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.gate_passes (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose          TEXT NOT NULL,
  destination      TEXT,
  emergency_contact TEXT,
  departure_date   DATE NOT NULL,
  return_date      DATE NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  reviewed_by      UUID REFERENCES public.profiles(id),
  reviewed_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. ATTENDANCE ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.attendance (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  present     BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(student_id, date)
);

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

ALTER TABLE public.profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance  ENABLE ROW LEVEL SECURITY;

-- helper function: get current user role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── profiles ──────────────────────────────────────────────────
-- Users can read/update only their own profile; admins can read all
CREATE POLICY "profiles_select_own"    ON public.profiles FOR SELECT USING (id = auth.uid() OR public.get_my_role() = 'admin');
CREATE POLICY "profiles_insert_self"   ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update_own"    ON public.profiles FOR UPDATE USING (id = auth.uid() OR public.get_my_role() = 'admin');

-- ── rooms ─────────────────────────────────────────────────────
-- All authenticated users can view rooms; only admins can mutate
CREATE POLICY "rooms_select_all"   ON public.rooms FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "rooms_admin_insert" ON public.rooms FOR INSERT WITH CHECK (public.get_my_role() = 'admin');
CREATE POLICY "rooms_admin_update" ON public.rooms FOR UPDATE USING (public.get_my_role() = 'admin');
CREATE POLICY "rooms_admin_delete" ON public.rooms FOR DELETE USING (public.get_my_role() = 'admin');

-- ── fees ──────────────────────────────────────────────────────
CREATE POLICY "fees_select"   ON public.fees FOR SELECT USING (student_id = auth.uid() OR public.get_my_role() = 'admin');
CREATE POLICY "fees_insert"   ON public.fees FOR INSERT WITH CHECK (public.get_my_role() = 'admin');
CREATE POLICY "fees_update"   ON public.fees FOR UPDATE USING (student_id = auth.uid() OR public.get_my_role() = 'admin');

-- ── complaints ────────────────────────────────────────────────
CREATE POLICY "complaints_select"  ON public.complaints FOR SELECT USING (student_id = auth.uid() OR public.get_my_role() = 'admin');
CREATE POLICY "complaints_insert"  ON public.complaints FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "complaints_update"  ON public.complaints FOR UPDATE USING (student_id = auth.uid() OR public.get_my_role() = 'admin');

-- ── notices ───────────────────────────────────────────────────
CREATE POLICY "notices_select_all"    ON public.notices FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "notices_admin_insert"  ON public.notices FOR INSERT WITH CHECK (public.get_my_role() = 'admin');
CREATE POLICY "notices_admin_update"  ON public.notices FOR UPDATE USING (public.get_my_role() = 'admin');
CREATE POLICY "notices_admin_delete"  ON public.notices FOR DELETE USING (public.get_my_role() = 'admin');

-- ── gate_passes ───────────────────────────────────────────────
CREATE POLICY "gate_passes_select" ON public.gate_passes FOR SELECT USING (student_id = auth.uid() OR public.get_my_role() = 'admin');
CREATE POLICY "gate_passes_insert" ON public.gate_passes FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "gate_passes_update" ON public.gate_passes FOR UPDATE USING (public.get_my_role() = 'admin');

-- ── attendance ────────────────────────────────────────────────
CREATE POLICY "attendance_select" ON public.attendance FOR SELECT USING (student_id = auth.uid() OR public.get_my_role() = 'admin');
CREATE POLICY "attendance_admin"  ON public.attendance FOR INSERT WITH CHECK (public.get_my_role() = 'admin');

-- ============================================================
-- TRIGGER: auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated   BEFORE UPDATE ON public.profiles   FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_complaints_updated BEFORE UPDATE ON public.complaints  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- SEED DATA — Rooms (Block A + B sample)
-- ============================================================
INSERT INTO public.rooms (room_number, block, floor, room_type, capacity, occupied, status, monthly_rent, amenities) VALUES
  ('A-101','Block A',1,'single',1,1,'occupied',3000,ARRAY['wifi','study_table']),
  ('A-102','Block A',1,'single',1,1,'occupied',3000,ARRAY['wifi','study_table']),
  ('A-103','Block A',1,'single',1,0,'vacant',3000,ARRAY['wifi','study_table']),
  ('A-104','Block A',1,'double',2,2,'occupied',2500,ARRAY['wifi']),
  ('A-105','Block A',1,'double',2,1,'occupied',2500,ARRAY['wifi']),
  ('A-201','Block A',2,'single',1,0,'maintenance',3000,ARRAY['wifi','ac','study_table']),
  ('A-202','Block A',2,'single',1,1,'occupied',3500,ARRAY['wifi','ac','study_table']),
  ('A-203','Block A',2,'double',2,2,'occupied',2800,ARRAY['wifi','ac']),
  ('B-101','Block B',1,'single',1,1,'occupied',3000,ARRAY['wifi','study_table','attached_bath']),
  ('B-102','Block B',1,'single',1,1,'occupied',3000,ARRAY['wifi','study_table','attached_bath']),
  ('B-103','Block B',1,'single',1,0,'vacant',3000,ARRAY['wifi','study_table','attached_bath']),
  ('B-201','Block B',2,'single',1,1,'occupied',3200,ARRAY['wifi','ac','study_table','attached_bath']),
  ('B-202','Block B',2,'single',1,1,'occupied',3200,ARRAY['wifi','ac','study_table','attached_bath']),
  ('B-203','Block B',2,'single',1,0,'vacant',3200,ARRAY['wifi','ac','study_table','attached_bath']),
  ('B-204','Block B',2,'single',1,1,'occupied',3200,ARRAY['wifi','ac','study_table','attached_bath'])
ON CONFLICT DO NOTHING;
