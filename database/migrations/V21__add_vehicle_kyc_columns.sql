-- V18__add_vehicle_kyc_columns.sql
-- KYC fields required for vehicle review

ALTER TABLE vehicles
    ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_APPROVAL',
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
    ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_vehicle_kyc_status ON vehicles(kyc_status);