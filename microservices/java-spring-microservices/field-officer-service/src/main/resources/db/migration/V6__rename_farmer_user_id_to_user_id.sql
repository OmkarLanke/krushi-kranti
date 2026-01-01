-- Rename farmer_user_id column to user_id in field_officer_assignments table
ALTER TABLE field_officer_assignments 
RENAME COLUMN farmer_user_id TO user_id;

-- Drop the old index
DROP INDEX IF EXISTS idx_assignments_farmer_user_id;

-- Drop the old unique constraint/index before handling duplicates
DROP INDEX IF EXISTS idx_assignments_unique;

-- Handle duplicate assignments: Keep the most recent one, cancel older duplicates
-- For each (field_officer_id, user_id) pair, keep only the assignment with the latest assigned_at
-- and cancel all other duplicates where status != 'CANCELLED'
UPDATE field_officer_assignments
SET status = 'CANCELLED',
    updated_at = CURRENT_TIMESTAMP
WHERE assignment_id NOT IN (
    SELECT DISTINCT ON (field_officer_id, user_id) assignment_id
    FROM field_officer_assignments
    WHERE status != 'CANCELLED'
    ORDER BY field_officer_id, user_id, assigned_at DESC
)
AND status != 'CANCELLED';

-- Recreate the index with the new column name
CREATE INDEX idx_assignments_user_id ON field_officer_assignments(user_id);

-- Recreate the unique constraint with the new column name
CREATE UNIQUE INDEX idx_assignments_unique 
ON field_officer_assignments(field_officer_id, user_id) 
WHERE status != 'CANCELLED';
