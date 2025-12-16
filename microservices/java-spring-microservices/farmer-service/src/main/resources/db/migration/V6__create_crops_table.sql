-- Create crops table for storing farmer's crop data
-- Links to farm and references crop_names master table
CREATE TABLE IF NOT EXISTS crops (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,
    
    -- Relationships
    farm_id BIGINT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    crop_name_id BIGINT NOT NULL REFERENCES crop_names(id),
    
    -- Area
    area_acres DECIMAL(10, 2) NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_crops_farm_id ON crops(farm_id);
CREATE INDEX idx_crops_crop_name_id ON crops(crop_name_id);
CREATE INDEX idx_crops_active ON crops(is_active);

-- Composite index for farm crops queries
CREATE INDEX idx_crops_farm_active ON crops(farm_id, is_active);

