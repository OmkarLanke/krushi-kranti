-- Subscriptions table
CREATE TABLE subscriptions (
    subscription_id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    
    -- Subscription Details
    subscription_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    subscription_amount DECIMAL(10, 2) NOT NULL DEFAULT 999.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    
    -- Payment Details
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_transaction_id VARCHAR(100),
    payment_gateway VARCHAR(50),
    payment_method VARCHAR(50),
    payment_date TIMESTAMP,
    
    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_subscription_status CHECK (subscription_status IN ('PENDING', 'ACTIVE', 'EXPIRED', 'CANCELLED')),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('PENDING', 'INITIATED', 'COMPLETED', 'FAILED', 'REFUNDED'))
);

-- Create indexes
CREATE INDEX idx_subscriptions_farmer_id ON subscriptions(farmer_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(subscription_status);
CREATE INDEX idx_subscriptions_payment_status ON subscriptions(payment_status);
CREATE INDEX idx_subscriptions_end_date ON subscriptions(subscription_end_date);

-- Comments
COMMENT ON TABLE subscriptions IS 'Farmer subscription records';
COMMENT ON COLUMN subscriptions.subscription_status IS 'PENDING: awaiting payment, ACTIVE: paid and valid, EXPIRED: past end date, CANCELLED: user cancelled';
COMMENT ON COLUMN subscriptions.payment_status IS 'PENDING: not started, INITIATED: payment started, COMPLETED: payment successful, FAILED: payment failed, REFUNDED: money returned';

