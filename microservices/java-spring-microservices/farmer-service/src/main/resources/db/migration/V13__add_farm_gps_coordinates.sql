-- ============================================
-- Add GPS coordinates to farms table
-- This migration adds GPS location fields to support farm verification
-- ============================================

-- Add GPS coordinate columns to farms table
ALTER TABLE farms 
    ADD COLUMN IF NOT EXISTS farm_latitude DECIMAL(10, 8),
    ADD COLUMN IF NOT EXISTS farm_longitude DECIMAL(11, 8),
    ADD COLUMN IF NOT EXISTS farm_location_accuracy DECIMAL(8, 2),
    ADD COLUMN IF NOT EXISTS farm_location_captured_at TIMESTAMP;

-- Add index for GPS-based queries (useful for location-based searches)
CREATE INDEX IF NOT EXISTS idx_farms_gps_coordinates ON farms(farm_latitude, farm_longitude) 
    WHERE farm_latitude IS NOT NULL AND farm_longitude IS NOT NULL;

-- Add comment to columns for documentation
COMMENT ON COLUMN farms.farm_latitude IS 'GPS latitude of the farm location captured by farmer (decimal degrees)';
COMMENT ON COLUMN farms.farm_longitude IS 'GPS longitude of the farm location captured by farmer (decimal degrees)';
COMMENT ON COLUMN farms.farm_location_accuracy IS 'GPS accuracy in meters when location was captured';
COMMENT ON COLUMN farms.farm_location_captured_at IS 'Timestamp when GPS coordinates were captured by farmer';

