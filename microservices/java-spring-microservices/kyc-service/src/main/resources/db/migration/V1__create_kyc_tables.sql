-- KYC Verification Records Table
-- Stores the KYC verification status and details for each user

CREATE TABLE kyc_verifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    
    -- Overall KYC Status
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, PARTIAL, VERIFIED, REJECTED
    
    -- Aadhaar Verification
    aadhaar_verified BOOLEAN NOT NULL DEFAULT FALSE,
    aadhaar_number_masked VARCHAR(16),  -- Store masked: XXXX XXXX 1234
    aadhaar_name VARCHAR(255),
    aadhaar_dob DATE,
    aadhaar_gender VARCHAR(10),
    aadhaar_address TEXT,
    aadhaar_verified_at TIMESTAMP,
    
    -- PAN Verification
    pan_verified BOOLEAN NOT NULL DEFAULT FALSE,
    pan_number_masked VARCHAR(10),  -- Store masked: XXXXX1234X
    pan_name VARCHAR(255),
    pan_verified_at TIMESTAMP,
    
    -- Bank Account Verification
    bank_verified BOOLEAN NOT NULL DEFAULT FALSE,
    bank_account_masked VARCHAR(20),  -- Store masked: XXXXXXXX1234
    bank_ifsc VARCHAR(11),
    bank_name VARCHAR(255),
    bank_account_holder_name VARCHAR(255),
    bank_verified_at TIMESTAMP,
    
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- KYC Verification Logs Table
-- Stores all verification attempts for audit trail
CREATE TABLE kyc_verification_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    verification_type VARCHAR(20) NOT NULL,  -- AADHAAR, PAN, BANK
    request_id VARCHAR(100),  -- Quick eKYC request ID
    status VARCHAR(20) NOT NULL,  -- SUCCESS, FAILED, PENDING
    error_message TEXT,
    request_payload TEXT,  -- Store sanitized request (no sensitive data)
    response_payload TEXT,  -- Store sanitized response
    ip_address VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_kyc_verification_logs_user
        FOREIGN KEY (user_id) REFERENCES kyc_verifications(user_id)
        ON DELETE CASCADE
);

-- Aadhaar OTP Sessions Table
-- Stores temporary OTP sessions for Aadhaar verification
CREATE TABLE aadhaar_otp_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    aadhaar_number_hash VARCHAR(64) NOT NULL,  -- SHA-256 hash for lookup
    client_id VARCHAR(100),  -- From Quick eKYC response
    request_id VARCHAR(100) NOT NULL,  -- Quick eKYC request ID
    otp_sent BOOLEAN NOT NULL DEFAULT FALSE,
    otp_verified BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_aadhaar_otp_sessions_user
        FOREIGN KEY (user_id) REFERENCES kyc_verifications(user_id)
        ON DELETE CASCADE
);

-- Indexes for better query performance
CREATE INDEX idx_kyc_verifications_user_id ON kyc_verifications(user_id);
CREATE INDEX idx_kyc_verifications_status ON kyc_verifications(kyc_status);
CREATE INDEX idx_kyc_verification_logs_user_id ON kyc_verification_logs(user_id);
CREATE INDEX idx_kyc_verification_logs_type ON kyc_verification_logs(verification_type);
CREATE INDEX idx_aadhaar_otp_sessions_user_id ON aadhaar_otp_sessions(user_id);
CREATE INDEX idx_aadhaar_otp_sessions_hash ON aadhaar_otp_sessions(aadhaar_number_hash);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_kyc_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_kyc_verifications_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_kyc_updated_at();

