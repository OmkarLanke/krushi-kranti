# PowerShell script to fix Flyway checksum mismatch for migration V6
# This connects to PostgreSQL and updates the checksum

$env:PGPASSWORD = "postgres"
$sql = "UPDATE flyway_schema_history SET checksum = 1581828465 WHERE version = '6';"

# Using psql command
& "psql" -h localhost -p 5453 -U postgres -d field_officer_db -c $sql

Write-Host "Checksum updated. You can now restart the service."
