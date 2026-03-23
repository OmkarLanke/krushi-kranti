-- V14__add_performance_indexes.sql
-- Performance indexes for faster queries on frequently accessed columns

-- Farmers table indexes
CREATE INDEX IF NOT EXISTS idx_farmers_user_id ON farmers(user_id);
CREATE INDEX IF NOT EXISTS idx_farmers_is_active ON farmers(is_active);
CREATE INDEX IF NOT EXISTS idx_farmers_state ON farmers(state);
CREATE INDEX IF NOT EXISTS idx_farmers_district ON farmers(district);
CREATE INDEX IF NOT EXISTS idx_farmers_created_at ON farmers(created_at DESC);

-- Composite indexes for common filter combinations
CREATE INDEX IF NOT EXISTS idx_farmers_state_district ON farmers(state, district);
CREATE INDEX IF NOT EXISTS idx_farmers_active_created ON farmers(is_active, created_at DESC);

-- Farms table indexes
CREATE INDEX IF NOT EXISTS idx_farms_farmer_id ON farms(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farms_is_verified ON farms(is_verified);
CREATE INDEX IF NOT EXISTS idx_farms_state ON farms(state);
CREATE INDEX IF NOT EXISTS idx_farms_district ON farms(district);

-- Crops table indexes
CREATE INDEX IF NOT EXISTS idx_crops_farm_id ON crops(farm_id);
CREATE INDEX IF NOT EXISTS idx_crops_status ON crops(status);
CREATE INDEX IF NOT EXISTS idx_crops_sowing_date ON crops(sowing_date DESC);

-- Pincode master indexes (for location lookups)
CREATE INDEX IF NOT EXISTS idx_pincode_master_pincode ON pincode_master(pincode);
CREATE INDEX IF NOT EXISTS idx_pincode_master_state ON pincode_master(state_name);
CREATE INDEX IF NOT EXISTS idx_pincode_master_district ON pincode_master(district);
