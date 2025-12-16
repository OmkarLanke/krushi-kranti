-- Add sowing date, harvesting date, and crop status fields to crops table
ALTER TABLE crops 
ADD COLUMN sowing_date DATE,
ADD COLUMN harvesting_date DATE,
ADD COLUMN crop_status VARCHAR(20) DEFAULT 'PLANNED' CHECK (crop_status IN ('PLANNED', 'SOWN', 'GROWING', 'HARVESTED', 'FAILED'));

-- Create index for crop status queries
CREATE INDEX idx_crops_status ON crops(crop_status);

-- Create index for date-based queries
CREATE INDEX idx_crops_sowing_date ON crops(sowing_date);
CREATE INDEX idx_crops_harvesting_date ON crops(harvesting_date);

