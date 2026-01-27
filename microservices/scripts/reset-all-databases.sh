#!/bin/bash

# =============================================================================
# Krushi Kranti - Database Reset Script
# =============================================================================
# This script resets ALL databases to ensure they are synchronized.
# Use this when:
# - auth-db is reset (user IDs start over)
# - You need a clean slate for testing
# - There are data inconsistencies between services
#
# WARNING: This will DELETE ALL DATA in all databases!
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW} Krushi Kranti - Database Reset Script   ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
echo -e "${RED}WARNING: This will DELETE ALL DATA in all databases!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting database reset...${NC}"

# Function to run SQL on a database container
run_sql() {
    local container=$1
    local database=$2
    local sql=$3
    echo -e "  Running on ${YELLOW}${container}${NC}..."
    docker exec "$container" psql -U postgres -d "$database" -c "$sql" 2>/dev/null || true
}

# Function to truncate tables in a database
truncate_tables() {
    local container=$1
    local database=$2
    local tables=$3
    for table in $tables; do
        echo -e "    Truncating ${table}..."
        docker exec "$container" psql -U postgres -d "$database" -c "TRUNCATE TABLE $table CASCADE;" 2>/dev/null || true
    done
}

echo ""
echo -e "${GREEN}[1/6] Resetting Auth Database...${NC}"
truncate_tables "auth-db" "auth_db" "refresh_tokens users"
# Reset user ID sequence
docker exec auth-db psql -U postgres -d auth_db -c "ALTER SEQUENCE users_user_id_seq RESTART WITH 1;" 2>/dev/null || true

echo ""
echo -e "${GREEN}[2/6] Resetting Farmer Database...${NC}"
truncate_tables "farmer-db" "farmer_db" "crops farms farmers"
# Reset sequences
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE farmers_farmer_id_seq RESTART WITH 1;" 2>/dev/null || true
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE farms_farm_id_seq RESTART WITH 1;" 2>/dev/null || true
docker exec farmer-db psql -U postgres -d farmer_db -c "ALTER SEQUENCE crops_crop_id_seq RESTART WITH 1;" 2>/dev/null || true

echo ""
echo -e "${GREEN}[3/6] Resetting Subscription Database...${NC}"
truncate_tables "subscription-db" "subscription_db" "payment_transactions subscriptions"
# Reset sequences
docker exec subscription-db psql -U postgres -d subscription_db -c "ALTER SEQUENCE subscriptions_subscription_id_seq RESTART WITH 1;" 2>/dev/null || true
docker exec subscription-db psql -U postgres -d subscription_db -c "ALTER SEQUENCE payment_transactions_transaction_id_seq RESTART WITH 1;" 2>/dev/null || true

echo ""
echo -e "${GREEN}[4/6] Resetting Field Officer Database...${NC}"
truncate_tables "field-officer-db" "field_officer_db" "verification_photos farm_verifications field_officer_assignments field_officers"
# Reset sequences
docker exec field-officer-db psql -U postgres -d field_officer_db -c "ALTER SEQUENCE field_officers_field_officer_id_seq RESTART WITH 1;" 2>/dev/null || true

echo ""
echo -e "${GREEN}[5/6] Resetting Notification Database...${NC}"
truncate_tables "notification-db" "notification_db" "notifications" 2>/dev/null || true

echo ""
echo -e "${GREEN}[6/6] Clearing Redis Cache...${NC}"
docker exec redis redis-cli FLUSHALL 2>/dev/null || true
echo "  Redis cache cleared."

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} Database reset complete!                ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "All databases have been reset and are now synchronized."
echo "User IDs, Farmer IDs, Subscription IDs, etc. will start from 1."
echo ""
echo "You may now restart the services or register new users."
