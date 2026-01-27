# =============================================================================
# Krushi Kranti - Cleanup Stale Subscriptions
# =============================================================================
# This script removes subscriptions that belong to users that no longer exist
# in the auth database. Use this when:
# - auth-db was reset but subscription-db was not
# - User IDs in subscription-db don't match current auth-db users
# =============================================================================

Write-Host "=========================================" -ForegroundColor Yellow
Write-Host " Cleanup Stale Subscriptions             " -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

# Get current date for comparison
$authResetDate = Read-Host "Enter the date when auth-db was reset (YYYY-MM-DD) [default: 2026-01-19]"
if ([string]::IsNullOrEmpty($authResetDate)) {
    $authResetDate = "2026-01-19"
}

Write-Host ""
Write-Host "Finding subscriptions created before $authResetDate..." -ForegroundColor Yellow

# Show what will be deleted
Write-Host ""
Write-Host "Payment transactions to delete:" -ForegroundColor Cyan
docker exec subscription-db psql -U postgres -d subscription_db -c "SELECT COUNT(*) as count FROM payment_transactions WHERE subscription_id IN (SELECT subscription_id FROM subscriptions WHERE created_at < '$authResetDate');"

Write-Host ""
Write-Host "Subscriptions to delete:" -ForegroundColor Cyan
docker exec subscription-db psql -U postgres -d subscription_db -c "SELECT COUNT(*) as count FROM subscriptions WHERE created_at < '$authResetDate';"

Write-Host ""
$confirm = Read-Host "Do you want to delete these records? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host ""
    Write-Host "Deleting payment transactions..." -ForegroundColor Green
    docker exec subscription-db psql -U postgres -d subscription_db -c "DELETE FROM payment_transactions WHERE subscription_id IN (SELECT subscription_id FROM subscriptions WHERE created_at < '$authResetDate');"
    
    Write-Host ""
    Write-Host "Deleting subscriptions..." -ForegroundColor Green
    docker exec subscription-db psql -U postgres -d subscription_db -c "DELETE FROM subscriptions WHERE created_at < '$authResetDate';"
    
    Write-Host ""
    Write-Host "Cleanup complete!" -ForegroundColor Green
} else {
    Write-Host "Aborted."
}
