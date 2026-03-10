-- Support tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
    ticket_id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    priority VARCHAR(20),
    assigned_admin_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP,
    last_message_by VARCHAR(20),
    unread_for_farmer BOOLEAN NOT NULL DEFAULT FALSE,
    unread_for_admin BOOLEAN NOT NULL DEFAULT TRUE,
    source VARCHAR(50)
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_farmer_id ON support_tickets(farmer_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_last_message_at ON support_tickets(last_message_at DESC);

-- Support ticket messages table
CREATE TABLE IF NOT EXISTS support_ticket_messages (
    message_id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL REFERENCES support_tickets(ticket_id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL,
    sender_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_id ON support_ticket_messages(ticket_id);

