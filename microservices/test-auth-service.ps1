# Test Auth Service Script
Write-Host "========================================"
Write-Host "Auth Service Test Script"
Write-Host "========================================"
Write-Host ""

$baseUrl = "http://localhost:4005"
$timeout = 10

function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [string]$Body = $null,
        [string]$Description,
        [hashtable]$Headers = @{}
    )
    
    Write-Host "Testing: $Description" -ForegroundColor Cyan
    Write-Host "  URL: $Url" -ForegroundColor Gray
    Write-Host "  Method: $Method" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            UseBasicParsing = $true
            TimeoutSec = $timeout
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        $response = Invoke-WebRequest @params -ErrorAction Stop
        Write-Host "  Status: SUCCESS ($($response.StatusCode))" -ForegroundColor Green
        if ($response.Content) {
            $content = $response.Content
            # Handle both string and byte array responses
            if ($content -is [byte[]]) {
                $content = [System.Text.Encoding]::UTF8.GetString($content)
            }
            if ($content -is [string] -and $content.Length -gt 300) {
                $content = $content.Substring(0, 300) + "..."
            }
            Write-Host "  Response: $content" -ForegroundColor Gray
        }
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "  Status: $statusCode" -ForegroundColor Yellow
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "  Response: $responseBody" -ForegroundColor Gray
            return $statusCode
        }
        else {
            Write-Host "  Status: FAILED" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            return $null
        }
    }
    Write-Host ""
}

# Test 1: Health Check
Write-Host "Test 1: Health Check Endpoint" -ForegroundColor Yellow
$healthResult = Test-Endpoint -Url "$baseUrl/actuator/health" -Description "Health Check"

Write-Host ""

# Test 2: Register User
Write-Host "Test 2: Register User" -ForegroundColor Yellow
# Generate unique email to avoid conflicts
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$registerBody = @{
    username = "testfarmer$timestamp"
    email = "testfarmer$timestamp@example.com"
    phoneNumber = "9876543$timestamp".Substring(0, 10)
    password = "password123"
    role = "FARMER"
} | ConvertTo-Json

$registerResult = Test-Endpoint -Url "$baseUrl/auth/register" -Method "POST" -Body $registerBody -Description "User Registration"

Write-Host ""

# Extract token if login succeeds
$token = $null
$registeredEmail = $null
if ($registerResult -and ($registerResult.StatusCode -eq 201 -or $registerResult.StatusCode -eq 200)) {
    # Extract email from registration response
    try {
        $registerData = $registerResult.Content | ConvertFrom-Json
        if ($registerData.data -and $registerData.data.email) {
            $registeredEmail = $registerData.data.email
        } else {
            # Fallback to generated email
            $registeredEmail = "testfarmer$timestamp@example.com"
        }
    } catch {
        $registeredEmail = "testfarmer$timestamp@example.com"
    }
    
    Write-Host "Test 3: Login" -ForegroundColor Yellow
    $loginBody = @{
        email = $registeredEmail
        password = "password123"
    } | ConvertTo-Json
    
    $loginResult = Test-Endpoint -Url "$baseUrl/auth/login" -Method "POST" -Body $loginBody -Description "User Login"
    
    if ($loginResult -and $loginResult.Content) {
        $loginData = $loginResult.Content | ConvertFrom-Json
        if ($loginData.accessToken) {
            $token = $loginData.accessToken
            Write-Host "  Token extracted: $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Green
        }
    }
}

Write-Host ""

# Test 4: JWKS Endpoint
Write-Host "Test 4: JWKS Endpoint" -ForegroundColor Yellow
$jwksResult = Test-Endpoint -Url "$baseUrl/.well-known/jwks.json" -Description "JWKS Endpoint"

Write-Host ""
Write-Host "========================================"
Write-Host "Test Summary" -ForegroundColor Yellow
Write-Host "========================================"
Write-Host "Health Check: $(if ($healthResult -and $healthResult.StatusCode -eq 200) { 'PASS' } else { 'FAIL' })"
Write-Host "Registration: $(if ($registerResult -and ($registerResult.StatusCode -eq 201 -or $registerResult.StatusCode -eq 200)) { 'PASS' } else { 'FAIL' })"
Write-Host "Login: $(if ($token) { 'PASS' } else { 'FAIL' })"
Write-Host "JWKS: $(if ($jwksResult -and $jwksResult.StatusCode -eq 200) { 'PASS' } else { 'FAIL' })"
Write-Host ""

