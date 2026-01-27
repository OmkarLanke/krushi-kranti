-- Username: admin1
-- Email: admin1@krushikranti.com
-- Phone: 9999999999
-- Password: admin123
-- Role: ADMIN
-- 
-- The password hash is BCrypt encoded for "admin123"

-- Insert admin user only if a user with this username does NOT already exist.
-- This makes the migration idempotent and safe if admin1 was created manually earlier.
INSERT INTO users (username, email, phone_number, password_hash, role, is_active, is_verified, created_at, updated_at)
SELECT
    'admin1'                                   AS username,
    'admin1@krushikranti.com'                 AS email,
    '9999999999'                              AS phone_number,
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy' AS password_hash, -- BCrypt hash for "admin123"
    'ADMIN'                                   AS role,
    true                                      AS is_active,
    true                                      AS is_verified,
    CURRENT_TIMESTAMP                         AS created_at,
    CURRENT_TIMESTAMP                         AS updated_at
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'admin1'
);

-- Add comment for documentation
COMMENT ON TABLE users IS 'Users table - includes FARMER, FIELD_OFFICER, ADMIN, etc. Admin users should NOT have farmer profiles.';
