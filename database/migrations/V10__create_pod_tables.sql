-- V10__create_pod_tables.sql
-- Proof of Delivery (POD) Records Table

CREATE TABLE IF NOT EXISTS pod_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES driver_profiles(id) ON DELETE RESTRICT,
    recipient_name VARCHAR(150) NOT NULL,
    recipient_phone VARCHAR(30) NOT NULL,
    recipient_signature_url VARCHAR(500) NOT NULL,
    delivery_photo_url VARCHAR(500) NOT NULL,
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    delivery_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    farmer_confirmation_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, DISPUTED
    farmer_confirmed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pod_booking ON pod_records(booking_id);
CREATE INDEX idx_pod_driver ON pod_records(driver_id);
