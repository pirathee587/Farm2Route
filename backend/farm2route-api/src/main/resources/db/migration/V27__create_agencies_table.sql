-- V27__create_agencies_table.sql
-- Agencies Table for Independent Agency Accounts and Signup

CREATE TABLE IF NOT EXISTS agencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) NOT NULL UNIQUE,
    agency_type VARCHAR(50) NOT NULL,
    district VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    contact_person_name VARCHAR(150),
    status VARCHAR(50) NOT NULL DEFAULT 'ACCOUNT_CREATED',
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_agency_type CHECK (agency_type IN ('INDIVIDUAL', 'COMPANY', 'PARTNERSHIP')),
    CONSTRAINT chk_agency_status CHECK (status IN ('ACCOUNT_CREATED', 'PENDING_VERIFICATION', 'APPROVED', 'REJECTED'))
);

CREATE INDEX IF NOT EXISTS idx_agencies_email ON agencies(email);
CREATE INDEX IF NOT EXISTS idx_agencies_phone ON agencies(phone_number);
CREATE INDEX IF NOT EXISTS idx_agencies_status ON agencies(status);
