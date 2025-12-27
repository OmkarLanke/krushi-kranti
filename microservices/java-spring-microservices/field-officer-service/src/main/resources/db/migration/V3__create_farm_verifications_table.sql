-- Create farm_verifications table
CREATE TABLE IF NOT EXISTS farm_verifications (
    verification_id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL, -- Links to farmer-service farms table
    field_officer_id BIGINT NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'IN_PROGRESS')),
    verified_at TIMESTAMP,
    feedback TEXT,
    rejection_reason VARCHAR(500),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_verifications_farm_id ON farm_verifications(farm_id);
CREATE INDEX idx_verifications_field_officer_id ON farm_verifications(field_officer_id);
CREATE INDEX idx_verifications_status ON farm_verifications(verification_status);
CREATE UNIQUE INDEX idx_verifications_unique ON farm_verifications(farm_id, field_officer_id);

