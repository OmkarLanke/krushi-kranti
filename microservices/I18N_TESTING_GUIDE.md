# I18n (Internationalization) Testing Guide for Auth Service

This guide explains how to test the internationalization (i18n) feature in the Auth Service using Postman.

## Overview

The Auth Service now supports multiple languages:
- **English (en)** - Default language
- **Hindi (hi)** - हिंदी
- **Marathi (mr)** - मराठी

The service automatically detects the language from the `Accept-Language` HTTP header and returns messages in the requested language.

---

## Prerequisites

1. **Auth Service must be running** on `http://localhost:4005`
2. **Postman** installed (or any REST client)
3. **Database and Redis** should be running

---

## How I18n Works

The service reads the `Accept-Language` header from the HTTP request:
- `Accept-Language: en` → Returns English messages
- `Accept-Language: hi` → Returns Hindi messages
- `Accept-Language: mr` → Returns Marathi messages

If no header is provided, it defaults to English.

---

## Postman Setup

### Step 1: Create a New Collection

1. Open Postman
2. Click **"New"** → **"Collection"**
3. Name it: **"KrushiKranti - Auth Service I18n Tests"**

### Step 2: Set Base URL as Collection Variable

1. Click on your collection
2. Go to **"Variables"** tab
3. Add variable:
   - **Variable**: `base_url`
   - **Initial Value**: `http://localhost:4005`
   - **Current Value**: `http://localhost:4005`

---

## Test Cases

### Test 1: Register Endpoint (OTP Sent Message)

**Endpoint**: `POST {{base_url}}/auth/register`

**Test in Different Languages**:

#### 1.1 English (en)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: en
  ```
- **Body** (JSON):
  ```json
  {
    "phoneNumber": "9876543210",
    "email": "test@example.com",
    "username": "testuser"
  }
  ```
- **Expected Response** (200 OK):
  ```json
  {
    "message": "OTP sent to mobile number. Please verify OTP to complete registration.",
    "data": null
  }
  ```

#### 1.2 Hindi (hi)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: hi
  ```
- **Body**: Same as above
- **Expected Response** (200 OK):
  ```json
  {
    "message": "मोबाइल नंबर पर OTP भेजा गया है। कृपया पंजीकरण पूरा करने के लिए OTP सत्यापित करें।",
    "data": null
  }
  ```

#### 1.3 Marathi (mr)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: mr
  ```
- **Body**: Same as above
- **Expected Response** (200 OK):
  ```json
  {
    "message": "मोबाइल नंबरावर OTP पाठवला आहे। कृपया नोंदणी पूर्ण करण्यासाठी OTP सत्यापित करा।",
    "data": null
  }
  ```

---

### Test 2: Login Endpoint (Success Message)

**Endpoint**: `POST {{base_url}}/auth/login`

#### 2.1 English (en)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: en
  ```
- **Body** (JSON):
  ```json
  {
    "email": "test@example.com",
    "password": "password123"
  }
  ```
- **Expected Response** (200 OK):
  ```json
  {
    "accessToken": "...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "user": { ... }
  }
  ```
  *Note: Login success message is implicit in the token response, but validation errors will be translated.*

#### 2.2 Hindi (hi)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: hi
  ```
- **Body**: Same as above
- **Expected Error Response** (401 Unauthorized) if credentials are invalid:
  ```json
  {
    "message": "अमान्य ईमेल या पासवर्ड",
    "data": null
  }
  ```

#### 2.3 Marathi (mr)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: mr
  ```
- **Expected Error Response** (401 Unauthorized) if credentials are invalid:
  ```json
  {
    "message": "अवैध ईमेल किंवा पासवर्ड",
    "data": null
  }
  ```

---

### Test 3: Verify OTP Endpoint

**Endpoint**: `POST {{base_url}}/auth/verify-otp`

#### 3.1 English (en)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: en
  ```
- **Body** (JSON):
  ```json
  {
    "phoneNumber": "9876543210",
    "otp": "123456"
  }
  ```
- **Expected Response** (200 OK):
  ```json
  {
    "message": "OTP verified and registration completed successfully",
    "data": {
      "id": 1,
      "username": "testuser",
      ...
    }
  }
  ```

#### 3.2 Hindi (hi)
- **Headers**:
  ```
  Accept-Language: hi
  ```
- **Expected Response**:
  ```json
  {
    "message": "OTP सत्यापित किया गया और नोंदणी यशस्वीरित्या पूर्ण झाली",
    "data": { ... }
  }
  ```

#### 3.3 Marathi (mr)
- **Headers**:
  ```
  Accept-Language: mr
  ```
- **Expected Response**:
  ```json
  {
    "message": "OTP सत्यापित केले आणि नोंदणी यशस्वीरित्या पूर्ण केले",
    "data": { ... }
  }
  ```

---

### Test 4: Request Login OTP

**Endpoint**: `POST {{base_url}}/auth/request-login-otp`

#### 4.1 English (en)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: en
  ```
- **Body** (JSON):
  ```json
  {
    "phoneNumber": "9876543210"
  }
  ```
- **Expected Response** (200 OK):
  ```json
  {
    "message": "OTP sent to mobile number for login. Please use the OTP to login.",
    "data": null
  }
  ```

#### 4.2 Hindi (hi)
- **Headers**:
  ```
  Accept-Language: hi
  ```
- **Expected Response**:
  ```json
  {
    "message": "लॉगिन के लिए मोबाइल नंबर पर OTP भेजा गया है। कृपया लॉगिन करने के लिए OTP का उपयोग करें।",
    "data": null
  }
  ```

#### 4.3 Marathi (mr)
- **Headers**:
  ```
  Accept-Language: mr
  ```
- **Expected Response**:
  ```json
  {
    "message": "लॉगिनसाठी मोबाइल नंबरावर OTP पाठवला आहे। कृपया लॉगिन करण्यासाठी OTP वापरा।",
    "data": null
  }
  ```

---

### Test 5: Login Validation Errors

**Endpoint**: `POST {{base_url}}/auth/login`

#### 5.1 Missing Login Method (English)
- **Headers**:
  ```
  Content-Type: application/json
  Accept-Language: en
  ```
- **Body** (JSON):
  ```json
  {}
  ```
- **Expected Response** (400 Bad Request):
  ```json
  {
    "message": "Please provide either email/password or phone/OTP for login",
    "data": null
  }
  ```

#### 5.2 Missing Login Method (Hindi)
- **Headers**:
  ```
  Accept-Language: hi
  ```
- **Expected Response** (400 Bad Request):
  ```json
  {
    "message": "कृपया लॉगिन के लिए ईमेल/पासवर्ड या फोन/OTP प्रदान करें",
    "data": null
  }
  ```

#### 5.3 Missing Login Method (Marathi)
- **Headers**:
  ```
  Accept-Language: mr
  ```
- **Expected Response** (400 Bad Request):
  ```json
  {
    "message": "कृपया लॉगिनसाठी ईमेल/पासवर्ड किंवा फोन/OTP प्रदान करा",
    "data": null
  }
  ```

---

### Test 6: Get Current User (Protected Endpoint)

**Endpoint**: `GET {{base_url}}/auth/me`

**Requires**: Valid JWT token in Authorization header

#### 6.1 English (en)
- **Headers**:
  ```
  Accept-Language: en
  Authorization: Bearer <your_jwt_token>
  ```
- **Expected Response** (200 OK):
  ```json
  {
    "message": "User retrieved successfully via validated token",
    "data": {
      "id": 1,
      "username": "testuser",
      ...
    }
  }
  ```

#### 6.2 Hindi (hi)
- **Headers**:
  ```
  Accept-Language: hi
  Authorization: Bearer <your_jwt_token>
  ```
- **Expected Response**:
  ```json
  {
    "message": "सत्यापित टोकन के माध्यम से उपयोगकर्ता सफलतापूर्वक प्राप्त किया गया",
    "data": { ... }
  }
  ```

#### 6.3 Marathi (mr)
- **Headers**:
  ```
  Accept-Language: mr
  Authorization: Bearer <your_jwt_token>
  ```
- **Expected Response**:
  ```json
  {
    "message": "सत्यापित टोकनद्वारे वापरकर्ता यशस्वीरित्या प्राप्त केला",
    "data": { ... }
  }
  ```

---

## Postman Collection Structure

Create requests in this order:

```
📁 KrushiKranti - Auth Service I18n Tests
  ├── 📁 Register
  │   ├── Register - English
  │   ├── Register - Hindi
  │   └── Register - Marathi
  ├── 📁 Login
  │   ├── Login - English
  │   ├── Login - Hindi
  │   └── Login - Marathi
  ├── 📁 Verify OTP
  │   ├── Verify OTP - English
  │   ├── Verify OTP - Hindi
  │   └── Verify OTP - Marathi
  ├── 📁 Request Login OTP
  │   ├── Request Login OTP - English
  │   ├── Request Login OTP - Hindi
  │   └── Request Login OTP - Marathi
  └── 📁 Error Cases
      ├── Missing Login Method - English
      ├── Missing Login Method - Hindi
      └── Missing Login Method - Marathi
```

---

## Quick Testing Script

### Using cURL (Alternative to Postman)

#### English
```bash
curl -X POST http://localhost:4005/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept-Language: en" \
  -d '{
    "phoneNumber": "9876543210",
    "email": "test@example.com",
    "username": "testuser"
  }'
```

#### Hindi
```bash
curl -X POST http://localhost:4005/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept-Language: hi" \
  -d '{
    "phoneNumber": "9876543210",
    "email": "test@example.com",
    "username": "testuser"
  }'
```

#### Marathi
```bash
curl -X POST http://localhost:4005/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept-Language: mr" \
  -d '{
    "phoneNumber": "9876543210",
    "email": "test@example.com",
    "username": "testuser"
  }'
```

---

## Expected Behavior

1. **Same endpoint, different languages**: The same API endpoint should return different message text based on the `Accept-Language` header.

2. **Default language**: If `Accept-Language` header is missing, it should default to English.

3. **Invalid language code**: If an unsupported language code is provided, it should default to English.

4. **Case insensitive**: Language codes should be case-insensitive (e.g., `en`, `EN`, `En` all work).

---

## Troubleshooting

### Issue: Messages still in English

**Solution**: 
1. Check that `Accept-Language` header is set correctly
2. Verify the header value is exactly `en`, `hi`, or `mr`
3. Check server logs to see if locale is being resolved correctly

### Issue: 500 Internal Server Error

**Solution**:
1. Check if auth-service is running
2. Verify database connection
3. Check server logs for error details
4. Ensure i18n-common module is properly built and included

### Issue: Message key not found

**Solution**:
1. Check if the message key exists in `messages.properties`
2. Verify translations exist for all languages (en, hi, mr)
3. Rebuild the i18n-common module: `mvn clean install -pl :i18n-common`

---

## Message Keys Reference

All message keys are defined in `MessageKeys.java`:

- `AUTH_REGISTRATION_OTP_SENT` → `auth.registration.otp.sent`
- `AUTH_LOGIN_SUCCESS` → `auth.login.success`
- `AUTH_LOGIN_INVALID_EMAIL_PASSWORD` → `auth.login.invalid.email.password`
- `AUTH_OTP_VERIFIED` → `auth.otp.verified`
- `AUTH_REGISTRATION_COMPLETED` → `auth.registration.completed`
- And more...

Full list can be found in:
`microservices/java-spring-microservices/i18n-common/src/main/java/com/krushikranti/i18n/constants/MessageKeys.java`

---

## Next Steps

1. Test all endpoints with all three languages
2. Verify error messages are also translated
3. Test with invalid/unsupported language codes
4. Test default language behavior (no header)

---

## Summary

✅ **Supported Languages**: English (en), Hindi (hi), Marathi (mr)  
✅ **Header Required**: `Accept-Language: <language_code>`  
✅ **Default Language**: English (if header missing)  
✅ **Response Format**: Messages in `ApiResponse.message` field are translated

Happy Testing! 🚀

