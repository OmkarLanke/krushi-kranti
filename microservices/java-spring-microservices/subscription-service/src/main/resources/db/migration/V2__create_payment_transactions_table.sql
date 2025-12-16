-- Payment transactions table (for detailed payment history)
CREATE TABLE payment_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    subscription_id BIGINT NOT NULL REFERENCES subscriptions(subscription_id),
    farmer_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    
    -- Transaction Details
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    transaction_type VARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    
    -- Payment Gateway Details
    payment_gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(100),
    gateway_order_id VARCHAR(100),
    gateway_payment_id VARCHAR(100),
    gateway_signature VARCHAR(255),
    gateway_response TEXT,
    
    -- Additional Info
    payment_method VARCHAR(50),
    failure_reason TEXT,
    
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('SUBSCRIPTION', 'RENEWAL', 'REFUND')),
    CONSTRAINT chk_transaction_status CHECK (transaction_status IN ('PENDING', 'INITIATED', 'SUCCESS', 'FAILED', 'REFUNDED'))
);

-- Create indexes
CREATE INDEX idx_payment_transactions_subscription_id ON payment_transactions(subscription_id);
CREATE INDEX idx_payment_transactions_farmer_id ON payment_transactions(farmer_id);
CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(transaction_status);
CREATE INDEX idx_payment_transactions_gateway_order_id ON payment_transactions(gateway_order_id);

-- Comments
COMMENT ON TABLE payment_transactions IS 'Payment transaction history for subscriptions';

