# Subscription Service

## Overview
The Subscription Service manages farmer subscriptions, payments, and access control for the Krushi Kranti platform.

## Port
- **HTTP**: 4013
- **gRPC**: 9093

## Features
- Subscription management (create, check status, activate)
- Payment processing (mock gateway for testing, ready for real gateway integration)
- Profile completion validation before subscription
- gRPC service for other microservices to check subscription status

## Database
- PostgreSQL: `subscription_db` (port 5451 locally)

## API Endpoints

### REST API

#### Check Subscription Status
```http
GET /subscription/status
Headers: X-User-Id: {userId}
```

#### Check if Subscribed
```http
GET /subscription/check
Headers: X-User-Id: {userId}
```

#### Check Profile Completion
```http
GET /subscription/profile-check?hasMyDetails=true&hasFarmDetails=true&hasCropDetails=true
Headers: X-User-Id: {userId}
```

#### Initiate Payment
```http
POST /subscription/payment/initiate
Headers: X-User-Id: {userId}
Body: {
    "paymentMethod": "UPI" // optional
}
```

#### Complete Payment
```http
POST /subscription/payment/complete
Headers: X-User-Id: {userId}
Body: {
    "transactionId": 1,
    "mockPayment": true,
    "mockPaymentStatus": "SUCCESS" // or "FAILED"
}
```

### gRPC Service

```protobuf
service SubscriptionService {
  rpc CheckSubscription (CheckSubscriptionRequest) returns (CheckSubscriptionResponse);
  rpc GetSubscriptionStatus (GetSubscriptionStatusRequest) returns (SubscriptionStatusResponse);
}
```

## Subscription Flow

1. User completes profile (My Details, Farm Details, Crop Details)
2. User initiates subscription payment
3. User completes payment (mock or real gateway)
4. Subscription is activated for 365 days
5. User can access all features

## Configuration

```yaml
subscription:
  amount: 999        # Subscription amount in INR
  currency: INR
  validity-days: 365 # Subscription validity
  trial-days: 0      # Trial period (future use)
```

## Building

```bash
# Build only subscription-service
mvn clean install -pl :subscription-service -am

# Run locally
mvn spring-boot:run -pl :subscription-service
```

## Running

```bash
# Local (ensure subscription-db is running on port 5451)
mvn spring-boot:run -pl :subscription-service

# Docker
docker-compose up subscription-service
```

## Database Migrations

- `V1__create_subscriptions_table.sql` - Main subscriptions table
- `V2__create_payment_transactions_table.sql` - Payment history

## Future Enhancements

- [ ] Real payment gateway integration (Razorpay, Stripe)
- [ ] KYC verification
- [ ] Document upload for KYC
- [ ] Subscription renewal reminders
- [ ] Refund processing
- [ ] Coupon/discount support

