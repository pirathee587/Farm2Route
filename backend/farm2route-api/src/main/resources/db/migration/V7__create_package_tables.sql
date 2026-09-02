-- V7__create_package_tables.sql
-- Logistics Packages / Service Offerings Table

CREATE TABLE IF NOT EXISTS packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_id UUID NOT NULL REFERENCES agency_profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    package_type VARCHAR(50) NOT NULL, -- STANDARD, EXPRESS, COLD_CHAIN, BULK_AGRICULTURAL
    base_price DECIMAL(10, 2) NOT NULL,
    price_per_km DECIMAL(10, 2) NOT NULL,
    price_per_kg DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    max_weight_kg DECIMAL(10, 2) NOT NULL,
    route_origin VARCHAR(100),
    route_destination VARCHAR(100),
    schedule_days TEXT[], -- e.g. ['MONDAY', 'WEDNESDAY', 'FRIDAY']
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_packages_agency ON packages(agency_id);
CREATE INDEX idx_packages_type ON packages(package_type);
CREATE INDEX idx_packages_active ON packages(is_active);
