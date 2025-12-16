# Testing API Gateway

## Prerequisites
- Java 21 installed
- Maven installed
- Port 4004 available

## Method 1: Run Locally with Maven

```powershell
cd microservices/java-spring-microservices
mvn spring-boot:run -pl :api-gateway
```

The service will start on `http://localhost:4004`

## Method 2: Run with JAR

```powershell
cd microservices/java-spring-microservices
java -jar api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar
```

## Method 3: Run with Docker Compose

```powershell
cd microservices
docker-compose up api-gateway
```

## Test Endpoints

Once the service is running, test the following:

### 1. Health Check (Should work)
```powershell
Invoke-WebRequest -Uri "http://localhost:4004/actuator/health" -Method GET
```

Expected: HTTP 200 with health status

### 2. Public Auth Endpoint (Should work - no JWT required)
```powershell
Invoke-WebRequest -Uri "http://localhost:4004/auth/login" -Method POST
```

Expected: HTTP 503 or connection error (auth-service not available, but gateway should route)

### 3. Protected Endpoint (Should require JWT)
```powershell
Invoke-WebRequest -Uri "http://localhost:4004/farmer/test" -Method GET
```

Expected: HTTP 401 Unauthorized (JWT missing)

### 4. Run Test Script
```powershell
cd microservices
.\test-gateway.ps1
```

## Expected Behavior

1. **Health Check**: Should return 200 OK
2. **Public Routes** (`/auth/login`, `/auth/register`, `/auth/verify-otp`): Should route to auth-service (will fail with 503 if service not available, but gateway is working)
3. **Protected Routes**: Should return 401 Unauthorized if no JWT token is provided
4. **Unknown Routes**: Should return appropriate error

## Troubleshooting

### Service won't start
- Check if port 4004 is already in use: `Get-NetTCPConnection -LocalPort 4004`
- Check Java version: `java -version` (should be 21)
- Check Maven version: `mvn -version`

### Connection Refused
- Ensure the service is running
- Check firewall settings
- Verify the port in `application.yml` matches

### 503 Service Unavailable
- This is expected if downstream services (auth-service, farmer-service, etc.) are not running
- The gateway is working correctly if you get 503 instead of connection refused

## Next Steps

Once the API Gateway is confirmed working:
1. Build Auth Service
2. Implement full JWT validation in the gateway
3. Test end-to-end authentication flow

