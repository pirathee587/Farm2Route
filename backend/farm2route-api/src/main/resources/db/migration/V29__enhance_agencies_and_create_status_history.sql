-- V29__enhance_agencies_and_create_status_history.sql
-- Enhance agencies table with business registration, banking, audit, and verification fields
-- Create agency_status_history table for immutable state audit logging

ALTER TABLE agencies
    ADD COLUMN IF NOT EXISTS business_reg_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS business_reg_expiry_date DATE,
    ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100),
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
    ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS rejected_by UUID,
    ADD COLUMN IF NOT EXISTS email_verification_token VARCHAR(255),
    ADD COLUMN IF NOT EXISTS email_verification_expires_at TIMESTAMP WITH TIME ZONE;

CREATE UNIQUE INDEX IF NOT EXISTS uq_agencies_business_reg_number
    ON agencies(business_reg_number)
    WHERE business_reg_number IS NOT NULL;

-- Agency Status History Audit Trail
CREATE TABLE IF NOT EXISTS agency_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_agency_status_history_agency_id
    ON agency_status_history(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_status_history_changed_at
    ON agency_status_history(changed_at);
