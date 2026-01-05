# Quick Fix for V12 Checksum Mismatch

## Problem
Flyway is detecting that migration V12 has been modified after it was already applied to the database.

## Solution (Choose ONE)

### Option 1: Delete V12 Record (Recommended - Safest)
Since the migration is now idempotent, delete the record and let it re-run:

```sql
DELETE FROM flyway_schema_history WHERE version = '12';
```

**Why this works:** The migration now checks if columns exist before renaming, so it's safe to re-run even if columns are already renamed.

### Option 2: Update Checksum
If you prefer to keep V12 marked as "already applied":

```sql
UPDATE flyway_schema_history 
SET checksum = 1742716602 
WHERE version = '12';
```

## How to Run

### Using pgAdmin:
1. Connect to `localhost:5450` / `farmer_db`
2. Open Query Tool (Tools → Query Tool)
3. Paste one of the SQL commands above
4. Click Execute (F5)
5. Restart farmer-service

### Using DBeaver:
1. Connect to `localhost:5450` / `farmer_db`
2. Open SQL Editor
3. Paste one of the SQL commands above
4. Click Execute (Ctrl+Enter)
5. Restart farmer-service

### Using psql (if installed):
```powershell
$env:PGPASSWORD = "your_password"
psql -h localhost -p 5450 -U postgres -d farmer_db -c "DELETE FROM flyway_schema_history WHERE version = '12';"
```

## After Running
Restart the farmer-service:
```powershell
mvn spring-boot:run -pl :farmer-service
```

The service should start successfully!
