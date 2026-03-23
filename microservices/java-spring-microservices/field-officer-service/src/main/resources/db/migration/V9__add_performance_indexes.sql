-- V9__add_performance_indexes.sql
-- Performance indexes for faster queries on frequently accessed columns

-- Field officers table indexes
CREATE INDEX IF NOT EXISTS idx_field_officers_user_id ON field_officers(user_id);
CREATE INDEX IF NOT EXISTS idx_field_officers_is_active ON field_officers(is_active);
CREATE INDEX IF NOT EXISTS idx_field_officers_state ON field_officers(state);
CREATE INDEX IF NOT EXISTS idx_field_officers_district ON field_officers(district);
CREATE INDEX IF NOT EXISTS idx_field_officers_created_at ON field_officers(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_field_officers_state_district ON field_officers(state, district);
CREATE INDEX IF NOT EXISTS idx_field_officers_active_created ON field_officers(is_active, created_at DESC);

-- Assignments table indexes
CREATE INDEX IF NOT EXISTS idx_assignments_field_officer_id ON field_officer_assignments(field_officer_id);
CREATE INDEX IF NOT EXISTS idx_assignments_farmer_id ON field_officer_assignments(farmer_id);
CREATE INDEX IF NOT EXISTS idx_assignments_farm_id ON field_officer_assignments(farm_id);
CREATE INDEX IF NOT EXISTS idx_assignments_status ON field_officer_assignments(status);
CREATE INDEX IF NOT EXISTS idx_assignments_created_at ON field_officer_assignments(created_at DESC);

-- Farm verifications table indexes
CREATE INDEX IF NOT EXISTS idx_verifications_assignment_id ON farm_verifications(assignment_id);
CREATE INDEX IF NOT EXISTS idx_verifications_status ON farm_verifications(verification_status);
CREATE INDEX IF NOT EXISTS idx_verifications_created_at ON farm_verifications(created_at DESC);
