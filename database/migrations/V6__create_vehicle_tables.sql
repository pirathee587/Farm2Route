-- V6__create_vehicle_tables.sql
-- Vehicles Table

CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_id UUID NOT NULL REFERENCES agency_profiles(id) ON DELETE CASCADE,
    assigned_driver_id UUID REFERENCES driver_profiles(id) ON DELETE SET NULL,
    vehicle_registration_number VARCHAR(50) NOT NULL UNIQUE,
    vehicle_type VARCHAR(50) NOT NULL, -- TRUCK, VAN, LORRY, TRACTOR, FREEZER_TRUCK
    make_and_model VARCHAR(100) NOT NULL,
    max_payload_weight_kg DECIMAL(10, 2) NOT NULL,
    max_cargo_volume_cbm DECIMAL(10, 2) NOT NULL,
    is_refrigerated BOOLEAN NOT NULL DEFAULT FALSE,
    insurance_policy_number VARCHAR(100),
    insurance_expiry_date DATE NOT NULL,
    revenue_license_number VARCHAR(100),
    revenue_license_expiry_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE, IN_USE, UNDER_MAINTENANCE, INACTIVE
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vehicle_agency ON vehicles(agency_id);
CREATE INDEX idx_vehicle_status ON vehicles(status);
