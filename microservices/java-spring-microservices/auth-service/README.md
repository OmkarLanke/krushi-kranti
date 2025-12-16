# Auth & Identity Service

## Overview
The Auth & Identity Service handles authentication, authorization, and user identity management for the Krushi Kranti platform. It provides JWT token generation, OTP verification, and gRPC endpoints for token validation.

## Port
- **REST API**: 4005
- **gRPC**: 9090

## Features
- User registration and login
- JWT token generation and validation
- OTP-based phone verification
- gRPC service for token validation (for other microservices)
- JWKS endpoint for API Gateway
- Redis integration for OTP storage
- PostgreSQL database for user data

## API Endpoints

### Public Endpoints

#### Register User
```
POST /auth/register
Content-Type: application/json

{
  "username": "farmer123",
  "email": "farmer@example.com",
  "phoneNumber": "9876543210",
  "password": "password123",
  "role": "FARMER"
}
```

#### Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "farmer@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "username": "farmer123",
    "email": "farmer@example.com",
    "phoneNumber": "9876543210",
    "role": "FARMER",
    "isVerified": false
  }
}
```

#### Verify OTP
```
POST /auth/verify-otp
Content-Type: application/json

{
  "phoneNumber": "9876543210",
  "otp": "123456"
}
```

#### JWKS Endpoint (for API Gateway)
```
GET /.well-known/jwks.json
```

### gRPC Endpoints

#### ValidateToken
```protobuf
rpc ValidateToken (TokenValidationRequest) returns (TokenValidationResponse);
```

#### GetUserInfo
```protobuf
rpc GetUserInfo (TokenValidationRequest) returns (UserInfoResponse);
```

## Database Schema

### Users Table
- `id` (BIGSERIAL PRIMARY KEY)
- `username` (VARCHAR(50) UNIQUE)
- `email` (VARCHAR(100) UNIQUE)
- `phone_number` (VARCHAR(15) UNIQUE)
- `password_hash` (VARCHAR(255))
- `role` (VARCHAR(20)) - FARMER, CUSTOMER, VCP_OPERATOR, ADMIN
- `is_active` (BOOLEAN)
- `is_verified` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Refresh Tokens Table
- `id` (BIGSERIAL PRIMARY KEY)
- `user_id` (BIGINT REFERENCES users)
- `token` (VARCHAR(500) UNIQUE)
- `expires_at` (TIMESTAMP)
- `is_revoked` (BOOLEAN)
- `created_at` (TIMESTAMP)

## Configuration

### Application Properties
- `jwt.secret`: JWT signing secret (use environment variable in production)
- `jwt.expiration`: Token expiration time in milliseconds (default: 24 hours)
- `jwt.issuer`: JWT issuer name
- `otp.expiration`: OTP expiration time in seconds (default: 5 minutes)
- `otp.length`: OTP length (default: 6)

### Database
- PostgreSQL connection via `auth-db` container
- Flyway migrations in `src/main/resources/db/migration`

### Redis
- Used for OTP storage
- Connection via `redis` container

## Building

```bash
mvn clean install -pl :auth-service -am
```

## Running

```bash
# Local (requires PostgreSQL and Redis running)
mvn spring-boot:run -pl :auth-service

# Docker
docker-compose up auth-service
```

## Dependencies
- PostgreSQL (database)
- Redis (OTP storage)
- gRPC (internal service communication)

## Security Notes
- Passwords are hashed using BCrypt
- JWT tokens use HMAC-SHA256
- OTPs expire after 5 minutes
- In production, use RSA keys for JWT and expose public key via JWKS

## TODO
- [ ] Implement refresh token mechanism
- [ ] Add RSA key support for JWT (instead of HMAC)
- [ ] Implement SMS service integration for OTP
- [ ] Add rate limiting for login attempts
- [ ] Add password reset functionality
- [ ] Implement account lockout after failed attempts

