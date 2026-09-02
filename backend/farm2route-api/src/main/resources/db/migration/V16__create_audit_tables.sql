-- V16__create_audit_tables.sql
-- System-wide Audit Trail Logs Table

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    actor_role VARCHAR(50),
    action VARCHAR(100) NOT NULL, -- USER_LOGIN, USER_LOGOUT, KYC_APPROVED, BOOKING_STATUS_CHANGED, etc.
    entity_name VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(50),
    user_agent VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_actor ON audit_logs(actor_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_entity ON audit_logs(entity_name, entity_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
