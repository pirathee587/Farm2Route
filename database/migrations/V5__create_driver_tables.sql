-- V5__create_driver_tables.sql
-- Driver Profiles Table

CREATE TABLE IF NOT EXISTS driver_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    agency_id UUID NOT NULL REFERENCES agency_profiles(id) ON DELETE CASCADE,
    driving_license_number VARCHAR(100) NOT NULL UNIQUE,
    license_expiry_date DATE NOT NULL,
    nic_number VARCHAR(50) NOT NULL UNIQUE,
    kyc_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    kyc_document_url VARCHAR(500),
    kyc_rejection_reason TEXT,
    availability_status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE, ON_TRIP, OFF_DUTY, INACTIVE
    rating_average DECIMAL(3, 2) DEFAULT 5.00,
    total_ratings_count INT DEFAULT 0,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_driver_agency ON driver_profiles(agency_id);
CREATE INDEX idx_driver_availability ON driver_profiles(availability_status);
CREATE INDEX idx_driver_kyc ON driver_profiles(kyc_status);
