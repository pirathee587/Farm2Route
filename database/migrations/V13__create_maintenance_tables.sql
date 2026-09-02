-- V13__create_maintenance_tables.sql
-- Vehicle Maintenance Records Table

CREATE TABLE IF NOT EXISTS vehicle_maintenance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    maintenance_type VARCHAR(50) NOT NULL, -- ROUTINE_SERVICE, TIRE_CHANGE, ENGINE_REPAIR, BRAKE_SERVICE, INSPECTION, OTHER
    title VARCHAR(150) NOT NULL,
    description TEXT,
    cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    maintenance_date DATE NOT NULL,
    next_due_date DATE,
    service_center_name VARCHAR(150),
    invoice_document_url VARCHAR(500),
    status VARCHAR(30) NOT NULL DEFAULT 'COMPLETED', -- SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_maintenance_vehicle ON vehicle_maintenance(vehicle_id);
CREATE INDEX idx_maintenance_status ON vehicle_maintenance(status);
