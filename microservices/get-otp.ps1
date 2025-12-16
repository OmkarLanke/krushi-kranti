# Get OTP for a registered user
# Usage: .\get-otp.ps1 -PhoneNumber "9876543210"

param(
    [Parameter(Mandatory=$true)]
    [string]$PhoneNumber
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OTP Retrieval for: $PhoneNumber" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Option 1: Try to get from Redis
Write-Host "Option 1: Checking Redis for existing OTP..." -ForegroundColor Yellow
$redisOtp = docker exec -it redis redis-cli GET "otp:$PhoneNumber" 2>&1

if ($redisOtp -and $redisOtp -ne "(nil)" -and $redisOtp -notmatch "Error") {
    Write-Host "✅ OTP found in Redis!" -ForegroundColor Green
    Write-Host "OTP: $redisOtp" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now verify it using:" -ForegroundColor Cyan
    Write-Host "  `$body = @{ phoneNumber = `"$PhoneNumber`"; otp = `"$redisOtp`" } | ConvertTo-Json" -ForegroundColor White
    Write-Host "  Invoke-WebRequest -Uri `"http://localhost:4005/auth/verify-otp`" -Method POST -Body `$body -ContentType `"application/json`"" -ForegroundColor White
} else {
    Write-Host "❌ No OTP found in Redis (may have expired or not generated)" -ForegroundColor Red
    Write-Host ""
    
    # Option 2: Generate new OTP using resend-otp endpoint
    Write-Host "Option 2: Generating new OTP via API..." -ForegroundColor Yellow
    try {
        $body = @{
            phoneNumber = $PhoneNumber
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "http://localhost:4005/auth/resend-otp" `
            -Method POST -Body $body -ContentType "application/json" `
            -ErrorAction Stop

        $responseData = $response.Content | ConvertFrom-Json
        
        if ($responseData.message) {
            Write-Host "✅ OTP generated successfully!" -ForegroundColor Green
            Write-Host "Response: $($responseData.message)" -ForegroundColor Green
            
            # Extract OTP from message (format: "OTP generated successfully. For testing: 123456")
            if ($responseData.message -match "For testing: (\d+)") {
                $otp = $matches[1]
                Write-Host ""
                Write-Host "Your OTP: $otp" -ForegroundColor Green -BackgroundColor Black
                Write-Host ""
                Write-Host "Verify it using:" -ForegroundColor Cyan
                Write-Host "  `$body = @{ phoneNumber = `"$PhoneNumber`"; otp = `"$otp`" } | ConvertTo-Json" -ForegroundColor White
                Write-Host "  Invoke-WebRequest -Uri `"http://localhost:4005/auth/verify-otp`" -Method POST -Body `$body -ContentType `"application/json`"" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "❌ Error generating OTP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure:" -ForegroundColor Yellow
        Write-Host "  1. Auth service is running on port 4005" -ForegroundColor White
        Write-Host "  2. User with phone number $PhoneNumber exists" -ForegroundColor White
    }
}

Write-Host ""

