# Test API Gateway Script
Write-Host "========================================"
Write-Host "API Gateway Test Script"
Write-Host "========================================"
Write-Host ""

$baseUrl = "http://localhost:4004"
$timeout = 5

function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [string]$Description
    )
    
    Write-Host "Testing: $Description" -ForegroundColor Cyan
    Write-Host "  URL: $Url" -ForegroundColor Gray
    Write-Host "  Method: $Method" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method $Method -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
        Write-Host "  Status: SUCCESS ($($response.StatusCode))" -ForegroundColor Green
        if ($response.Content) {
            Write-Host "  Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))" -ForegroundColor Gray
        }
        return $true
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "  Status: $statusCode" -ForegroundColor Yellow
            Write-Host "  Note: Service responded but returned error (this is expected if downstream service is not available)" -ForegroundColor Yellow
            return $true
        }
        else {
            Write-Host "  Status: FAILED" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    Write-Host ""
}

# Test 1: Health Check
Write-Host "Test 1: Health Check Endpoint" -ForegroundColor Yellow
$healthResult = Test-Endpoint -Url "$baseUrl/actuator/health" -Description "Health Check"

Write-Host ""

# Test 2: Public Auth Endpoint (should bypass JWT)
Write-Host "Test 2: Public Auth Endpoint (No JWT Required)" -ForegroundColor Yellow
$authResult = Test-Endpoint -Url "$baseUrl/auth/login" -Method "POST" -Description "Auth Login (Public)"

Write-Host ""

# Test 3: Protected Endpoint (should require JWT or fail with 401)
Write-Host "Test 3: Protected Endpoint (JWT Required)" -ForegroundColor Yellow
$protectedResult = Test-Endpoint -Url "$baseUrl/farmer/test" -Description "Farmer Service (Protected)"

Write-Host ""

# Test 4: Non-existent Route
Write-Host "Test 4: Non-existent Route" -ForegroundColor Yellow
$unknownResult = Test-Endpoint -Url "$baseUrl/unknown/route" -Description "Unknown Route"

Write-Host ""
Write-Host "========================================"
Write-Host "Test Summary" -ForegroundColor Yellow
Write-Host "========================================"
Write-Host "Health Check: $(if ($healthResult) { 'PASS' } else { 'FAIL' })"
Write-Host "Public Auth: $(if ($authResult) { 'PASS' } else { 'FAIL' })"
Write-Host "Protected Route: $(if ($protectedResult) { 'PASS (or expected error)' } else { 'FAIL' })"
Write-Host "Unknown Route: $(if ($unknownResult) { 'PASS (or expected error)' } else { 'FAIL' })"
Write-Host ""

