-- Create farmers table
CREATE TABLE IF NOT EXISTS farmers (
    id BIGSERIAL PRIMARY KEY,
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);





-- Create indexes
CREATE INDEX idx_farmers_user_id ON farmers(user_id);
CREATE INDEX idx_farmers_pincode ON farmers(pincode);
CREATE INDEX idx_farmers_state ON farmers(state);
CREATE INDEX idx_farmers_district ON farmers(district);

