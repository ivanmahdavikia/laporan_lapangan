-- ===========================================
-- SUPABASE SQL SETUP
-- Jalankan di Supabase SQL Editor
-- ===========================================

-- Table: reports
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  location TEXT NOT NULL DEFAULT '',
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  inspector_name TEXT NOT NULL DEFAULT '',
  reference_id TEXT NOT NULL DEFAULT '',
  photos_per_page INTEGER NOT NULL DEFAULT 8,
  status TEXT NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: report_photos
CREATE TABLE IF NOT EXISTS report_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  local_path TEXT NOT NULL DEFAULT '',
  storage_url TEXT,
  caption TEXT NOT NULL DEFAULT '',
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_report_photos_report_id ON report_photos(report_id);
CREATE INDEX IF NOT EXISTS idx_report_photos_order ON report_photos(report_id, order_index);

-- ===========================================
-- STORAGE BUCKET
-- Buat bucket di Supabase Dashboard > Storage
-- Nama: report-photos
-- Public: Yes (agar bisa diakses via URL)
-- ===========================================

-- RLS (Row Level Security) - Disable untuk development
-- Aktifkan kembali untuk production
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_photos ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all operations (untuk development)
CREATE POLICY "Allow all on reports" ON reports FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on report_photos" ON report_photos FOR ALL USING (true) WITH CHECK (true);
