-- Create crop_names master table for storing crop names under each type
-- Admin can add/edit/delete crop names which will reflect on farmer app
CREATE TABLE IF NOT EXISTS crop_names (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,
    
    -- Relationship to crop_types
    crop_type_id BIGINT NOT NULL REFERENCES crop_types(id) ON DELETE CASCADE,
    
    -- Name Information
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(150) NOT NULL,
    local_name VARCHAR(150),  -- Local/Regional name (e.g., Marathi, Hindi)
    description TEXT,
    
    -- UI/Display
    icon_url TEXT,
    display_order INT DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Unique constraint: same name cannot exist twice under same crop type
    CONSTRAINT uk_crop_name_per_type UNIQUE (crop_type_id, name)
);

-- Indexes
CREATE INDEX idx_crop_names_type_id ON crop_names(crop_type_id);
CREATE INDEX idx_crop_names_active ON crop_names(is_active);
CREATE INDEX idx_crop_names_order ON crop_names(display_order);
CREATE INDEX idx_crop_names_name ON crop_names(name);

-- Composite index for dropdown queries
CREATE INDEX idx_crop_names_type_active ON crop_names(crop_type_id, is_active, display_order);

