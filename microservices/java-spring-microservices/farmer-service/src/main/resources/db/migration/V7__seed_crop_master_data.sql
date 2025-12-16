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
SELECT id, 'TOMATO', 'Tomato', 'टमाटर', 1 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ONION', 'Onion', 'कांदा', 2 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'POTATO', 'Potato', 'बटाटा', 3 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CAULIFLOWER', 'Cauliflower', 'फूलकोबी', 4 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CABBAGE', 'Cabbage', 'कोबी', 5 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CORIANDER', 'Coriander', 'कोथिंबीर', 6 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BEANS', 'Beans', 'शेंगा', 7 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BRINJAL', 'Brinjal (Eggplant)', 'वांगे', 8 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LADYFINGER', 'Ladyfinger (Okra)', 'भेंडी', 9 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CAPSICUM', 'Capsicum', 'ढोबळी मिरची', 10 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CARROT', 'Carrot', 'गाजर', 11 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BEETROOT', 'Beetroot', 'बीट', 12 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CUCUMBER', 'Cucumber', 'काकडी', 13 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SPINACH', 'Spinach (Palak)', 'पालक', 14 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FENUGREEK', 'Fenugreek (Methi)', 'मेथी', 15 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RADISH', 'Radish (Mooli)', 'मुळा', 16 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BITTER_GOURD', 'Bitter Gourd (Karela)', 'कारले', 17 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BOTTLE_GOURD', 'Bottle Gourd (Lauki)', 'दुधी भोपळा', 18 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RIDGE_GOURD', 'Ridge Gourd (Turai)', 'दोडका', 19 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'PUMPKIN', 'Pumpkin (Kaddu)', 'भोपळा', 20 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'DRUMSTICK', 'Drumstick (Moringa)', 'शेवगा', 21 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GREEN_PEAS', 'Green Peas', 'वाटाणे', 22 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GARLIC', 'Garlic', 'लसूण', 23 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GINGER', 'Ginger', 'आले', 24 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GREEN_CHILLI', 'Green Chilli', 'हिरवी मिरची', 25 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SWEET_POTATO', 'Sweet Potato', 'रताळे', 26 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TURNIP', 'Turnip', 'सलगम', 27 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LETTUCE', 'Lettuce', 'लेट्यूस', 28 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BROCCOLI', 'Broccoli', 'ब्रोकोली', 29 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MUSHROOM', 'Mushroom', 'अळंबी', 30 FROM crop_types WHERE type_name = 'VEGETABLE';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'VEGETABLE_OTHER', 'Other Vegetable', 'इतर भाजी', 99 FROM crop_types WHERE type_name = 'VEGETABLE';

-- Seed crop_names for FRUIT
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BANANA', 'Banana', 'केळे', 1 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MANGO', 'Mango', 'आंबा', 2 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'PAPAYA', 'Papaya', 'पपई', 3 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'POMEGRANATE', 'Pomegranate', 'डाळिंब', 4 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'WATERMELON', 'Watermelon', 'कलिंगड', 5 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GRAPES', 'Grapes', 'द्राक्षे', 6 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CHIKOO', 'Chikoo (Sapota)', 'चिकू', 7 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GUAVA', 'Guava', 'पेरू', 8 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ORANGE', 'Orange', 'संत्रा', 9 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'APPLE', 'Apple', 'सफरचंद', 10 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'PINEAPPLE', 'Pineapple', 'अननस', 11 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'COCONUT', 'Coconut', 'नारळ', 12 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LEMON', 'Lemon', 'लिंबू', 13 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SWEET_LIME', 'Sweet Lime (Mosambi)', 'मोसंबी', 14 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CUSTARD_APPLE', 'Custard Apple (Sitaphal)', 'सीताफळ', 15 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'JACKFRUIT', 'Jackfruit', 'फणस', 16 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LITCHI', 'Litchi', 'लीची', 17 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FIG', 'Fig (Anjeer)', 'अंजीर', 18 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'STRAWBERRY', 'Strawberry', 'स्ट्रॉबेरी', 19 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'KIWI', 'Kiwi', 'किवी', 20 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'DRAGON_FRUIT', 'Dragon Fruit', 'ड्रॅगन फ्रूट', 21 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'AMLA', 'Amla (Indian Gooseberry)', 'आवळा', 22 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'JAMUN', 'Jamun', 'जांभूळ', 23 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BER', 'Ber (Indian Jujube)', 'बोर', 24 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TAMARIND', 'Tamarind', 'चिंच', 25 FROM crop_types WHERE type_name = 'FRUIT';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FRUIT_OTHER', 'Other Fruit', 'इतर फळे', 99 FROM crop_types WHERE type_name = 'FRUIT';

-- Seed crop_names for GRAIN_CEREAL
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'WHEAT', 'Wheat', 'गहू', 1 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RICE', 'Rice (Paddy)', 'तांदूळ', 2 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'JOWAR', 'Jowar (Sorghum)', 'ज्वारी', 3 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BAJRA', 'Bajra (Pearl Millet)', 'बाजरी', 4 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MAIZE', 'Maize (Corn)', 'मका', 5 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RAGI', 'Ragi (Finger Millet)', 'नाचणी', 6 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BARLEY', 'Barley', 'जव', 7 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'OATS', 'Oats', 'ओट्स', 8 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GRAIN_OTHER', 'Other Grain', 'इतर धान्य', 99 FROM crop_types WHERE type_name = 'GRAIN_CEREAL';

-- Seed crop_names for PULSES_LEGUMES
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TOOR_DAL', 'Toor Dal (Arhar)', 'तूर डाळ', 1 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MOONG_DAL', 'Moong Dal', 'मूग डाळ', 2 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CHANA_DAL', 'Chana Dal (Bengal Gram)', 'चणा डाळ', 3 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MASOOR_DAL', 'Masoor Dal (Red Lentil)', 'मसूर डाळ', 4 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'URAD_DAL', 'Urad Dal (Black Gram)', 'उडीद डाळ', 5 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RAJMA', 'Rajma (Kidney Beans)', 'राजमा', 6 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LOBIA', 'Lobia (Black-eyed Peas)', 'चवळी', 7 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'KULTHI', 'Kulthi (Horse Gram)', 'कुळीथ', 8 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MOTH_DAL', 'Moth Dal', 'मठ', 9 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CHICKPEAS', 'Chickpeas (Kabuli Chana)', 'काबुली चणे', 10 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SOYBEAN', 'Soybean', 'सोयाबीन', 11 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'PULSE_OTHER', 'Other Pulse', 'इतर कडधान्य', 99 FROM crop_types WHERE type_name = 'PULSES_LEGUMES';

-- Seed crop_names for SPICES
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TURMERIC', 'Turmeric (Haldi)', 'हळद', 1 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RED_CHILLI', 'Red Chilli', 'लाल मिरची', 2 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BLACK_PEPPER', 'Black Pepper', 'काळी मिरी', 3 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CUMIN', 'Cumin (Jeera)', 'जिरे', 4 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CORIANDER_SEEDS', 'Coriander Seeds', 'धणे', 5 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CARDAMOM', 'Cardamom', 'वेलची', 6 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CLOVE', 'Clove', 'लवंग', 7 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CINNAMON', 'Cinnamon', 'दालचिनी', 8 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FENUGREEK_SEEDS', 'Fenugreek Seeds', 'मेथी दाणे', 9 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MUSTARD_SEEDS', 'Mustard Seeds', 'मोहरी', 10 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FENNEL', 'Fennel (Saunf)', 'बडीशेप', 11 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ASAFOETIDA', 'Asafoetida (Hing)', 'हिंग', 12 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BAY_LEAF', 'Bay Leaf', 'तमालपत्र', 13 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'NUTMEG', 'Nutmeg', 'जायफळ', 14 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SAFFRON', 'Saffron', 'केशर', 15 FROM crop_types WHERE type_name = 'SPICES';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SPICE_OTHER', 'Other Spice', 'इतर मसाला', 99 FROM crop_types WHERE type_name = 'SPICES';

-- Seed crop_names for OILSEEDS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GROUNDNUT', 'Groundnut (Peanut)', 'शेंगदाणे', 1 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MUSTARD', 'Mustard', 'मोहरी', 2 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SUNFLOWER', 'Sunflower', 'सूर्यफूल', 3 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SESAME', 'Sesame (Til)', 'तीळ', 4 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'COCONUT_OIL', 'Coconut (for oil)', 'नारळ (तेलासाठी)', 5 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CASTOR', 'Castor', 'एरंड', 6 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LINSEED', 'Linseed (Flaxseed)', 'जवस', 7 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SAFFLOWER', 'Safflower', 'करडई', 8 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'NIGER_SEEDS', 'Niger Seeds', 'खुरासणी', 9 FROM crop_types WHERE type_name = 'OILSEEDS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'OILSEED_OTHER', 'Other Oilseed', 'इतर तेलबिया', 99 FROM crop_types WHERE type_name = 'OILSEEDS';

-- Seed crop_names for CASH_CROPS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SUGARCANE', 'Sugarcane', 'ऊस', 1 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'COTTON', 'Cotton', 'कापूस', 2 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'JUTE', 'Jute', 'ताग', 3 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TOBACCO', 'Tobacco', 'तंबाखू', 4 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'RUBBER', 'Rubber', 'रबर', 5 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TEA', 'Tea', 'चहा', 6 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'COFFEE', 'Coffee', 'कॉफी', 7 FROM crop_types WHERE type_name = 'CASH_CROPS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CASH_CROP_OTHER', 'Other Cash Crop', 'इतर नगदी पीक', 99 FROM crop_types WHERE type_name = 'CASH_CROPS';

-- Seed crop_names for DAIRY_MILK
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'COW_MILK', 'Fresh Cow Milk', 'गाईचे दूध', 1 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BUFFALO_MILK', 'Fresh Buffalo Milk', 'म्हशीचे दूध', 2 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GHEE', 'Ghee', 'तूप', 3 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'PANEER', 'Paneer', 'पनीर', 4 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CURD', 'Curd (Dahi)', 'दही', 5 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BUTTERMILK', 'Buttermilk (Chaas)', 'ताक', 6 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CREAM', 'Cream', 'साय', 7 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'KHOYA', 'Khoya (Mawa)', 'खवा', 8 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CHEESE', 'Cheese', 'चीज', 9 FROM crop_types WHERE type_name = 'DAIRY_MILK';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'DAIRY_OTHER', 'Other Dairy Product', 'इतर दुग्धजन्य पदार्थ', 99 FROM crop_types WHERE type_name = 'DAIRY_MILK';

-- Seed crop_names for FLOWERS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MARIGOLD', 'Marigold', 'झेंडू', 1 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ROSE', 'Rose', 'गुलाब', 2 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'JASMINE', 'Jasmine', 'मोगरा', 3 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TUBEROSE', 'Tuberose', 'रजनीगंधा', 4 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'CHRYSANTHEMUM', 'Chrysanthemum', 'शेवंती', 5 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GLADIOLUS', 'Gladiolus', 'ग्लॅडिओलस', 6 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LOTUS', 'Lotus', 'कमळ', 7 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'HIBISCUS', 'Hibiscus', 'जास्वंद', 8 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SUNFLOWER_FLOWER', 'Sunflower', 'सूर्यफूल', 9 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ORCHID', 'Orchid', 'ऑर्किड', 10 FROM crop_types WHERE type_name = 'FLOWERS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'FLOWER_OTHER', 'Other Flower', 'इतर फुले', 99 FROM crop_types WHERE type_name = 'FLOWERS';

-- Seed crop_names for MEDICINAL_HERBS
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'TULSI', 'Tulsi (Holy Basil)', 'तुळस', 1 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ALOE_VERA', 'Aloe Vera', 'कोरफड', 2 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'ASHWAGANDHA', 'Ashwagandha', 'अश्वगंधा', 3 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'NEEM', 'Neem', 'कडुलिंब', 4 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'BRAHMI', 'Brahmi', 'ब्राह्मी', 5 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'MINT', 'Mint (Pudina)', 'पुदिना', 6 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'LEMONGRASS', 'Lemongrass', 'गवती चहा', 7 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'STEVIA', 'Stevia', 'स्टीव्हिया', 8 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'GILOY', 'Giloy', 'गुळवेल', 9 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'SHATAVARI', 'Shatavari', 'शतावरी', 10 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';
INSERT INTO crop_names (crop_type_id, name, display_name, local_name, display_order)
SELECT id, 'HERB_OTHER', 'Other Herb', 'इतर औषधी वनस्पती', 99 FROM crop_types WHERE type_name = 'MEDICINAL_HERBS';

