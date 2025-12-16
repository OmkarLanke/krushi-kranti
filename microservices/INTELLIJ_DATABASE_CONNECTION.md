# IntelliJ Database Connection Setup

## Issue
IntelliJ is trying to connect to `auth-db:5432`, but this hostname only works inside the Docker network. From your host machine (where IntelliJ runs), you need to use `localhost:5433`.

## Solution: Fix Database Connection Settings

### Step 1: Open Data Sources Configuration
1. Go to **View** → **Tool Windows** → **Database** (or press `Alt+1` and select Database)
2. Right-click on `auth_db@auth-db` → **Properties** (or double-click it)

### Step 2: Update Connection Settings
In the **General** tab, change:

**Current (Wrong):**
- Host: `auth-db`
- Port: `5432`

**Correct Settings:**
- **Host:** `localhost` ✅
- **Port:** `5433` ✅
- **Database:** `auth_db`
- **User:** `postgres`
- **Password:** `....` (your database password)
- **Authentication:** User & Password

### Step 3: Test Connection
1. Click **Test Connection** button
2. If successful, you'll see: ✅ **Connection successful**
3. Click **OK** to save

### Step 4: Verify Connection
1. In the Database tool window, expand `auth_db@localhost`
2. You should see:
   - Tables (including `users` and `refresh_tokens` after migrations)
   - Schemas
   - etc.

## Why This Happens

- **Inside Docker network:** Services use container names like `auth-db:5432`
- **From host machine:** Use `localhost:5433` (mapped port)

The `docker-compose.yml` maps:
```
ports:
  - "5433:5432"  # host:container
```

So:
- Container listens on port `5432` internally
- Host machine accesses it via port `5433`

## Alternative: Multiple Data Source Configurations

You can have both configurations:

1. **`auth_db@localhost`** - For IntelliJ (host machine)
   - Host: `localhost`
   - Port: `5433`

2. **`auth_db@auth-db`** - For Docker services (if needed)
   - Host: `auth-db`
   - Port: `5432`
   - Only works from inside Docker containers

For IntelliJ development, use the `localhost:5433` configuration.

