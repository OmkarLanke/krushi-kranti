-- Fix Flyway V6 migration issue
-- The migration was marked as applied but didn't actually run
-- This script will delete the record so Flyway can run it properly

-- Step 1: Delete the V6 record from Flyway history
DELETE FROM flyway_schema_history WHERE version = '6';

-- Step 2: Verify current column name (should be farmer_user_id)
-- Run this to check:
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'field_officer_assignments' AND column_name IN ('farmer_user_id', 'user_id');

-- After running this DELETE statement, restart the service.
-- Flyway will execute the V6 migration and rename the column from farmer_user_id to user_id.
