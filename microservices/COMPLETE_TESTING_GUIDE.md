# Complete Testing Guide for Auth Service

## Current Status ✅
- ✅ Docker containers running (PostgreSQL, Redis)
- ✅ Database visible in pgAdmin
- ✅ IntelliJ connected to database
- ✅ Maven compilation successful

## Step 1: Start Auth Service

### Option A: Run from IntelliJ
1. Open `AuthServiceApplication.java`
2. Right-click → **Run 'AuthServiceApplication'**
3. Wait for: `Started AuthServiceApplication in X.XXX seconds`

### Option B: Run from Terminal
```powershell
cd microservices\java-spring-microservices
mvn spring-boot:run -pl :auth-service
```

**Expected Output:**
```
- Database connection established
- Flyway migrations applied
- Redis connection working
- gRPC server started on port 9090
- Service started on port 4005
```

## Step 2: Verify Service is Running

### Quick Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:4005/actuator/health" -UseBasicParsing
```

**Expected:** HTTP 200 with health status

### Check Service Logs
Look for:
- ✅ `HikariPool-1 - Start completed`
- ✅ `Flyway migrations applied`
- ✅ `Started AuthServiceApplication`

## Step 3: Run Automated Tests

### Use Test Script
```powershell
cd microservices
.\test-auth-service.ps1
```

This will test:
1. Health Check
2. User Registration
3. User Login
4. JWKS Endpoint

## Step 4: Manual API Testing

### 1. Health Check
```powershell
curl http://localhost:4005/actuator/health
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### 2. Register a New User
```powershell
$registerBody = @{
    username = "testfarmer"
    email = "testfarmer@example.com"
    phoneNumber = "9876543210"
    password = "password123"
    role = "FARMER"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:4005/auth/register" `
    -Method POST -Body $registerBody -ContentType "application/json"

$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**Expected Response (HTTP 201):**
```json
{
  "message": "User registered successfully. Please verify OTP.",
  "data": {
    "id": 1,
    "username": "testfarmer",
    "email": "testfarmer@example.com",
    "phoneNumber": "9876543210",
    "role": "FARMER",
    "isVerified": false
  }
}
```

**What Happens:**
- User is created in database
- OTP is generated and stored in Redis
- Password is hashed using BCrypt

### 3. Check OTP in Redis (for testing)
```powershell
docker exec -it redis redis-cli KEYS "otp:*"
docker exec -it redis redis-cli GET "otp:9876543210"
```

### 4. Verify OTP
```powershell
# Replace "123456" with actual OTP from Redis
$verifyBody = @{
    phoneNumber = "9876543210"
    otp = "123456"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:4005/auth/verify-otp" `
    -Method POST -Body $verifyBody -ContentType "application/json"

$response.Content
```

**Expected Response (HTTP 200):**
```json
{
  "message": "OTP verified successfully",
  "data": null
}
```

### 5. Login
```powershell
$loginBody = @{
    email = "testfarmer@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:4005/auth/login" `
    -Method POST -Body $loginBody -ContentType "application/json"

$loginData = $response.Content | ConvertFrom-Json
$token = $loginData.accessToken
Write-Host "Token: $token"
```

**Expected Response (HTTP 200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "username": "testfarmer",
    "email": "testfarmer@example.com",
    "phoneNumber": "9876543210",
    "role": "FARMER",
    "isVerified": true
  }
}
```

### 6. JWKS Endpoint (for API Gateway)
```powershell
$response = Invoke-WebRequest -Uri "http://localhost:4005/.well-known/jwks.json" -UseBasicParsing
$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**Expected Response (HTTP 200):**
```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "...",
      "use": "sig",
      "n": "...",
      "e": "AQAB"
    }
  ]
}
```

### 7. Verify User in Database (pgAdmin)
1. Open pgAdmin
2. Connect to `Krushi Kranti - Auth DB (Docker)`
3. Navigate to: `auth_db` → `Schemas` → `public` → `Tables` → `users`
4. Right-click `users` → **View/Edit Data** → **All Rows**
5. You should see the registered user

## Step 5: Test Error Cases

### 1. Duplicate Registration
```powershell
# Try registering same email again
$registerBody = @{
    username = "testfarmer2"
    email = "testfarmer@example.com"  # Same email
    phoneNumber = "9876543211"
    password = "password123"
    role = "FARMER"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:4005/auth/register" `
    -Method POST -Body $registerBody -ContentType "application/json"
```

**Expected:** HTTP 400 - "Email already exists"

### 2. Invalid Login
```powershell
$loginBody = @{
    email = "testfarmer@example.com"
    password = "wrongpassword"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:4005/auth/login" `
    -Method POST -Body $loginBody -ContentType "application/json"
```

**Expected:** HTTP 401 - "Invalid email or password"

### 3. Invalid OTP
```powershell
$verifyBody = @{
    phoneNumber = "9876543210"
    otp = "999999"  # Wrong OTP
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:4005/auth/verify-otp" `
    -Method POST -Body $verifyBody -ContentType "application/json"
```

**Expected:** HTTP 400 - "Invalid OTP"

## Step 6: Verify Database Changes

### Check Users Table
```sql
SELECT * FROM users;
```

### Check Refresh Tokens Table (after login)
```sql
SELECT * FROM refresh_tokens;
```

### Check Flyway Migration History
```sql
SELECT * FROM flyway_schema_history;
```

## Troubleshooting

### Service Won't Start
- Check if port 4005 is available: `Get-NetTCPConnection -LocalPort 4005`
- Check Docker containers: `docker ps`
- Check logs in IntelliJ console

### Database Connection Error
- Verify auth-db is running: `docker ps --filter "name=auth-db"`
- Check database logs: `docker logs auth-db`
- Verify connection string in `application.yml`

### Redis Connection Error
- Verify Redis is running: `docker ps --filter "name=redis"`
- Test Redis: `docker exec -it redis redis-cli ping`
- Should return: `PONG`

### OTP Not Found
- OTP expires after 5 minutes (300 seconds)
- Check Redis: `docker exec -it redis redis-cli KEYS "otp:*"`
- Register again to generate new OTP

## Next Steps After Testing

Once all tests pass:
1. ✅ Test API Gateway integration
2. ✅ Update API Gateway JWT validation
3. ✅ Test end-to-end authentication flow
4. ✅ Start building Farmer Service
5. ✅ Implement Kafka event publishing

