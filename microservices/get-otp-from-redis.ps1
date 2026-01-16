# Get OTP from Redis for farm verification
# Usage: .\get-otp-from-redis.ps1 -FarmId 35 -FarmerUserId 60

param(
    [Parameter(Mandatory=$true)]
    [int]$FarmId,
    
    [Parameter(Mandatory=$true)]
    [int]$FarmerUserId
)

Write-Host "=== Getting OTP from Redis ===" -ForegroundColor Cyan
Write-Host "Farm ID: $FarmId" -ForegroundColor Yellow
Write-Host "Farmer User ID: $FarmerUserId" -ForegroundColor Yellow

$otpKey = "farm_verification_otp:$FarmId`:$FarmerUserId"
Write-Host "Redis Key: $otpKey" -ForegroundColor Yellow

$otpValue = docker exec redis redis-cli GET $otpKey

if ($otpValue) {
    Write-Host "`nOTP Found!" -ForegroundColor Green
    Write-Host "Raw Value: $otpValue" -ForegroundColor Green
    
    # OTP format is: "OTP:fieldOfficerUserId"
    $parts = $otpValue -split ':'
    if ($parts.Length -ge 1) {
        $otp = $parts[0]
        Write-Host "OTP: $otp" -ForegroundColor Green
        
        if ($parts.Length -ge 2) {
            $fieldOfficerUserId = $parts[1]
            Write-Host "Field Officer User ID: $fieldOfficerUserId" -ForegroundColor Green
        }
    }
} else {
    Write-Host "`nOTP not found in Redis" -ForegroundColor Red
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "1. OTP has expired (default: 10 minutes)" -ForegroundColor Yellow
    Write-Host "2. OTP was already validated and removed" -ForegroundColor Yellow
    Write-Host "3. Wrong Farm ID or Farmer User ID" -ForegroundColor Yellow
    Write-Host "`nTry listing all OTP keys:" -ForegroundColor Yellow
    Write-Host "docker exec redis redis-cli KEYS 'farm_verification_otp:*'" -ForegroundColor Cyan
}

Write-Host "`n=== Checking Validation Status ===" -ForegroundColor Cyan
$validationKey = "farm_verification_otp_validated:$FarmId`:$FarmerUserId"
$validationStatus = docker exec redis redis-cli GET $validationKey

if ($validationStatus) {
    Write-Host "Validation Status: $validationStatus" -ForegroundColor Green
} else {
    Write-Host "Validation Status: Not validated" -ForegroundColor Yellow
}
