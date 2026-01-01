-- Repair Flyway checksum for migration V6
-- This updates the checksum in flyway_schema_history to match the current migration file

-- First, check if the migration was already applied
-- If the column was already renamed, we just need to update the checksum
-- If not, we need to delete the record and let Flyway run it

-- Option 1: If migration V6 was already applied but checksum is wrong
-- Update the checksum to match the current file (1581828465)
UPDATE flyway_schema_history 
SET checksum = 1581828465 
WHERE version = '6' AND description LIKE '%rename_farmer_user_id%';

-- Option 2: If migration V6 was partially applied or incorrectly recorded
-- Delete the record and let Flyway run it fresh
-- DELETE FROM flyway_schema_history WHERE version = '6';

-- After running this, restart the service and Flyway will validate correctly
