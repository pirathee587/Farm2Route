-- V12__create_review_tables.sql
-- Reviews and Moderation Table

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    farmer_id UUID NOT NULL REFERENCES farmer_profiles(id) ON DELETE CASCADE,
    agency_id UUID NOT NULL REFERENCES agency_profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES driver_profiles(id) ON DELETE SET NULL,
    
    agency_rating INT NOT NULL CHECK (agency_rating >= 1 AND agency_rating <= 5),
    driver_rating INT CHECK (driver_rating >= 1 AND driver_rating <= 5),
    comment TEXT,
    agency_response TEXT,
    agency_responded_at TIMESTAMP WITH TIME ZONE,
    
    moderation_status VARCHAR(30) NOT NULL DEFAULT 'APPROVED', -- APPROVED, PENDING_REVIEW, HIDDEN
    moderated_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_agency ON reviews(agency_id);
CREATE INDEX idx_reviews_driver ON reviews(driver_id);
CREATE INDEX idx_reviews_farmer ON reviews(farmer_id);
