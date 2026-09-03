-- V18__enhance_incident_tables.sql
-- Enhance incident_reports and incident_evidence with farmer profile link, indexes, and Member 3 admin resolution placeholders

-- Make title nullable so it can be auto-generated or optional
ALTER TABLE incident_reports ALTER COLUMN title DROP NOT NULL;

-- Link directly to farmer profile (in addition to reported_by_user_id)
ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES farmer_profiles(id) ON DELETE SET NULL;

-- Add Member 3 Admin Lifecycle & Moderation fields (reserved for Member 3 write-side)
ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS investigation_notes TEXT;
ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS resolution_outcome VARCHAR(100);
ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS refund_amount NUMERIC(12, 2);

-- Add photo_url alias column to incident_evidence for flexible property mapping
ALTER TABLE incident_evidence ADD COLUMN IF NOT EXISTS photo_url VARCHAR(500);

-- Make file_type optional if not explicitly provided
ALTER TABLE incident_evidence ALTER COLUMN file_type DROP NOT NULL;

-- Add performance indexes for farmer and admin lookups
CREATE INDEX IF NOT EXISTS idx_incidents_farmer ON incident_reports(farmer_id);
CREATE INDEX IF NOT EXISTS idx_incidents_reporter_status ON incident_reports(reported_by_user_id, status);
CREATE INDEX IF NOT EXISTS idx_incidents_farmer_status ON incident_reports(farmer_id, status);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incident_reports(created_at DESC);
