# KYC Service

## Overview
The KYC Service handles identity verification for farmers on the Krushi Kranti platform. It integrates with Quick eKYC API for Aadhaar, PAN, and Bank Account verification.

## Port
- **HTTP**: 4014
- **gRPC**: 9094

## Features
- Aadhaar verification (OTP-based)
- PAN verification
- Bank Account verification
- KYC status tracking
- gRPC service for other microservices to check KYC status

## Database
- PostgreSQL: `kyc_db` (port 5452 locally)

## Quick eKYC Integration

This service integrates with [Quick eKYC](https://quickekyc.com) API for identity verification.

### API Credentials
Set these environment variables:
- `QUICKEKYC_BASE_URL`: API base URL
  - Production: `https://api.quickekyc.com`
  - Sandbox: `https://sandbox.quickekyc.com`
- `QUICKEKYC_API_KEY`: Your API key

### Supported Verifications
1. **PAN Validation** - Validates PAN number and retrieves name
2. **Aadhaar Verification** - OTP-based verification with full details
3. **Bank Account Verification** - Account number and IFSC verification

## API Endpoints

### REST API

#### Get KYC Status
```http
GET /kyc/status
Headers: X-User-Id: {userId}
```

#### Check if KYC is Complete
```http
GET /kyc/check
Headers: X-User-Id: {userId}
```

#### Verify PAN
```http
POST /kyc/pan/verify
Headers: X-User-Id: {userId}
Body: {
    "panNumber": "XXXXX1234X"
}
```

#### Generate Aadhaar OTP
```http
POST /kyc/aadhaar/generate-otp
Headers: X-User-Id: {userId}
Body: {
    "aadhaarNumber": "123456789012"
}
```

#### Verify Aadhaar OTP
```http
POST /kyc/aadhaar/verify-otp
Headers: X-User-Id: {userId}
Body: {
    "requestId": "from_generate_otp_response",
    "otp": "123456"
}
```

#### Verify Bank Account
```http
POST /kyc/bank/verify
Headers: X-User-Id: {userId}
Body: {
    "accountNumber": "1234567890123",
    "ifscCode": "SBIN0001234"
}
```

### gRPC Service

```protobuf
service KycService {
  rpc CheckKyc (CheckKycRequest) returns (CheckKycResponse);
  rpc GetKycStatus (GetKycStatusRequest) returns (KycStatusResponse);
}
```

## KYC Flow

### PAN Verification
1. User submits PAN number
2. Service calls Quick eKYC PAN API
3. If valid, PAN is marked as verified

### Aadhaar Verification
1. User submits Aadhaar number
2. Service calls Quick eKYC to generate OTP
3. OTP is sent to Aadhaar-linked mobile
4. User submits OTP
5. Service verifies OTP with Quick eKYC
6. On success, Aadhaar details are stored

### Bank Account Verification
1. User submits account number and IFSC
2. Service calls Quick eKYC Bank API
3. If account exists, bank details are stored

## Database Schema

### kyc_verifications
- Stores KYC status for each user
- Tracks Aadhaar, PAN, Bank verification status

### kyc_verification_logs
- Audit trail for all verification attempts

### aadhaar_otp_sessions
- Temporary storage for Aadhaar OTP sessions

## Configuration

```yaml
quickekyc:
  api:
    base-url: https://sandbox.quickekyc.com
    key: your-api-key
    connect-timeout: 10000
    read-timeout: 30000
```

## Building

```bash
# Build only kyc-service
mvn clean install -pl :kyc-service -am

# Run locally
mvn spring-boot:run -pl :kyc-service
```

## Database Setup

Create the database:
```sql
CREATE DATABASE kyc_db;
```

Flyway will automatically create tables on startup.

## Security Notes

- Aadhaar numbers are hashed (SHA-256) before storage
- Only masked versions of PAN, Aadhaar, and Account numbers are stored
- All verification attempts are logged for audit
- IP addresses are captured for security

## Future Enhancements

- [ ] Document upload for manual KYC
- [ ] KYC document verification
- [ ] Re-verification flow
- [ ] Admin dashboard for KYC management

