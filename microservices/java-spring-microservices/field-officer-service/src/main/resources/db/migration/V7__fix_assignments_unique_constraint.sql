-- ============================================
-- Fix unique constraint to allow same field officer to be assigned to multiple farms of same farmer
-- The constraint should only apply when farm_id IS NULL (all-farms assignment)
-- When farm_id IS NOT NULL, multiple assignments are allowed (one per farm)
-- ============================================

-- Drop the old unique constraint that prevents multiple farm assignments
DROP INDEX IF EXISTS idx_assignments_unique;

-- Create new unique constraint that only applies when farm_id IS NULL
-- This allows:
-- - Multiple assignments for same (field_officer_id, user_id) when farm_id IS NOT NULL (different farms)
-- - Only one assignment for same (field_officer_id, user_id) when farm_id IS NULL (all-farms assignment)
CREATE UNIQUE INDEX IF NOT EXISTS idx_assignments_unique 
ON field_officer_assignments(field_officer_id, user_id) 
WHERE status != 'CANCELLED' AND farm_id IS NULL;

-- The idx_assignments_farm_unique constraint (from V5) already ensures:
-- - One farm can only be assigned to one field officer at a time (when farm_id IS NOT NULL)
-- This works together with the new constraint above
