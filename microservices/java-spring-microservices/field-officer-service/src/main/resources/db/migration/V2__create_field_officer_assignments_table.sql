-- Create field_officer_assignments table
CREATE TABLE IF NOT EXISTS field_officer_assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    field_officer_id BIGINT NOT NULL,
    farmer_user_id BIGINT NOT NULL, -- Links to auth.users.id (farmer)
    status VARCHAR(20) DEFAULT 'ASSIGNED' CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    assigned_by_user_id BIGINT, -- Admin who assigned
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    notes VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_assignments_field_officer_id ON field_officer_assignments(field_officer_id);
CREATE INDEX idx_assignments_farmer_user_id ON field_officer_assignments(farmer_user_id);
CREATE INDEX idx_assignments_status ON field_officer_assignments(status);
CREATE UNIQUE INDEX idx_assignments_unique ON field_officer_assignments(field_officer_id, farmer_user_id) WHERE status != 'CANCELLED';

