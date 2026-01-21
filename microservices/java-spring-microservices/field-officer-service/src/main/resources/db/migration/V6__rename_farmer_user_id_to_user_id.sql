-- ============================================
-- Rename farmer_user_id column to user_id in field_officer_assignments table
-- This migration is idempotent - it only renames if farmer_user_id exists
-- For fresh databases (where V2 already creates user_id), this does nothing
-- ============================================

DO $$
BEGIN
    -- Check if farmer_user_id exists and needs to be renamed
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'field_officer_assignments' 
        AND column_name = 'farmer_user_id' 
        AND table_schema = 'public'
    ) THEN
        -- Rename the column
        ALTER TABLE field_officer_assignments 
        RENAME COLUMN farmer_user_id TO user_id;
        RAISE NOTICE 'Renamed farmer_user_id to user_id';
        
        -- Drop the old index
        DROP INDEX IF EXISTS idx_assignments_farmer_user_id;
        
        -- Drop the old unique constraint/index before handling duplicates
        DROP INDEX IF EXISTS idx_assignments_unique;
        
        -- Handle duplicate assignments: Keep the most recent one, cancel older duplicates
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
        CREATE INDEX IF NOT EXISTS idx_assignments_user_id ON field_officer_assignments(user_id);
        
        -- Recreate the unique constraint with the new column name
        CREATE UNIQUE INDEX IF NOT EXISTS idx_assignments_unique 
        ON field_officer_assignments(field_officer_id, user_id) 
        WHERE status != 'CANCELLED';
    ELSE
        RAISE NOTICE 'Column user_id already exists, skipping rename';
        
        -- Ensure indexes exist even if no rename needed
        DROP INDEX IF EXISTS idx_assignments_farmer_user_id;
        CREATE INDEX IF NOT EXISTS idx_assignments_user_id ON field_officer_assignments(user_id);
        
        -- Ensure unique constraint exists
        DROP INDEX IF EXISTS idx_assignments_unique;
        CREATE UNIQUE INDEX IF NOT EXISTS idx_assignments_unique 
        ON field_officer_assignments(field_officer_id, user_id) 
        WHERE status != 'CANCELLED';
    END IF;
END $$;
