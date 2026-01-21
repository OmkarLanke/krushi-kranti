-- Remove REJECTED status from verification_status CHECK constraint
-- Remove rejection_reason column as it's no longer needed

-- Step 1: Update any existing REJECTED statuses to PENDING (they will remain unverified)
UPDATE farm_verifications 
SET verification_status = 'PENDING', 
    verified_at = NULL,
    rejection_reason = NULL
WHERE verification_status = 'REJECTED';

-- Step 2: Drop the old CHECK constraint (name may vary between databases; use IF EXISTS)
ALTER TABLE farm_verifications 
DROP CONSTRAINT IF EXISTS farm_verifications_verification_status_check;

-- Step 3: Add new CHECK constraint without REJECTED
ALTER TABLE farm_verifications 
ADD CONSTRAINT farm_verifications_verification_status_check 
CHECK (verification_status IN ('PENDING', 'VERIFIED', 'IN_PROGRESS'));

-- Step 4: Drop the rejection_reason column
ALTER TABLE farm_verifications 
DROP COLUMN IF EXISTS rejection_reason;

