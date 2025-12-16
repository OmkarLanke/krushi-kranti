# Test Auth Service Connection Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auth Service Connection Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:4005"
$timeout = 5

# Step 1: Check if service is running
Write-Host "Step 1: Checking if Auth Service is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-WebRequest -Uri "$baseUrl/actuator/health" -Method GET -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
    Write-Host "✅ Auth Service is RUNNING" -ForegroundColor Green
    Write-Host "   Status Code: $($healthCheck.StatusCode)" -ForegroundColor Gray
    $content = $healthCheck.Content
    if ($content -is [byte[]]) {
        $content = [System.Text.Encoding]::UTF8.GetString($content)
    }
    try {
        $healthData = $content | ConvertFrom-Json
        Write-Host "   Status: $($healthData.status)" -ForegroundColor Gray
        if ($healthData.components) {
            Write-Host "   Components:" -ForegroundColor Gray
            if ($healthData.components.db) { Write-Host "     - Database: $($healthData.components.db.status)" -ForegroundColor Gray }
            if ($healthData.components.redis) { Write-Host "     - Redis: $($healthData.components.redis.status)" -ForegroundColor Gray }
        }
    } catch {
        Write-Host "   Response: $($content.Substring(0, [Math]::Min(200, $content.Length)))" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "❌ Auth Service is NOT RUNNING" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start the service, run one of these:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Using Maven (Recommended)" -ForegroundColor Cyan
    Write-Host "  cd java-spring-microservices" -ForegroundColor White
    Write-Host "  mvn spring-boot:run -pl :auth-service" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Using IntelliJ" -ForegroundColor Cyan
    Write-Host "  1. Open AuthServiceApplication.java" -ForegroundColor White
    Write-Host "  2. Right-click → Run 'AuthServiceApplication'" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 3: Using JAR file" -ForegroundColor Cyan
    Write-Host "  cd java-spring-microservices" -ForegroundColor White
    Write-Host "  java -jar auth-service/target/auth-service-0.0.1-SNAPSHOT.jar" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Step 2: Test Database Connection (via health endpoint)
Write-Host "Step 2: Testing Database Connection..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "$baseUrl/actuator/health" -Method GET -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
    $content = $health.Content
    if ($content -is [byte[]]) {
        $content = [System.Text.Encoding]::UTF8.GetString($content)
    }
    $healthData = $content | ConvertFrom-Json
    if ($healthData.components.db -and $healthData.components.db.status -eq "UP") {
        Write-Host "✅ Database connection: HEALTHY" -ForegroundColor Green
        Write-Host "   Database: $($healthData.components.db.details.database)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Database connection: Check status" -ForegroundColor Yellow
    }
    Write-Host ""
} catch {
    Write-Host "❌ Could not check database status" -ForegroundColor Red
    Write-Host ""
}

# Step 3: Test Redis Connection
Write-Host "Step 3: Testing Redis Connection..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "$baseUrl/actuator/health" -Method GET -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
    $content = $health.Content
    if ($content -is [byte[]]) {
        $content = [System.Text.Encoding]::UTF8.GetString($content)
    }
    $healthData = $content | ConvertFrom-Json
    if ($healthData.components.redis -and $healthData.components.redis.status -eq "UP") {
        Write-Host "✅ Redis connection: HEALTHY" -ForegroundColor Green
        if ($healthData.components.redis.details.version) {
            Write-Host "   Redis Version: $($healthData.components.redis.details.version)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Redis connection: Check health endpoint details" -ForegroundColor Yellow
    }
    Write-Host ""
} catch {
    Write-Host "❌ Could not check Redis status" -ForegroundColor Red
    Write-Host ""
}

# Step 4: Test JWKS Endpoint
Write-Host "Step 4: Testing JWKS Endpoint..." -ForegroundColor Yellow
try {
    $jwks = Invoke-WebRequest -Uri "$baseUrl/.well-known/jwks.json" -Method GET -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
    Write-Host "✅ JWKS endpoint: WORKING" -ForegroundColor Green
    Write-Host "   Status Code: $($jwks.StatusCode)" -ForegroundColor Gray
    $jwksData = $jwks.Content | ConvertFrom-Json
    if ($jwksData.keys) {
        Write-Host "   Keys available: $($jwksData.keys.Count)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "❌ JWKS endpoint: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 5: Test Registration Endpoint (Quick Test)
Write-Host "Step 5: Testing Registration Endpoint..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$testBody = @{
    username = "testconnection$timestamp"
    email = "testconnection$timestamp@example.com"
    phoneNumber = "9999999$timestamp".Substring(0, 10)
    password = "password123"
    role = "FARMER"
} | ConvertTo-Json

try {
    $register = Invoke-WebRequest -Uri "$baseUrl/auth/register" -Method POST -Body $testBody -ContentType "application/json" -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
    Write-Host "✅ Registration endpoint: WORKING" -ForegroundColor Green
    Write-Host "   Status Code: $($register.StatusCode)" -ForegroundColor Gray
    Write-Host ""
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 409) {
        Write-Host "✅ Registration endpoint: RESPONDING (user may already exist)" -ForegroundColor Green
        Write-Host "   Status Code: $statusCode" -ForegroundColor Gray
    } else {
        Write-Host "❌ Registration endpoint: FAILED" -ForegroundColor Red
        Write-Host "   Status Code: $statusCode" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Connection Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Service Status: RUNNING" -ForegroundColor Green
Write-Host "✅ Health Endpoint: ACCESSIBLE" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  Run full test suite: .\test-auth-service.ps1" -ForegroundColor White
Write-Host "  Get OTP for user: .\get-otp.ps1 -PhoneNumber '9876543210'" -ForegroundColor White
Write-Host ""

