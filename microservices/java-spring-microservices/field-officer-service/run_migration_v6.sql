-- Step 1: Delete the V6 record from Flyway history so it can run properly
DELETE FROM flyway_schema_history WHERE version = '6';

-- Step 2: Verify the column still exists as farmer_user_id (it should)
-- You can check with: SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'field_officer_assignments' AND column_name IN ('farmer_user_id', 'user_id');

-- After running this, restart the service and Flyway will execute V6 migration properly
