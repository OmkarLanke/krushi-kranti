-- ============================================
-- Fix Flyway checksum mismatch for V12 migration
-- Run this script in farmer_db database
-- ============================================

-- Option 1: Delete V12 record and let it re-run (since migration is now idempotent)
-- This is safe because the migration checks if columns exist before renaming
DELETE FROM flyway_schema_history WHERE version = '12';

-- Option 2: Update checksum to match new file (current checksum: 1742716602)
-- Uncomment and use this if you prefer to keep the migration as "already applied"
UPDATE flyway_schema_history 
SET checksum = 1742716602 
WHERE version = '12';

-- Verify the change
SELECT version, description, checksum, installed_on, success 
FROM flyway_schema_history 
WHERE version = '12';
