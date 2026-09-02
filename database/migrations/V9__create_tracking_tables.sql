-- V9__create_tracking_tables.sql
-- Trip Assignments and Live GPS Tracking Tables

CREATE TABLE IF NOT EXISTS trip_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES driver_profiles(id) ON DELETE RESTRICT,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL DEFAULT 'ASSIGNED', -- ASSIGNED, STARTED, AT_PICKUP, LOADED, IN_TRANSIT, COMPLETED, CANCELLED
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trips_booking ON trip_assignments(booking_id);
CREATE INDEX idx_trips_driver ON trip_assignments(driver_id);

CREATE TABLE IF NOT EXISTS gps_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trip_assignments(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES driver_profiles(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed_kmh DECIMAL(5, 2),
    heading_degrees DECIMAL(5, 2),
    accuracy_meters DECIMAL(5, 2),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gps_trip_recorded ON gps_locations(trip_id, recorded_at DESC);
CREATE INDEX idx_gps_booking ON gps_locations(booking_id);
