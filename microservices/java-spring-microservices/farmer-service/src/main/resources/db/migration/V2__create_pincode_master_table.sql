-- Create pincode_master table for address lookup
CREATE TABLE IF NOT EXISTS pincode_master (
    id BIGSERIAL PRIMARY KEY,
    pincode VARCHAR(6) NOT NULL,
    village VARCHAR(200) NOT NULL,
    taluka VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for fast lookup
CREATE INDEX idx_pincode_master_pincode ON pincode_master(pincode);
CREATE INDEX idx_pincode_master_state ON pincode_master(state);
CREATE INDEX idx_pincode_master_district ON pincode_master(district);

-- Create unique constraint to prevent duplicate entries
CREATE UNIQUE INDEX idx_pincode_master_unique ON pincode_master(pincode, village);

