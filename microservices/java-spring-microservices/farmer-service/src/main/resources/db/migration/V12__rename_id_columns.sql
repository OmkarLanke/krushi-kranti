-- ============================================
-- Rename ID columns to match Java entity mappings
-- This migration is idempotent - it only renames columns if they exist with old names
-- For fresh databases (where V1-V6 already create correct column names), this does nothing
-- ============================================

-- Step 1: Rename primary key columns (only if they exist as 'id')
DO $$
BEGIN
    -- Rename farmers.id to farmer_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farmers' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE farmers RENAME COLUMN id TO farmer_id;
        RAISE NOTICE 'Renamed farmers.id to farmer_id';
    ELSE
        RAISE NOTICE 'farmers.farmer_id already exists, skipping rename';
    END IF;
    
    -- Rename farms.id to farm_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farms' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE farms RENAME COLUMN id TO farm_id;
        RAISE NOTICE 'Renamed farms.id to farm_id';
    ELSE
        RAISE NOTICE 'farms.farm_id already exists, skipping rename';
    END IF;
    
    -- Rename crop_types.id to crop_type_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_types' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crop_types RENAME COLUMN id TO crop_type_id;
        RAISE NOTICE 'Renamed crop_types.id to crop_type_id';
    ELSE
        RAISE NOTICE 'crop_types.crop_type_id already exists, skipping rename';
    END IF;
    
    -- Rename crop_names.id to crop_name_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_names' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crop_names RENAME COLUMN id TO crop_name_id;
        RAISE NOTICE 'Renamed crop_names.id to crop_name_id';
    ELSE
        RAISE NOTICE 'crop_names.crop_name_id already exists, skipping rename';
    END IF;
    
    -- Rename crops.id to crop_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crops' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crops RENAME COLUMN id TO crop_id;
        RAISE NOTICE 'Renamed crops.id to crop_id';
    ELSE
        RAISE NOTICE 'crops.crop_id already exists, skipping rename';
    END IF;
    
    -- Rename pincode_master.id to pincode_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pincode_master' AND column_name = 'id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE pincode_master RENAME COLUMN id TO pincode_id;
        RAISE NOTICE 'Renamed pincode_master.id to pincode_id';
    ELSE
        RAISE NOTICE 'pincode_master.pincode_id already exists, skipping rename';
    END IF;
END $$;

-- Step 2: Update foreign key constraints to reference renamed columns (idempotent)
-- Drop old constraints if they exist and recreate with correct references

-- Update farms table foreign key
ALTER TABLE farms DROP CONSTRAINT IF EXISTS farms_farmer_id_fkey;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farms' AND column_name = 'farmer_id' AND table_schema = 'public'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farmers' AND column_name = 'farmer_id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE farms ADD CONSTRAINT farms_farmer_id_fkey 
            FOREIGN KEY (farmer_id) REFERENCES farmers(farmer_id) ON DELETE CASCADE;
        RAISE NOTICE 'Updated farms foreign key to reference farmers(farmer_id)';
    END IF;
END $$;

-- Update crops table foreign keys
ALTER TABLE crops DROP CONSTRAINT IF EXISTS crops_farm_id_fkey;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crops' AND column_name = 'farm_id' AND table_schema = 'public'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'farms' AND column_name = 'farm_id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crops ADD CONSTRAINT crops_farm_id_fkey 
            FOREIGN KEY (farm_id) REFERENCES farms(farm_id) ON DELETE CASCADE;
        RAISE NOTICE 'Updated crops foreign key to reference farms(farm_id)';
    END IF;
END $$;

ALTER TABLE crops DROP CONSTRAINT IF EXISTS crops_crop_name_id_fkey;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crops' AND column_name = 'crop_name_id' AND table_schema = 'public'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_names' AND column_name = 'crop_name_id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crops ADD CONSTRAINT crops_crop_name_id_fkey 
            FOREIGN KEY (crop_name_id) REFERENCES crop_names(crop_name_id);
        RAISE NOTICE 'Updated crops foreign key to reference crop_names(crop_name_id)';
    END IF;
END $$;

-- Update crop_names table foreign key
ALTER TABLE crop_names DROP CONSTRAINT IF EXISTS crop_names_crop_type_id_fkey;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_names' AND column_name = 'crop_type_id' AND table_schema = 'public'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crop_types' AND column_name = 'crop_type_id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE crop_names ADD CONSTRAINT crop_names_crop_type_id_fkey 
            FOREIGN KEY (crop_type_id) REFERENCES crop_types(crop_type_id) ON DELETE CASCADE;
        RAISE NOTICE 'Updated crop_names foreign key to reference crop_types(crop_type_id)';
    END IF;
END $$;

-- Step 3: Update indexes that reference the old column names (idempotent)
DROP INDEX IF EXISTS idx_farms_farmer_id;
CREATE INDEX IF NOT EXISTS idx_farms_farmer_id ON farms(farmer_id);

DROP INDEX IF EXISTS idx_crops_farm_id;
CREATE INDEX IF NOT EXISTS idx_crops_farm_id ON crops(farm_id);

DROP INDEX IF EXISTS idx_crops_crop_name_id;
CREATE INDEX IF NOT EXISTS idx_crops_crop_name_id ON crops(crop_name_id);

DROP INDEX IF EXISTS idx_crop_names_type_id;
CREATE INDEX IF NOT EXISTS idx_crop_names_type_id ON crop_names(crop_type_id);
