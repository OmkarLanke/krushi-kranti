-- ============================================
-- Rename users.id to user_id to match Java entity
-- This migration is idempotent - it only runs if column 'id' exists
-- For fresh databases (where V1 already creates user_id), this does nothing
-- ============================================

-- Step 1: Rename primary key column in users table (only if it exists as 'id')
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
        RAISE NOTICE 'Renamed users.id to user_id';
    ELSE
        RAISE NOTICE 'Column user_id already exists, skipping rename';
    END IF;
END $$;

-- Step 2: Update foreign key constraint in refresh_tokens table
-- First, drop any existing foreign key constraints that might reference the old column name
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find and drop any foreign key constraint on refresh_tokens.user_id that references users
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'refresh_tokens'::regclass
        AND contype = 'f'
        AND confrelid = 'users'::regclass
    LOOP
        EXECUTE 'ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Recreate the foreign key constraint with the correct column name
-- This will work whether the column was just renamed or already exists as user_id
ALTER TABLE refresh_tokens ADD CONSTRAINT refresh_tokens_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- Step 3: Update indexes that reference the column
DROP INDEX IF EXISTS idx_refresh_tokens_user_id;
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
