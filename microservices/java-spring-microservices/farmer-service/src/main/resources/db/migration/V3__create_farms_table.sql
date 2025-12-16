-- Create farms table for storing farm details (used as collateral for loans)
CREATE TABLE IF NOT EXISTS farms (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,
    
    -- Relationship to farmer
    farmer_id BIGINT NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    
    -- ========================================
    -- BASIC FARM INFORMATION (Farmer fills)
    -- ========================================
    farm_name VARCHAR(200) NOT NULL,
    farm_type VARCHAR(50) CHECK (farm_type IN ('ORGANIC', 'CONVENTIONAL', 'MIXED', 'VERMI_COMPOST')),
    total_area_acres DECIMAL(10, 2) NOT NULL,
    
    -- Address (using pincode lookup like farmer details)
    pincode VARCHAR(6) NOT NULL,
    village VARCHAR(200) NOT NULL,
    district VARCHAR(100) NOT NULL,
    taluka VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    
    -- Land Details
    soil_type VARCHAR(50) CHECK (soil_type IN ('BLACK', 'RED', 'SANDY', 'LOAMY', 'CLAY', 'MIXED')),
    irrigation_type VARCHAR(50) CHECK (irrigation_type IN ('DRIP', 'SPRINKLER', 'RAINFED', 'CANAL', 'BORE_WELL', 'OPEN_WELL', 'MIXED')),
    land_ownership VARCHAR(50) NOT NULL CHECK (land_ownership IN ('OWNED', 'LEASED', 'SHARED', 'GOVERNMENT_ALLOTTED')),
    
    -- ========================================
    -- COLLATERAL INFORMATION (For Loan Recovery)
    -- ========================================
    -- Legal/Land Details
    survey_number VARCHAR(100),
    land_registration_number VARCHAR(200),
    patta_number VARCHAR(100),
    
    -- Collateral Value & Status
    estimated_land_value DECIMAL(15, 2),
    encumbrance_status VARCHAR(50) DEFAULT 'NOT_VERIFIED' CHECK (encumbrance_status IN ('NOT_VERIFIED', 'FREE', 'ENCUMBERED', 'PARTIALLY_ENCUMBERED')),
    encumbrance_remarks TEXT,
    
    -- Document References (S3 URLs via File Service)
    land_document_url TEXT,
    survey_map_url TEXT,
    registration_certificate_url TEXT,
    
    -- ========================================
    -- VERIFICATION STATUS (On-field Officer fills)
    -- ========================================
    is_verified BOOLEAN DEFAULT false,
    verified_by BIGINT,
    verified_at TIMESTAMP,
    verification_remarks TEXT,
    
    -- ========================================
    -- STATUS & METADATA
    -- ========================================
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX idx_farms_farmer_id ON farms(farmer_id);
CREATE INDEX idx_farms_pincode ON farms(pincode);
CREATE INDEX idx_farms_state ON farms(state);
CREATE INDEX idx_farms_district ON farms(district);
CREATE INDEX idx_farms_verification_status ON farms(is_verified);
CREATE INDEX idx_farms_encumbrance_status ON farms(encumbrance_status);

-- Composite index for loan-related queries
CREATE INDEX idx_farms_farmer_verified ON farms(farmer_id, is_verified, encumbrance_status);
CREATE INDEX idx_farms_active ON farms(farmer_id, is_active);

