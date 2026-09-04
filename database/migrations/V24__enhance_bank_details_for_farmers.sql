-- V24__enhance_bank_details_for_farmers.sql
-- Add farmer_id, account_type, branch_code and relax branch_name constraint for Farmer Bank Details

ALTER TABLE bank_details
    ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES farmer_profiles(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS account_type VARCHAR(30) NOT NULL DEFAULT 'SAVINGS',
    ADD COLUMN IF NOT EXISTS branch_code VARCHAR(30);

ALTER TABLE bank_details
    ALTER COLUMN branch_name DROP NOT NULL;

ALTER TABLE bank_details
    ALTER COLUMN user_id DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bank_details_farmer_id
    ON bank_details(farmer_id)
    WHERE farmer_id IS NOT NULL;
