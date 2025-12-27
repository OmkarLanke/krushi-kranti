-- Create field_officers table
CREATE TABLE IF NOT EXISTS field_officers (
    field_officer_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE, -- Links to auth.users.id
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    alternate_phone VARCHAR(15),
    pincode VARCHAR(6),
    village VARCHAR(200),
    district VARCHAR(100),
    taluka VARCHAR(100),
    state VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_field_officers_user_id ON field_officers(user_id);
CREATE INDEX idx_field_officers_pincode ON field_officers(pincode);
CREATE INDEX idx_field_officers_state ON field_officers(state);
CREATE INDEX idx_field_officers_district ON field_officers(district);
CREATE INDEX idx_field_officers_is_active ON field_officers(is_active);

