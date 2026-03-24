-- Additional composite/ordering indexes not covered by earlier migrations

CREATE INDEX IF NOT EXISTS idx_field_officers_state_district ON field_officers(state, district);
CREATE INDEX IF NOT EXISTS idx_field_officers_active_created ON field_officers(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_assignments_created_at ON field_officer_assignments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_verifications_created_at ON farm_verifications(created_at DESC);
