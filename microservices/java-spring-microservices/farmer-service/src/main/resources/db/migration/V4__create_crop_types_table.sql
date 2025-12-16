-- Create crop_types master table for storing crop categories
-- Admin can add/edit/delete crop types which will reflect on farmer app
CREATE TABLE IF NOT EXISTS crop_types (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,
    
    -- Type Information
    type_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- UI/Display
    icon_url TEXT,
    display_order INT DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_crop_types_active ON crop_types(is_active);
CREATE INDEX idx_crop_types_order ON crop_types(display_order);
CREATE INDEX idx_crop_types_name ON crop_types(type_name);

