# pgAdmin Setup for Docker PostgreSQL

## Issue
pgAdmin is connecting to a different PostgreSQL instance (likely your local installation on port 5432), not the Docker container running on port 5433.

## Solution: Add Docker PostgreSQL Server in pgAdmin

### Step 1: Open pgAdmin
1. Launch pgAdmin
2. In the left sidebar, right-click on **Servers**
3. Select **Register** → **Server...**

### Step 2: Configure General Tab
1. **General** tab:
   - **Name:** `Krushi Kranti - Auth DB (Docker)` (or any name you prefer)
   - **Server group:** `Servers` (default)
   - **Comments:** `Docker container: auth-db on port 5433`

### Step 3: Configure Connection Tab
**Important:** Use these exact settings:

- **Host name/address:** `localhost` ✅
- **Port:** `5433` ✅ (NOT 5432!)
- **Maintenance database:** `auth_db`
- **Username:** `postgres`
- **Password:** `....` (your database password)
- ✅ Check **Save password** (optional, for convenience)

### Step 4: Test Connection
1. Click **Save** button
2. pgAdmin will attempt to connect
3. If successful, you'll see the server appear in the left sidebar

### Step 5: Verify Database
1. Expand the server: `Krushi Kranti - Auth DB (Docker)`
2. Expand **Databases**
3. You should see:
   - `auth_db` ✅
   - `postgres` (default database)
   - `template0`
   - `template1`

### Step 6: Explore auth_db
1. Expand `auth_db`
2. Expand **Schemas** → **public** → **Tables**
3. You should see:
   - `users` (created by Flyway migration)
   - `refresh_tokens` (created by Flyway migration)
   - `flyway_schema_history` (Flyway's migration tracking table)

## Why This Happens

You likely have **two PostgreSQL instances**:

1. **Local PostgreSQL** (port 5432)
   - Installed on your Windows machine
   - Default port: 5432
   - This is what pgAdmin was connecting to by default

2. **Docker PostgreSQL** (port 5433)
   - Container: `auth-db`
   - Mapped port: 5433 → 5432
   - Database: `auth_db`
   - This is what your application uses

## Quick Verification

To see which databases are in each instance:

### Docker Container (auth_db exists here):
```powershell
docker exec -it auth-db psql -U postgres -c "\l"
```

### Local PostgreSQL (if running):
```powershell
psql -h localhost -p 5432 -U postgres -c "\l"
```

## Troubleshooting

### If connection fails:

1. **Check Docker container is running:**
   ```powershell
   docker ps --filter "name=auth-db"
   ```

2. **Test connection from command line:**
   ```powershell
   psql -h localhost -p 5433 -U postgres -d auth_db
   ```
   Enter password when prompted.

3. **Check port is not blocked:**
   ```powershell
   netstat -an | findstr "5433"
   ```
   Should show `LISTENING` state.

4. **Verify password:**
   - Password should be: `....` (as configured in docker-compose.yml)

## Summary

- **IntelliJ:** Connected to `localhost:5433` ✅
- **pgAdmin:** Needs a new server entry for `localhost:5433` ✅
- **Application:** Uses `localhost:5433` ✅

All three should now point to the same Docker PostgreSQL instance!

