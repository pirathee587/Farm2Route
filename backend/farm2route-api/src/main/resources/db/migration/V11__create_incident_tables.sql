-- V11__create_incident_tables.sql
-- Incident Reports and Evidence Files Tables

CREATE TABLE IF NOT EXISTS incident_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    reported_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    incident_type VARCHAR(50) NOT NULL, -- ACCIDENT, CARGO_DAMAGE, DELAY, THEFT, BREAKDOWN, OTHER
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN', -- OPEN, INVESTIGATING, RESOLVED, REJECTED
    admin_notes TEXT,
    resolved_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_incidents_booking ON incident_reports(booking_id);
CREATE INDEX idx_incidents_status ON incident_reports(status);
CREATE INDEX idx_incidents_reporter ON incident_reports(reported_by_user_id);

CREATE TABLE IF NOT EXISTS incident_evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID NOT NULL REFERENCES incident_reports(id) ON DELETE CASCADE,
    file_url VARCHAR(500) NOT NULL,
    file_type VARCHAR(50) NOT NULL, -- IMAGE, VIDEO, DOCUMENT
    caption VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_evidence_incident ON incident_evidence(incident_id);
