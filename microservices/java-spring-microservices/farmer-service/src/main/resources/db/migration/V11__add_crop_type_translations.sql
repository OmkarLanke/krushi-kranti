-- Add translation columns to crop_types table
ALTER TABLE crop_types ADD COLUMN IF NOT EXISTS display_name_hi VARCHAR(100);
ALTER TABLE crop_types ADD COLUMN IF NOT EXISTS display_name_mr VARCHAR(100);

-- Update crop types with Hindi and Marathi translations
UPDATE crop_types SET 
    display_name_hi = 'सब्जियां',
    display_name_mr = 'भाजीपाला'
WHERE type_name = 'VEGETABLE';

UPDATE crop_types SET 
    display_name_hi = 'फल',
    display_name_mr = 'फळे'
WHERE type_name = 'FRUIT';

UPDATE crop_types SET 
    display_name_hi = 'अनाज और दाल',
    display_name_mr = 'धान्य आणि तृणधान्ये'
WHERE type_name = 'GRAIN_CEREAL';

UPDATE crop_types SET 
    display_name_hi = 'दलहन और फलियां',
    display_name_mr = 'कडधान्ये आणि डाळी'
WHERE type_name = 'PULSES_LEGUMES';

UPDATE crop_types SET 
    display_name_hi = 'मसाले',
    display_name_mr = 'मसाले'
WHERE type_name = 'SPICES';

UPDATE crop_types SET 
    display_name_hi = 'तिलहन',
    display_name_mr = 'तेलबिया'
WHERE type_name = 'OILSEEDS';

UPDATE crop_types SET 
    display_name_hi = 'नकदी फसलें',
    display_name_mr = 'नगदी पिके'
WHERE type_name = 'CASH_CROPS';

UPDATE crop_types SET 
    display_name_hi = 'डेयरी और दूध उत्पाद',
    display_name_mr = 'दुग्धजन्य पदार्थ'
WHERE type_name = 'DAIRY_MILK';

UPDATE crop_types SET 
    display_name_hi = 'फूल',
    display_name_mr = 'फुले'
WHERE type_name = 'FLOWERS';

UPDATE crop_types SET 
    display_name_hi = 'औषधीय और जड़ी-बूटियां',
    display_name_mr = 'औषधी आणि वनस्पती'
WHERE type_name = 'MEDICINAL_HERBS';


