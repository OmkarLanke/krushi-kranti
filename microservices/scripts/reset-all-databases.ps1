# =============================================================================
# Krushi Kranti - Database Reset Script (PowerShell)
# =============================================================================
# This script resets ALL databases to ensure they are synchronized.
# Use this when:
# - auth-db is reset (user IDs start over)
# - You need a clean slate for testing
# - There are data inconsistencies between services
#
# WARNING: This will DELETE ALL DATA in all databases!
# =============================================================================

Write-Host "=========================================" -ForegroundColor Yellow
Write-Host " Krushi Kranti - Database Reset Script   " -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "WARNING: This will DELETE ALL DATA in all databases!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Aborted."
    exit 0
}

Write-Host ""
Write-Host "Starting database reset..." -ForegroundColor Green

# Function to run SQL on a database container
function Run-SQL {
    param($container, $database, $sql)
    Write-Host "  Running on $container..." -ForegroundColor Yellow
    docker exec $container psql -U postgres -d $database -c $sql 2>$null
}

# Function to truncate tables
function Truncate-Tables {
    param($container, $database, $tables)
    foreach ($table in $tables) {
        Write-Host "    Truncating $table..." -ForegroundColor Gray
        docker exec $container psql -U postgres -d $database -c "TRUNCATE TABLE $table CASCADE;" 2>$null
    }
}

Write-Host ""
Write-Host "[1/6] Resetting Auth Database..." -ForegroundColor Green
Truncate-Tables -container "auth-db" -database "auth_db" -tables @("refresh_tokens", "users")
docker exec auth-db psql -U postgres -d auth_db -c "ALTER SEQUENCE users_user_id_seq RESTART WITH 1;" 2>$null

Write-Host ""
Write-Host "[2/6] Resetting Farmer Database..." -ForegroundColor Green
Truncate-Tables -container "farmer-db" -database "farmer_db" -tables @("crops", "farms", "farmers")
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE farmers_farmer_id_seq RESTART WITH 1;" 2>$null
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE farms_farm_id_seq RESTART WITH 1;" 2>$null
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE crops_crop_id_seq RESTART WITH 1;" 2>$null

Write-Host ""
Write-Host "[3/6] Resetting Subscription Database..." -ForegroundColor Green
Truncate-Tables -container "subscription-db" -database "subscription_db" -tables @("payment_transactions", "subscriptions")
docker exec subscription-db psql -U postgres -d subscription_db -c "ALTER SEQUENCE subscriptions_subscription_id_seq RESTART WITH 1;" 2>$null
docker exec subscription-db psql -U postgres -d subscription_db -c "ALTER SEQUENCE payment_transactions_transaction_id_seq RESTART WITH 1;" 2>$null

Write-Host ""
Write-Host "[4/6] Resetting Field Officer Database..." -ForegroundColor Green
Truncate-Tables -container "field-officer-db" -database "field_officer_db" -tables @("verification_photos", "farm_verifications", "field_officer_assignments", "field_officers")
docker exec field-officer-db psql -U postgres -d field_officer_db -c "ALTER SEQUENCE field_officers_field_officer_id_seq RESTART WITH 1;" 2>$null

Write-Host ""
Write-Host "[5/6] Resetting Notification Database..." -ForegroundColor Green
Truncate-Tables -container "notification-db" -database "notification_db" -tables @("notifications") 2>$null

Write-Host ""
Write-Host "[6/6] Clearing Redis Cache..." -ForegroundColor Green
docker exec redis redis-cli FLUSHALL 2>$null
Write-Host "  Redis cache cleared."

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " Database reset complete!                " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "All databases have been reset and are now synchronized."
Write-Host "User IDs, Farmer IDs, Subscription IDs, etc. will start from 1."
Write-Host ""
Write-Host "You may now restart the services or register new users."
