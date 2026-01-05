-- ============================================
-- Rename ID columns to match Java entity mappings
-- This migration fixes the mismatch between database schema and Java entities
-- ============================================

-- Step 1: Rename primary key columns (only if they exist as 'id')
-- Use DO block to conditionally rename columns
DO $$
BEGIN
    -- Rename farmers.id to farmer_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farmers' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE farmers RENAME COLUMN id TO farmer_id;
    END IF;
    
    -- Rename farms.id to farm_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farms' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE farms RENAME COLUMN id TO farm_id;
    END IF;
    
    -- Rename crop_types.id to crop_type_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_types' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crop_types RENAME COLUMN id TO crop_type_id;
    END IF;
    
    -- Rename crop_names.id to crop_name_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_names' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crop_names RENAME COLUMN id TO crop_name_id;
    END IF;
    
    -- Rename crops.id to crop_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crops' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crops RENAME COLUMN id TO crop_id;
    END IF;
    
    -- Rename pincode_master.id to pincode_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pincode_master' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE pincode_master RENAME COLUMN id TO pincode_id;
    END IF;
END $$;

-- Step 2: Update foreign key constraints to reference renamed columns
-- Update farms table foreign key
ALTER TABLE farms DROP CONSTRAINT IF EXISTS farms_farmer_id_fkey;
ALTER TABLE farms ADD CONSTRAINT farms_farmer_id_fkey 
    FOREIGN KEY (farmer_id) REFERENCES farmers(farmer_id) ON DELETE CASCADE;

-- Update crops table foreign keys
ALTER TABLE crops DROP CONSTRAINT IF EXISTS crops_farm_id_fkey;
ALTER TABLE crops ADD CONSTRAINT crops_farm_id_fkey 
    FOREIGN KEY (farm_id) REFERENCES farms(farm_id) ON DELETE CASCADE;

ALTER TABLE crops DROP CONSTRAINT IF EXISTS crops_crop_name_id_fkey;
ALTER TABLE crops ADD CONSTRAINT crops_crop_name_id_fkey 
    FOREIGN KEY (crop_name_id) REFERENCES crop_names(crop_name_id);

-- Update crop_names table foreign key
ALTER TABLE crop_names DROP CONSTRAINT IF EXISTS crop_names_crop_type_id_fkey;
ALTER TABLE crop_names ADD CONSTRAINT crop_names_crop_type_id_fkey 
    FOREIGN KEY (crop_type_id) REFERENCES crop_types(crop_type_id) ON DELETE CASCADE;

-- Step 3: Update indexes that reference the old column names
-- Most indexes use column names directly, so they should auto-update
-- But we'll recreate any that might be affected to be safe
DROP INDEX IF EXISTS idx_farms_farmer_id;
CREATE INDEX idx_farms_farmer_id ON farms(farmer_id);

DROP INDEX IF EXISTS idx_crops_farm_id;
CREATE INDEX idx_crops_farm_id ON crops(farm_id);

DROP INDEX IF EXISTS idx_crops_crop_name_id;
CREATE INDEX idx_crops_crop_name_id ON crops(crop_name_id);

DROP INDEX IF EXISTS idx_crop_names_type_id;
CREATE INDEX idx_crop_names_type_id ON crop_names(crop_type_id);
