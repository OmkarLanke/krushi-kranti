-- Seed crop_types master data
INSERT INTO crop_types (type_name, display_name, description, display_order) VALUES
('VEGETABLE', 'Vegetables', 'Fresh vegetables including leafy greens, root vegetables, and gourds', 1),
('FRUIT', 'Fruits', 'Fresh fruits including tropical, citrus, and seasonal fruits', 2),
('GRAIN_CEREAL', 'Grains & Cereals', 'Staple grains and cereals like wheat, rice, and millets', 3),
('PULSES_LEGUMES', 'Pulses & Legumes', 'Protein-rich pulses and legumes including dals and beans', 4),
('SPICES', 'Spices', 'Aromatic spices and seasonings', 5),
('OILSEEDS', 'Oilseeds', 'Oil-producing seeds like groundnut, mustard, and sesame', 6),
('CASH_CROPS', 'Cash Crops', 'Commercial crops like sugarcane, cotton, and jute', 7),
('DAIRY_MILK', 'Dairy & Milk Products', 'Milk and dairy products from farm animals', 8),
('FLOWERS', 'Flowers', 'Ornamental and commercial flowers', 9),
('MEDICINAL_HERBS', 'Medicinal & Herbs', 'Medicinal plants and culinary herbs', 10);

-- Seed crop_names for VEGETABLE
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TOMATO', 'Tomato', 'टमाटर', 1 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ONION', 'Onion', 'कांदा', 2 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'POTATO', 'Potato', 'बटाटा', 3 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CAULIFLOWER', 'Cauliflower', 'फूलकोबी', 4 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CABBAGE', 'Cabbage', 'कोबी', 5 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CORIANDER', 'Coriander', 'कोथिंबीर', 6 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BEANS', 'Beans', 'शेंगा', 7 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BRINJAL', 'Brinjal (Eggplant)', 'वांगे', 8 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LADYFINGER', 'Ladyfinger (Okra)', 'भेंडी', 9 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CAPSICUM', 'Capsicum', 'ढोबळी मिरची', 10 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CARROT', 'Carrot', 'गाजर', 11 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BEETROOT', 'Beetroot', 'बीट', 12 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CUCUMBER', 'Cucumber', 'काकडी', 13 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SPINACH', 'Spinach (Palak)', 'पालक', 14 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FENUGREEK', 'Fenugreek (Methi)', 'मेथी', 15 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RADISH', 'Radish (Mooli)', 'मुळा', 16 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BITTER_GOURD', 'Bitter Gourd (Karela)', 'कारले', 17 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BOTTLE_GOURD', 'Bottle Gourd (Lauki)', 'दुधी भोपळा', 18 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RIDGE_GOURD', 'Ridge Gourd (Turai)', 'दोडका', 19 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'PUMPKIN', 'Pumpkin (Kaddu)', 'भोपळा', 20 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'DRUMSTICK', 'Drumstick (Moringa)', 'शेवगा', 21 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GREEN_PEAS', 'Green Peas', 'वाटाणे', 22 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GARLIC', 'Garlic', 'लसूण', 23 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GINGER', 'Ginger', 'आले', 24 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GREEN_CHILLI', 'Green Chilli', 'हिरवी मिरची', 25 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SWEET_POTATO', 'Sweet Potato', 'रताळे', 26 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TURNIP', 'Turnip', 'सलगम', 27 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LETTUCE', 'Lettuce', 'लेट्यूस', 28 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BROCCOLI', 'Broccoli', 'ब्रोकोली', 29 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MUSHROOM', 'Mushroom', 'अळंबी', 30 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'VEGETABLE_OTHER', 'Other Vegetable', 'इतर भाजी', 99 FROM crop_types WHERE type_name = 'VEGETABLE';

-- Seed crop_names for FRUIT
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BANANA', 'Banana', 'केळे', 1 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MANGO', 'Mango', 'आंबा', 2 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'PAPAYA', 'Papaya', 'पपई', 3 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'POMEGRANATE', 'Pomegranate', 'डाळिंब', 4 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'WATERMELON', 'Watermelon', 'कलिंगड', 5 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GRAPES', 'Grapes', 'द्राक्षे', 6 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CHIKOO', 'Chikoo (Sapota)', 'चिकू', 7 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GUAVA', 'Guava', 'पेरू', 8 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ORANGE', 'Orange', 'संत्रा', 9 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'APPLE', 'Apple', 'सफरचंद', 10 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'PINEAPPLE', 'Pineapple', 'अननस', 11 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'COCONUT', 'Coconut', 'नारळ', 12 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LEMON', 'Lemon', 'लिंबू', 13 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SWEET_LIME', 'Sweet Lime (Mosambi)', 'मोसंबी', 14 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CUSTARD_APPLE', 'Custard Apple (Sitaphal)', 'सीताफळ', 15 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'JACKFRUIT', 'Jackfruit', 'फणस', 16 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LITCHI', 'Litchi', 'लीची', 17 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FIG', 'Fig (Anjeer)', 'अंजीर', 18 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'STRAWBERRY', 'Strawberry', 'स्ट्रॉबेरी', 19 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'KIWI', 'Kiwi', 'किवी', 20 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'DRAGON_FRUIT', 'Dragon Fruit', 'ड्रॅगन फ्रूट', 21 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'AMLA', 'Amla (Indian Gooseberry)', 'आवळा', 22 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'JAMUN', 'Jamun', 'जांभूळ', 23 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BER', 'Ber (Indian Jujube)', 'बोर', 24 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TAMARIND', 'Tamarind', 'चिंच', 25 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FRUIT_OTHER', 'Other Fruit', 'इतर फळे', 99 FROM crop_types WHERE type_name = 'FRUIT';

-- Seed crop_names for GRAIN_CEREAL
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'WHEAT', 'Wheat', 'गहू', 1 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RICE', 'Rice (Paddy)', 'तांदूळ', 2 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'JOWAR', 'Jowar (Sorghum)', 'ज्वारी', 3 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BAJRA', 'Bajra (Pearl Millet)', 'बाजरी', 4 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MAIZE', 'Maize (Corn)', 'मका', 5 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RAGI', 'Ragi (Finger Millet)', 'नाचणी', 6 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BARLEY', 'Barley', 'जव', 7 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'OATS', 'Oats', 'ओट्स', 8 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GRAIN_OTHER', 'Other Grain', 'इतर धान्य', 99 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';

-- Seed crop_names for PULSES_LEGUMES
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TOOR_DAL', 'Toor Dal (Arhar)', 'तूर डाळ', 1 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MOONG_DAL', 'Moong Dal', 'मूग डाळ', 2 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CHANA_DAL', 'Chana Dal (Bengal Gram)', 'चणा डाळ', 3 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MASOOR_DAL', 'Masoor Dal (Red Lentil)', 'मसूर डाळ', 4 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'URAD_DAL', 'Urad Dal (Black Gram)', 'उडीद डाळ', 5 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RAJMA', 'Rajma (Kidney Beans)', 'राजमा', 6 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LOBIA', 'Lobia (Black-eyed Peas)', 'चवळी', 7 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'KULTHI', 'Kulthi (Horse Gram)', 'कुळीथ', 8 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MOTH_DAL', 'Moth Dal', 'मठ', 9 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CHICKPEAS', 'Chickpeas (Kabuli Chana)', 'काबुली चणे', 10 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SOYBEAN', 'Soybean', 'सोयाबीन', 11 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'PULSE_OTHER', 'Other Pulse', 'इतर कडधान्य', 99 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';

-- Seed crop_names for SPICES
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TURMERIC', 'Turmeric (Haldi)', 'हळद', 1 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RED_CHILLI', 'Red Chilli', 'लाल मिरची', 2 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BLACK_PEPPER', 'Black Pepper', 'काळी मिरी', 3 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CUMIN', 'Cumin (Jeera)', 'जिरे', 4 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CORIANDER_SEEDS', 'Coriander Seeds', 'धणे', 5 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CARDAMOM', 'Cardamom', 'वेलची', 6 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CLOVE', 'Clove', 'लवंग', 7 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CINNAMON', 'Cinnamon', 'दालचिनी', 8 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FENUGREEK_SEEDS', 'Fenugreek Seeds', 'मेथी दाणे', 9 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MUSTARD_SEEDS', 'Mustard Seeds', 'मोहरी', 10 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FENNEL', 'Fennel (Saunf)', 'बडीशेप', 11 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ASAFOETIDA', 'Asafoetida (Hing)', 'हिंग', 12 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BAY_LEAF', 'Bay Leaf', 'तमालपत्र', 13 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'NUTMEG', 'Nutmeg', 'जायफळ', 14 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SAFFRON', 'Saffron', 'केशर', 15 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SPICE_OTHER', 'Other Spice', 'इतर मसाला', 99 FROM crop_types WHERE type_name = 'SPICES';

-- Seed crop_names for OILSEEDS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GROUNDNUT', 'Groundnut (Peanut)', 'शेंगदाणे', 1 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MUSTARD', 'Mustard', 'मोहरी', 2 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SUNFLOWER', 'Sunflower', 'सूर्यफूल', 3 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SESAME', 'Sesame (Til)', 'तीळ', 4 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'COCONUT_OIL', 'Coconut (for oil)', 'नारळ (तेलासाठी)', 5 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CASTOR', 'Castor', 'एरंड', 6 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LINSEED', 'Linseed (Flaxseed)', 'जवस', 7 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SAFFLOWER', 'Safflower', 'करडई', 8 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'NIGER_SEEDS', 'Niger Seeds', 'खुरासणी', 9 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'OILSEED_OTHER', 'Other Oilseed', 'इतर तेलबिया', 99 FROM crop_types WHERE type_name = 'OILSEEDS';

-- Seed crop_names for CASH_CROPS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SUGARCANE', 'Sugarcane', 'ऊस', 1 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'COTTON', 'Cotton', 'कापूस', 2 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'JUTE', 'Jute', 'ताग', 3 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TOBACCO', 'Tobacco', 'तंबाखू', 4 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'RUBBER', 'Rubber', 'रबर', 5 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TEA', 'Tea', 'चहा', 6 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'COFFEE', 'Coffee', 'कॉफी', 7 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CASH_CROP_OTHER', 'Other Cash Crop', 'इतर नगदी पीक', 99 FROM crop_types WHERE type_name = 'CASH_CROPS';

-- Seed crop_names for DAIRY_MILK
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'COW_MILK', 'Fresh Cow Milk', 'गाईचे दूध', 1 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BUFFALO_MILK', 'Fresh Buffalo Milk', 'म्हशीचे दूध', 2 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GHEE', 'Ghee', 'तूप', 3 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'PANEER', 'Paneer', 'पनीर', 4 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CURD', 'Curd (Dahi)', 'दही', 5 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BUTTERMILK', 'Buttermilk (Chaas)', 'ताक', 6 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CREAM', 'Cream', 'साय', 7 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'KHOYA', 'Khoya (Mawa)', 'खवा', 8 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CHEESE', 'Cheese', 'चीज', 9 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'DAIRY_OTHER', 'Other Dairy Product', 'इतर दुग्धजन्य पदार्थ', 99 FROM crop_types WHERE type_name = 'DAIRY_MILK';

-- Seed crop_names for FLOWERS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MARIGOLD', 'Marigold', 'झेंडू', 1 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ROSE', 'Rose', 'गुलाब', 2 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'JASMINE', 'Jasmine', 'मोगरा', 3 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TUBEROSE', 'Tuberose', 'रजनीगंधा', 4 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'CHRYSANTHEMUM', 'Chrysanthemum', 'शेवंती', 5 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GLADIOLUS', 'Gladiolus', 'ग्लॅडिओलस', 6 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LOTUS', 'Lotus', 'कमळ', 7 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'HIBISCUS', 'Hibiscus', 'जास्वंद', 8 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SUNFLOWER_FLOWER', 'Sunflower', 'सूर्यफूल', 9 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ORCHID', 'Orchid', 'ऑर्किड', 10 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'FLOWER_OTHER', 'Other Flower', 'इतर फुले', 99 FROM crop_types WHERE type_name = 'FLOWERS';

-- Seed crop_names for MEDICINAL_HERBS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'TULSI', 'Tulsi (Holy Basil)', 'तुळस', 1 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ALOE_VERA', 'Aloe Vera', 'कोरफड', 2 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'ASHWAGANDHA', 'Ashwagandha', 'अश्वगंधा', 3 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'NEEM', 'Neem', 'कडुलिंब', 4 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'BRAHMI', 'Brahmi', 'ब्राह्मी', 5 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'MINT', 'Mint (Pudina)', 'पुदिना', 6 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'LEMONGRASS', 'Lemongrass', 'गवती चहा', 7 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'STEVIA', 'Stevia', 'स्टीव्हिया', 8 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'GILOY', 'Giloy', 'गुळवेल', 9 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'SHATAVARI', 'Shatavari', 'शतावरी', 10 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT crop_type_id, 'HERB_OTHER', 'Other Herb', 'इतर औषधी वनस्पती', 99 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';

