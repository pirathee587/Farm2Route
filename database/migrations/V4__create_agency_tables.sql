-- V4__create_agency_tables.sql
-- Logistics Agency Profiles Table

CREATE TABLE IF NOT EXISTS agency_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(150) NOT NULL,
    business_registration_number VARCHAR(100) NOT NULL UNIQUE,
    tax_identification_number VARCHAR(100),
    office_address VARCHAR(255) NOT NULL,
    district VARCHAR(100) NOT NULL,
    contact_person_name VARCHAR(150) NOT NULL,
    contact_person_phone VARCHAR(30) NOT NULL,
    kyc_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    kyc_document_url VARCHAR(500),
    kyc_rejection_reason TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    commission_rate_percentage DECIMAL(5, 2) DEFAULT 10.00,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agency_kyc_status ON agency_profiles(kyc_status);
