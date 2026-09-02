-- V14__create_notification_tables.sql
-- In-app Notifications Table

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- BOOKING_UPDATE, TRIP_DISPATCH, POD_SUBMITTED, INCIDENT_ALERT, KYC_STATUS, PAYMENT, SYSTEM
    reference_type VARCHAR(50), -- BOOKING, TRIP, INCIDENT, TRANSACTION
    reference_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
