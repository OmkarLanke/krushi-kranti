# Testing Auth Service

## Prerequisites
- Java 21 installed
- Maven installed
- PostgreSQL and Redis running (via docker-compose)
- Port 4005 available

## Step 1: Start Infrastructure Services

```powershell
cd microservices
docker-compose up -d auth-db redis
```

Wait for services to be healthy (about 10-15 seconds).

## Step 2: Start Auth Service

```powershell
cd microservices/java-spring-microservices
mvn spring-boot:run -pl :auth-service
```

The service will start on `http://localhost:4005`

Wait for the log message: `Started AuthServiceApplication in X.XXX seconds`

## Step 3: Run Tests

### Option 1: Use Test Script
```powershell
cd microservices
.\test-auth-service.ps1
```

### Option 2: Manual Testing

#### 1. Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:4005/actuator/health" -Method GET
```

#### 2. Register User
```powershell
$body = @{
    username = "testfarmer"
    email = "testfarmer@example.com"
    phoneNumber = "9876543210"
    password = "password123"
    role = "FARMER"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:4005/auth/register" -Method POST -Body $body -ContentType "application/json"
```

#### 3. Login
```powershell
$loginBody = @{
    email = "testfarmer@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:4005/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = ($response.Content | ConvertFrom-Json).accessToken
Write-Host "Token: $token"
```

#### 4. Verify OTP (Note: OTP is generated during registration)
```powershell
# Check Redis for OTP (or use a test OTP)
# In production, OTP is sent via SMS
$verifyBody = @{
    phoneNumber = "9876543210"
    otp = "123456"  # Replace with actual OTP from Redis
} | ConvertTo-Json
# To get the OTP from Redis (for test phone), run the following in PowerShell:
# (assumes your redis container is named 'redis', update if needed!)
$otp = docker exec -it redis redis-cli get "otp:9876543210"
Write-Host "OTP from Redis: $otp"
# Then use the value of $otp in the request below:


Invoke-WebRequest -Uri "http://localhost:4005/auth/verify-otp" -Method POST -Body $verifyBody -ContentType "application/json"
```

#### 5. JWKS Endpoint
```powershell
Invoke-WebRequest -Uri "http://localhost:4005/.well-known/jwks.json" -Method GET
```

## Expected Results

1. **Health Check**: HTTP 200 OK
2. **Registration**: HTTP 201 Created with user info
3. **Login**: HTTP 200 OK with JWT token
4. **OTP Verification**: HTTP 200 OK (if valid OTP)
5. **JWKS**: HTTP 200 OK with JWKS JSON

## Troubleshooting

### Service won't start
- Check if PostgreSQL is running: `docker ps | findstr auth-db`
- Check if Redis is running: `docker ps | findstr redis`
- Check if port 4005 is available: `Get-NetTCPConnection -LocalPort 4005`

### Database connection error
- Ensure auth-db container is healthy: `docker ps`
- Check database logs: `docker logs auth-db`

### Redis connection error
- Ensure Redis container is running: `docker ps`
- Test Redis connection: `docker exec -it redis redis-cli ping`

## Next Steps

Once Auth Service is working:
1. Test integration with API Gateway
2. Update API Gateway JWT validation to use Auth Service
3. Test end-to-end authentication flow

