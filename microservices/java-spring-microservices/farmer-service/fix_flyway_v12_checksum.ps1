# Fix Flyway checksum mismatch for V12 migration
# This script updates the checksum in flyway_schema_history table

# Database connection parameters
$host = "localhost"
$port = "5450"
$database = "farmer_db"
$username = "postgres"
$password = "...."  # Update with your password

# New checksum from the error message
$newChecksum = 1742716602

Write-Host "Connecting to PostgreSQL database..." -ForegroundColor Yellow

# Build connection string
$connectionString = "Host=$host;Port=$port;Database=$database;Username=$username;Password=$password"

try {
    # Load Npgsql assembly (PostgreSQL .NET driver)
    # If not installed, you can install via: Install-Package Npgsql
    Add-Type -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\*\Npgsql.dll" -ErrorAction SilentlyContinue
    
    # Alternative: Use psql command line if Npgsql is not available
    $psqlPath = "psql"
    
    # Check if psql is available
    $psqlAvailable = Get-Command psql -ErrorAction SilentlyContinue
    
    if ($psqlAvailable) {
        Write-Host "Using psql command line..." -ForegroundColor Green
        
        # Set PGPASSWORD environment variable
        $env:PGPASSWORD = $password
        
        # SQL command to update checksum
        $sqlCommand = @"
UPDATE flyway_schema_history 
SET checksum = $newChecksum 
WHERE version = '12';

SELECT version, description, checksum, installed_on, success 
FROM flyway_schema_history 
WHERE version = '12';
"@
        
        # Execute SQL using psql
        $sqlCommand | & $psqlPath -h $host -p $port -U $username -d $database
        
        Write-Host "`nChecksum updated successfully!" -ForegroundColor Green
        Write-Host "You can now restart the farmer-service." -ForegroundColor Green
    } else {
        Write-Host "psql command not found. Please use one of these options:" -ForegroundColor Red
        Write-Host ""
        Write-Host "Option 1: Install PostgreSQL client tools" -ForegroundColor Yellow
        Write-Host "Option 2: Use pgAdmin or DBeaver to run this SQL:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "UPDATE flyway_schema_history" -ForegroundColor Cyan
        Write-Host "SET checksum = $newChecksum" -ForegroundColor Cyan
        Write-Host "WHERE version = '12';" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Option 3: Delete the V12 record (safer if migration is idempotent):" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "DELETE FROM flyway_schema_history WHERE version = '12';" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this SQL manually in your database client:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "UPDATE flyway_schema_history" -ForegroundColor Cyan
    Write-Host "SET checksum = $newChecksum" -ForegroundColor Cyan
    Write-Host "WHERE version = '12';" -ForegroundColor Cyan
}
