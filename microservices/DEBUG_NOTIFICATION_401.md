# Debugging 401 Unauthorized for Notification API

## Issue
Farmer app is getting `401 (Unauthorized)` when calling `/notification/unread/FARM_VERIFICATION_OTP`

## Root Cause Analysis

The API Gateway's JWT filter is rejecting the request. Possible reasons:
1. **Token is missing** - Not being sent in Authorization header
2. **Token is expired** - JWT token has expired (default: 24 hours)
3. **Token is invalid** - Token signature doesn't match JWKS
4. **JWKS not available** - API Gateway can't fetch JWKS from Auth Service

## Debugging Steps

### 1. Check if Token Exists in Farmer App

Open browser console and check the debug logs:
```
=== FETCHING NOTIFICATIONS ===
User ID from storage: 60
Token exists: true/false
Token length: XXX
```

### 2. Check API Gateway Logs

Look for:
- `Missing JWT token for path: /notification/unread/FARM_VERIFICATION_OTP`
- `Token validation failed for path /notification/unread/FARM_VERIFICATION_OTP: <error>`
- `Token validated for path: /notification/unread/FARM_VERIFICATION_OTP, user: <username> (ID: 60)`

### 3. Check Auth Service JWKS Endpoint

```powershell
Invoke-WebRequest -Uri "http://localhost:4005/.well-known/jwks.json" -Method GET
```

Should return JSON with keys.

### 4. Test Token Manually

1. Get token from farmer app storage (browser DevTools → Application → Local Storage)
2. Test API directly:

```powershell
$token = "YOUR_TOKEN_HERE"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}
Invoke-WebRequest -Uri "http://localhost:4004/notification/unread/FARM_VERIFICATION_OTP" -Headers $headers
```

## Solutions

### Solution 1: User Needs to Login Again

If token is expired:
1. Logout from farmer app
2. Login again
3. New token will be generated
4. Notifications should work

### Solution 2: Check Token Storage

Verify token is being saved correctly:
```dart
// In browser console or Flutter logs
final token = await StorageService.getToken();
print('Token: $token');
```

### Solution 3: Check API Gateway Configuration

Verify:
- API Gateway is running on port 4004
- Auth Service is running on port 4005
- JWKS endpoint is accessible: `http://localhost:4005/.well-known/jwks.json`

### Solution 4: Temporarily Disable JWT for Testing

**⚠️ ONLY FOR TESTING - NOT FOR PRODUCTION**

Add to `application.yml`:
```yaml
gateway:
  jwt:
    enabled: false  # Disable JWT validation temporarily
```

Then test if notifications work. If they do, the issue is JWT validation.

## Quick Fix

**Most Likely Solution**: The user's JWT token has expired. 

1. **Logout and Login Again** in the farmer app
2. This will generate a new JWT token
3. Notifications should start working

## Verification

After logging in again, check:
1. Browser console shows: `Token exists: true`
2. API Gateway logs show: `Token validated for user: <username> (ID: 60)`
3. Notification Service logs show: `X-User-Id header: 60`
4. Notifications appear in farmer app
