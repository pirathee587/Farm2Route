-- V28__create_farmers_table.sql
-- Farmers and Farmer Crops join table for light-touch Farmer Onboarding

CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(255) NOT NULL,
    nic_number VARCHAR(50) UNIQUE,
    phone_number VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255),
    district VARCHAR(100) NOT NULL,
    gn_division VARCHAR(100),
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    farm_size_acres DECIMAL(10, 2),
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'TA',
    bank_account_number VARCHAR(50),
    mobile_wallet_number VARCHAR(50),
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_farmer_status CHECK (status IN ('PENDING', 'ACTIVE')),
    CONSTRAINT chk_preferred_language CHECK (preferred_language IN ('TA', 'SI', 'EN'))
);

CREATE INDEX IF NOT EXISTS idx_farmers_phone ON farmers(phone_number);
CREATE INDEX IF NOT EXISTS idx_farmers_status ON farmers(status);
CREATE INDEX IF NOT EXISTS idx_farmers_district ON farmers(district);

-- Join table for primary crops
CREATE TABLE IF NOT EXISTS farmer_crops (
    farmer_id UUID NOT NULL,
    crop_type VARCHAR(50) NOT NULL,
    CONSTRAINT pk_farmer_crops PRIMARY KEY (farmer_id, crop_type),
    CONSTRAINT fk_farmer_crops_farmer FOREIGN KEY (farmer_id) REFERENCES farmers(id) ON DELETE CASCADE,
    CONSTRAINT chk_crop_type CHECK (crop_type IN ('VEGETABLES', 'FRUITS', 'GRAINS', 'DAIRY', 'OTHER'))
);

CREATE INDEX IF NOT EXISTS idx_farmer_crops_farmer_id ON farmer_crops(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_crops_crop_type ON farmer_crops(crop_type);
