# QuickeKYC API Test Report

## Test Date
December 19, 2025

---

## API Configuration

### Production API
- **Base URL**: `https://api.quickekyc.com`
- **API Key**: `5682be91-07f3-4208-bc07-f0477e3a038b`
- **IP Whitelist**: `103.147.161.15`

### Sandbox API
- **Base URL**: `https://sandbox.quickekyc.com`
- **API Key**: `d8551d2e-1a31-45d1-be02-b797207ac494`

---

## Subscribed Services
| Service | Status | Endpoint Used |
|---------|--------|---------------|
| Aadhaar Verification API (OTP) | ✅ Activated | `/api/v1/aadhaar-v2/generate-otp` |
| Bank Account Verification API | ✅ Activated | `/api/v1/bank-verification` |
| Pan Verification API (NAME) | ✅ Activated | `/api/v1/pan/pan` (PAN Lite) |

---

## Test Results Summary

| Endpoint | Status | Notes |
|----------|--------|-------|
| Aadhaar Generate OTP | ✅ SUCCESS | OTP sent to phone |
| Aadhaar Submit OTP | ⏳ Pending user OTP | Requires manual testing |
| Bank Verification | ✅ SUCCESS | Account verified |
| PAN Verification | ✅ SUCCESS | Name: OMKAR DNYANESH LANKE |

---

# 1. Aadhaar Verification API (OTP)

## 1.1 Generate OTP

### Endpoint Details
- **Method**: `POST`
- **URL (through Gateway)**: `http://localhost:4004/kyc/aadhaar/generate-otp`
- **URL (direct)**: `http://localhost:4014/kyc/aadhaar/generate-otp`
- **QuickeKYC Endpoint**: `https://api.quickekyc.com/api/v1/aadhaar-v2/generate-otp`

### Postman Setup

#### Headers
| Key | Value |
|-----|-------|
| Authorization | Bearer `<your-jwt-token>` |
| Content-Type | application/json |

> **Note**: When testing through API Gateway (port 4004), only Bearer token is needed. 
> When testing directly (port 4014), add `X-User-Id: <userId>` header.

#### Request Body (raw JSON)
```json
{
  "aadhaarNumber": "479162878227"
}
```

### Test Result: ✅ SUCCESS

**Request:**
```
POST http://localhost:4004/kyc/aadhaar/generate-otp
Authorization: Bearer eyJraWQi...
Content-Type: application/json

{
  "aadhaarNumber": "479162878227"
}
```

**Response (200 OK):**
```json
{
  "message": "OTP sent successfully",
  "data": {
    "otpSent": true,
    "requestId": "7079051",
    "message": "OTP sent to Aadhaar linked mobile"
  }
}
```

### Notes
- OTP is sent to the mobile number linked to the Aadhaar
- `requestId` is required for the Submit OTP step
- OTP is valid for 10 minutes
- Wait 45 seconds before requesting another OTP for the same Aadhaar

---

## 1.2 Submit OTP (Verify Aadhaar)

### Endpoint Details
- **Method**: `POST`
- **URL (through Gateway)**: `http://localhost:4004/kyc/aadhaar/verify-otp`
- **URL (direct)**: `http://localhost:4014/kyc/aadhaar/verify-otp`
- **QuickeKYC Endpoint**: `https://api.quickekyc.com/api/v1/aadhaar-v2/submit-otp`

### Postman Setup

#### Headers
| Key | Value |
|-----|-------|
| Authorization | Bearer `<your-jwt-token>` |
| Content-Type | application/json |

#### Request Body (raw JSON)
```json
{
  "requestId": "7079051",
  "otp": "<OTP-from-phone>"
}
```

### Expected Response (Success)
```json
{
  "message": "Aadhaar verified successfully",
  "data": {
    "verified": true,
    "aadhaarNumberMasked": "XXXX XXXX 8227",
    "name": "Full Name from Aadhaar",
    "dob": "DD-MM-YYYY",
    "gender": "M/F",
    "address": "Full Address",
    "message": "Aadhaar verified successfully"
  }
}
```

### Test Status: ⏳ PENDING
Requires the OTP sent to the user's phone.

**To test manually:**
1. Use the `requestId` from Generate OTP response: `7079051`
2. Enter the OTP received on phone: `<6-digit-OTP>`
3. Send the request within 10 minutes of OTP generation

---

# 2. Bank Account Verification API

## 2.1 Verify Bank Account

### Endpoint Details
- **Method**: `POST`
- **URL (through Gateway)**: `http://localhost:4004/kyc/bank/verify`
- **URL (direct)**: `http://localhost:4014/kyc/bank/verify`
- **QuickeKYC Endpoint**: `https://api.quickekyc.com/api/v1/bank-verification`

### Postman Setup

#### Headers
| Key | Value |
|-----|-------|
| Authorization | Bearer `<your-jwt-token>` |
| Content-Type | application/json |

#### Request Body (raw JSON)
```json
{
  "accountNumber": "<your-bank-account-number>",
  "ifscCode": "<your-bank-ifsc-code>"
}
```

### Expected Response (Success)
```json
{
  "message": "Bank account verified successfully",
  "data": {
    "verified": true,
    "accountNumberMasked": "XXXXXX1234",
    "ifscCode": "SBIN0001234",
    "accountHolderName": "Account Holder Name",
    "bankName": "State Bank of India",
    "message": "Bank account verified successfully"
  }
}
```

### Test Result: ✅ SUCCESS

**Request:**
```
POST http://localhost:4004/kyc/bank/verify
Authorization: Bearer eyJraWQi...
Content-Type: application/json

{
  "accountNumber": "38707680516",
  "ifscCode": "SBIN0015706"
}
```

**Response (200 OK):**
```json
{
  "message": "Bank account verified successfully",
  "data": {
    "verified": true,
    "accountNumberMasked": "XXXXXXX0516",
    "ifscCode": "SBIN0015706",
    "accountHolderName": "Mr AMEYA SHRIPAD KHIRE",
    "bankName": null,
    "message": "Bank account verified successfully"
  }
}
```

### Notes
- Account holder name is returned from bank records
- Account number is masked for security
- Bank name may be null depending on QuickeKYC response

---

# 3. PAN Verification API (PAN Lite)

## 3.1 Verify PAN

### Endpoint Details
- **Method**: `POST`
- **URL (through Gateway)**: `http://localhost:4004/kyc/pan/verify`
- **URL (direct)**: `http://localhost:4014/kyc/pan/verify`
- **QuickeKYC Endpoint**: `https://api.quickekyc.com/api/v1/pan/pan` (PAN Lite)

> **Important**: This uses the **PAN Lite** endpoint (`/api/v1/pan/pan`), NOT the PAN Validation endpoint (`/api/v1/pan/pan-validation`). The "Pan Verification API (NAME)" subscription requires the PAN Lite endpoint.

### Postman Setup

#### Headers
| Key | Value |
|-----|-------|
| Authorization | Bearer `<your-jwt-token>` |
| Content-Type | application/json |

#### Request Body (raw JSON)
```json
{
  "panNumber": "BLGPL2357H"
}
```

### Test Result: ✅ SUCCESS

**Request:**
```
POST http://localhost:4004/kyc/pan/verify
Authorization: Bearer eyJraWQi...
Content-Type: application/json

{
  "panNumber": "BLGPL2357H"
}
```

**Response (200 OK):**
```json
{
  "message": "PAN verified successfully",
  "data": {
    "verified": true,
    "panNumberMasked": "BLGPL****H",
    "name": "OMKAR DNYANESH LANKE",
    "message": "PAN verified successfully"
  }
}
```

### QuickeKYC Direct Response
```json
{
  "data": {
    "pan_number": "BLGPL2357H",
    "full_name": "OMKAR DNYANESH LANKE",
    "category": "individual"
  },
  "status_code": 200,
  "message": null,
  "status": "success",
  "request_id": 7083007
}
```

### Notes
- PAN holder's full name is returned from government database
- PAN number is masked for security in response
- Category (individual/company) is available from QuickeKYC

---

# KYC Service Endpoints Summary

| Our Endpoint | Method | QuickeKYC API | Description |
|--------------|--------|---------------|-------------|
| `/kyc/aadhaar/generate-otp` | POST | `/api/v1/aadhaar-v2/generate-otp` | Generate OTP for Aadhaar |
| `/kyc/aadhaar/verify-otp` | POST | `/api/v1/aadhaar-v2/submit-otp` | Submit OTP and verify Aadhaar |
| `/kyc/bank/verify` | POST | `/api/v1/bank-verification` | Verify bank account |
| `/kyc/pan/verify` | POST | `/api/v1/pan/pan` | Verify PAN (PAN Lite) ✅ |
| `/kyc/status` | GET | - | Get KYC status for user |
| `/kyc/check` | GET | - | Check if KYC is complete |

---

# Postman Collection Setup Guide

## 1. Environment Variables

Create a Postman environment with these variables:

| Variable | Value |
|----------|-------|
| `base_url` | `http://localhost:4004` |
| `bearer_token` | `<your-jwt-token>` |

## 2. Collection Authorization

Set collection-level authorization:
- **Type**: Bearer Token
- **Token**: `{{bearer_token}}`

## 3. Request Examples

### 3.1 Generate Aadhaar OTP
```
POST {{base_url}}/kyc/aadhaar/generate-otp
Authorization: Bearer {{bearer_token}}
Content-Type: application/json

{
  "aadhaarNumber": "123456789012"
}
```

### 3.2 Submit Aadhaar OTP
```
POST {{base_url}}/kyc/aadhaar/verify-otp
Authorization: Bearer {{bearer_token}}
Content-Type: application/json

{
  "requestId": "<requestId-from-generate-otp>",
  "otp": "<6-digit-otp>"
}
```

### 3.3 Verify Bank Account
```
POST {{base_url}}/kyc/bank/verify
Authorization: Bearer {{bearer_token}}
Content-Type: application/json

{
  "accountNumber": "1234567890",
  "ifscCode": "SBIN0001234"
}
```

### 3.4 Get KYC Status
```
GET {{base_url}}/kyc/status
Authorization: Bearer {{bearer_token}}
```

### 3.5 Check KYC Complete
```
GET {{base_url}}/kyc/check
Authorization: Bearer {{bearer_token}}
```

---

# Troubleshooting

## Common Errors

### 1. "Service not allowed" (404)
- **Cause**: API key doesn't have access to the service
- **Solution**: Subscribe to the service in QuickeKYC dashboard

### 2. "Required request header 'X-User-Id' is not present" (500)
- **Cause**: Testing directly without going through API Gateway
- **Solution**: Either:
  - Use API Gateway (port 4004) with Bearer token, OR
  - Add `X-User-Id: <userId>` header when testing directly

### 3. "Invalid or expired token" (401)
- **Cause**: JWT token expired
- **Solution**: Login again to get a new token

### 4. OTP not received
- **Cause**: Various reasons
- **Solutions**:
  - Wait 45 seconds between OTP requests
  - Check if mobile number is linked to Aadhaar
  - Check if phone has network connectivity

### 5. "IP not whitelisted"
- **Cause**: Your IP is not in QuickeKYC whitelist
- **Solution**: Add your public IP to QuickeKYC dashboard
- **Find your IP**: `(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content`

---

# Test User Details

| Field | Value |
|-------|-------|
| User ID | 31 |
| Email | omkardl873@gmail.com |
| Username | Omkar |
| Aadhaar | 479162878227 |
| Phone | 8180039093 |

---

# Configuration Files

## application.yml
```yaml
quickekyc:
  api:
    base-url: ${QUICKEKYC_BASE_URL:https://api.quickekyc.com}
    key: ${QUICKEKYC_API_KEY:5682be91-07f3-4208-bc07-f0477e3a038b}
    connect-timeout: 10000
    read-timeout: 30000
```

## To switch to Sandbox
```yaml
quickekyc:
  api:
    base-url: https://sandbox.quickekyc.com
    key: d8551d2e-1a31-45d1-be02-b797207ac494
```

---

# Next Steps

1. ✅ Aadhaar Generate OTP - Tested successfully
2. ⏳ Aadhaar Submit OTP - Enter OTP from phone to verify
3. ✅ Bank Verification - Tested successfully
4. ✅ PAN Verification - Tested successfully

---

# Complete Test Log

## Test 1: Aadhaar Generate OTP
- **Time**: December 19, 2025
- **Status**: ✅ SUCCESS
- **Request ID**: `7079051`
- **Aadhaar**: `479162878227`
- **OTP sent to**: `8180039093`

## Test 2: Bank Verification
- **Time**: December 19, 2025
- **Status**: ✅ SUCCESS
- **Account**: `38707680516`
- **IFSC**: `SBIN0015706`
- **Account Holder**: `Mr AMEYA SHRIPAD KHIRE`
- **Verified**: `true`

## Test 3: PAN Verification
- **Time**: December 19, 2025
- **Status**: ✅ SUCCESS
- **PAN**: `BLGPL2357H`
- **Name**: `OMKAR DNYANESH LANKE`
- **Category**: `individual`
- **Request ID**: `7083007`
- **Verified**: `true`
