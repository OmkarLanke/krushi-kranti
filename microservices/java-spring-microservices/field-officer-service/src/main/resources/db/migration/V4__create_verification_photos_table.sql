-- Create verification_photos table
CREATE TABLE IF NOT EXISTS verification_photos (
    photo_id BIGSERIAL PRIMARY KEY,
    verification_id BIGINT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    photo_type VARCHAR(50) CHECK (photo_type IN ('FARM_OVERVIEW', 'BOUNDARY', 'CROP', 'DOCUMENT', 'OTHER')),
    description VARCHAR(500),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_verification_photos_verification FOREIGN KEY (verification_id) REFERENCES farm_verifications(verification_id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_photos_verification_id ON verification_photos(verification_id);
CREATE INDEX idx_photos_photo_type ON verification_photos(photo_type);

