-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    recipient_user_id BIGINT NOT NULL,
    recipient_phone_number VARCHAR(15),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    data TEXT, -- JSON string of additional data
    priority VARCHAR(10) DEFAULT 'MEDIUM',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_id ON notifications(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_type ON notifications(event_type);
CREATE INDEX IF NOT EXISTS idx_read_status ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_user_read ON notifications(recipient_user_id, is_read);

-- Add comment to table
COMMENT ON TABLE notifications IS 'Stores notifications for users consumed from Kafka events';
COMMENT ON COLUMN notifications.data IS 'JSON string containing additional notification data (OTP, farmId, etc.)';
