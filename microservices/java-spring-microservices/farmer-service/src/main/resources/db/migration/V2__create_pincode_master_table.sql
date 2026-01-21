-- Create pincode_master table for address lookup
CREATE TABLE IF NOT EXISTS pincode_master (
    pincode_id BIGSERIAL PRIMARY KEY,
    pincode VARCHAR(6) NOT NULL,
    village VARCHAR(200) NOT NULL,
    village_hi VARCHAR(200),
    village_mr VARCHAR(200),
    taluka VARCHAR(100) NOT NULL,
    taluka_hi VARCHAR(100),
    taluka_mr VARCHAR(100),
    district VARCHAR(100) NOT NULL,
    district_hi VARCHAR(100),
    district_mr VARCHAR(100),
    state VARCHAR(100) NOT NULL,
    state_hi VARCHAR(100),
    state_mr VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for fast lookup
CREATE INDEX idx_pincode_master_pincode ON pincode_master(pincode);
CREATE INDEX idx_pincode_master_state ON pincode_master(state);
CREATE INDEX idx_pincode_master_district ON pincode_master(district);

-- Create unique constraint to prevent duplicate entries
CREATE UNIQUE INDEX idx_pincode_master_unique ON pincode_master(pincode, village);
