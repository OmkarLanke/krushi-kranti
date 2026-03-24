-- Additional composite/ordering indexes not covered by earlier migrations

CREATE INDEX IF NOT EXISTS idx_farmers_created_at ON farmers(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_farmers_state_district ON farmers(state, district);
