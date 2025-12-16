# Quick Test Guide - Auth Service

## Current Status
✅ **Build**: SUCCESS (JAR file created)  
✅ **Infrastructure**: Running (PostgreSQL, Redis in Docker)  
⚠️ **Docker Build**: Has issue (needs fix)  
✅ **Local Run**: Ready to test

## Quick Test Steps

### Option 1: Run Locally (Recommended for now)

1. **Start the service locally:**
   ```powershell
   cd microservices\java-spring-microservices
   mvn spring-boot:run -pl :auth-service
   ```

2. **Wait for startup** (about 20-30 seconds)
   - Look for: `Started AuthServiceApplication in X.XXX seconds`

3. **Test the service:**
   ```powershell
   cd microservices
   .\test-auth-service.ps1
   ```

### Option 2: Fix Docker Build (For later)

The Dockerfile needs to be updated to handle the multi-module structure properly. For now, local testing works perfectly.

## Manual Test Commands

Once the service is running on `http://localhost:4005`:

### 1. Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:4005/actuator/health" -Method GET
```

### 2. Register User
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

### 3. Login
```powershell
$loginBody = @{
    email = "testfarmer@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:4005/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = ($response.Content | ConvertFrom-Json).accessToken
Write-Host "Token: $token"
```

### 4. JWKS Endpoint
```powershell
Invoke-WebRequest -Uri "http://localhost:4005/.well-known/jwks.json" -Method GET
```

## Next Steps

Once Auth Service is tested and working:
1. Fix Dockerfile for proper Docker builds
2. Test integration with API Gateway
3. Update API Gateway JWT validation
4. Proceed with Farmer Service development

