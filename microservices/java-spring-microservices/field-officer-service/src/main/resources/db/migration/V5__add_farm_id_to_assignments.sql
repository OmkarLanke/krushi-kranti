-- Add farm_id column to field_officer_assignments table
-- This allows assignments to be per-farm instead of per-farmer
ALTER TABLE field_officer_assignments 
ADD COLUMN IF NOT EXISTS farm_id BIGINT;

-- Create index for farm_id lookups
CREATE INDEX IF NOT EXISTS idx_assignments_farm_id ON field_officer_assignments(farm_id);

-- Update unique constraint to include farm_id
-- Remove old unique index
DROP INDEX IF EXISTS idx_assignments_unique;

-- Create new unique index with farm_id
-- One farm can only be assigned to one field officer at a time (active assignments)
CREATE UNIQUE INDEX idx_assignments_farm_unique 
ON field_officer_assignments(farm_id) 
WHERE status != 'CANCELLED' AND farm_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN field_officer_assignments.farm_id IS 'Farm ID from farmer-service farms table. If NULL, assignment is for all farms of the farmer.';

