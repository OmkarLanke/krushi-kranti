# Test Notification API
# This script tests if the notification API is working correctly

Write-Host "=== Testing Notification API ===" -ForegroundColor Cyan

# Get user ID from user (or use a test value)
$userId = Read-Host "Enter Farmer User ID (e.g., 60)"
$token = Read-Host "Enter JWT Token (or press Enter to skip)"

$baseUrl = "http://localhost:4004"

Write-Host "`n1. Testing through API Gateway (with token)..." -ForegroundColor Yellow
$headers = @{
    "Content-Type" = "application/json"
}
if ($token) {
    $headers["Authorization"] = "Bearer $token"
}

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/notification/unread/FARM_VERIFICATION_OTP" `
        -Method GET `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`n2. Testing directly on Notification Service (with X-User-Id header)..." -ForegroundColor Yellow
$directHeaders = @{
    "Content-Type" = "application/json"
    "X-User-Id" = $userId
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:4016/notification/unread/FARM_VERIFICATION_OTP" `
        -Method GET `
        -Headers $directHeaders `
        -ErrorAction Stop
    
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
