-- ============================================
-- Rename users.id to user_id to match Java entity
-- This migration fixes the mismatch between database schema and Java entities
-- ============================================

-- Step 1: Rename primary key column in users table (only if it exists as 'id')
-- Use DO block to conditionally rename the column
DO $$
BEGIN
    -- Check if column 'id' exists and rename it to 'user_id'
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users RENAME COLUMN id TO user_id;
    END IF;
END $$;

-- Step 2: Update foreign key constraint in refresh_tokens table
-- First, drop any existing foreign key constraints that might reference the old column name
-- Check for constraints that reference users table
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find and drop any foreign key constraint on refresh_tokens.user_id
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'refresh_tokens'::regclass
        AND contype = 'f'
        AND confrelid = 'users'::regclass
    LOOP
        EXECUTE 'ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS ' || constraint_name;
    END LOOP;
END $$;

-- Recreate the foreign key constraint with the correct column name
-- This will work whether the column was just renamed or already exists as user_id
ALTER TABLE refresh_tokens ADD CONSTRAINT refresh_tokens_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- Step 3: Update indexes that reference the column
-- The index idx_refresh_tokens_user_id should automatically work with the column name
-- But we'll recreate it to be safe
DROP INDEX IF EXISTS idx_refresh_tokens_user_id;
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
