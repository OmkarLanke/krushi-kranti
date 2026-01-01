-- Fix Flyway checksum mismatch for migration V6
-- Run this SQL directly in your PostgreSQL database (field_officer_db)

-- Connect to the database first:
-- psql -h localhost -p 5453 -U postgres -d field_officer_db

-- Update the checksum for migration V6 to match the current file
UPDATE flyway_schema_history 
SET checksum = 1581828465 
WHERE version = '6';

-- Verify the update
SELECT version, description, checksum, installed_on 
FROM flyway_schema_history 
WHERE version = '6';

-- If the above doesn't work, you can delete the record and let Flyway re-run it:
-- DELETE FROM flyway_schema_history WHERE version = '6';
