-- ============================================
-- Rename ID columns in farmer_db
-- Run this script in farmer_db database
-- ============================================

-- Step 1: Rename primary key columns
ALTER TABLE farmers RENAME COLUMN id TO farmer_id;
ALTER TABLE farms RENAME COLUMN id TO farm_id;
ALTER TABLE crop_types RENAME COLUMN id TO crop_type_id;
ALTER TABLE crop_names RENAME COLUMN id TO crop_name_id;
ALTER TABLE crops RENAME COLUMN id TO crop_id;
ALTER TABLE pincode_master RENAME COLUMN id TO pincode_id;

-- Step 2: Update foreign key constraints
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

-- Verify changes
SELECT 'farmers' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'farmers' AND column_name LIKE '%_id';

SELECT 'farms' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'farms' AND column_name LIKE '%_id';

SELECT 'crop_types' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'crop_types' AND column_name LIKE '%_id';

SELECT 'crop_names' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'crop_names' AND column_name LIKE '%_id';

SELECT 'crops' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'crops' AND column_name LIKE '%_id';

SELECT 'pincode_master' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'pincode_master' AND column_name LIKE '%_id';


