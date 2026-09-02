-- V8__create_booking_tables.sql
-- Bookings Table

CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_number VARCHAR(50) NOT NULL UNIQUE,
    farmer_id UUID NOT NULL REFERENCES farmer_profiles(id) ON DELETE RESTRICT,
    agency_id UUID NOT NULL REFERENCES agency_profiles(id) ON DELETE RESTRICT,
    package_id UUID REFERENCES packages(id) ON DELETE SET NULL,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    driver_id UUID REFERENCES driver_profiles(id) ON DELETE SET NULL,
    
    pickup_address VARCHAR(255) NOT NULL,
    pickup_latitude DECIMAL(10, 8) NOT NULL,
    pickup_longitude DECIMAL(11, 8) NOT NULL,
    pickup_contact_name VARCHAR(150),
    pickup_contact_phone VARCHAR(30),
    
    delivery_address VARCHAR(255) NOT NULL,
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    recipient_name VARCHAR(150) NOT NULL,
    recipient_phone VARCHAR(30) NOT NULL,
    
    cargo_type VARCHAR(100) NOT NULL,
    cargo_weight_kg DECIMAL(10, 2) NOT NULL,
    cargo_volume_cbm DECIMAL(10, 2),
    is_fragile BOOLEAN NOT NULL DEFAULT FALSE,
    requires_refrigeration BOOLEAN NOT NULL DEFAULT FALSE,
    special_instructions TEXT,
    
    estimated_distance_km DECIMAL(10, 2),
    total_amount DECIMAL(10, 2) NOT NULL,
    commission_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    agency_earnings DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING', 
    -- PENDING, ACCEPTED, REJECTED, DRIVER_ASSIGNED, IN_TRANSIT, DELIVERED, CANCELLED
    
    scheduled_pickup_at TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_pickup_at TIMESTAMP WITH TIME ZONE,
    actual_delivery_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES users(id),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bookings_farmer ON bookings(farmer_id);
CREATE INDEX idx_bookings_agency ON bookings(agency_id);
CREATE INDEX idx_bookings_driver ON bookings(driver_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_number ON bookings(booking_number);
