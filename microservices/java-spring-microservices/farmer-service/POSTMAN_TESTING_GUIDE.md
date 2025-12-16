# Farmer Service - Postman Testing Guide

This guide provides step-by-step instructions to test all Farmer Service endpoints using Postman.

## 📋 Prerequisites

Before testing, ensure the following services are running:

1. **Farmer Service** - Port `4000`
2. **Auth Service** - Port `4005` (REST) and `9090` (gRPC)
3. **API Gateway** - Port `4004` (optional, for protected endpoints)
4. **PostgreSQL Database** - Port `5450` (for farmer_db)
5. **Redis** - Port `6379` (for Auth Service OTP)

### Check Services Status

```bash
# Check if services are running
Get-NetTCPConnection -LocalPort 4000,4004,4005,9090 -ErrorAction SilentlyContinue | Select-Object LocalPort, State
```

---

## 🚀 Testing Setup

### Option 1: Testing via API Gateway (Recommended for Protected Endpoints)

**Base URL:** `http://localhost:4004`

### Option 2: Testing Directly on Farmer Service

**Base URL:** `http://localhost:4000`

> **Note:** Protected endpoints require `X-User-Id` header. For direct testing, you'll need to manually set this header.

---

## 📝 Step-by-Step Testing Guide

### **STEP 1: Health Check (No Authentication Required)**

Test if the Farmer Service is running.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/health`
- **URL (Via Gateway):** `http://localhost:4004/farmer/health`
- **Headers:** None required

#### Expected Response

```
Status: 200 OK
Body: "Farmer Service is running"
```

---

### **STEP 2: Import Pincode Data (One-Time Setup)**

> **Important:** This must be done before testing address lookup endpoints.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4000/farmer/admin/pincode/import`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body (raw JSON):**
  ```json
  {
      "filePath": "D:\\Thynk Tech\\Krushi_Kranti\\Copy of List of Pin Codes of Maharashtra.xlsx"
  }
  ```

#### Expected Response

```json
{
    "message": "Pincode import completed successfully",
    "data": 1656
}
```

> **Note:** The `data` field contains the number of pincode records imported.

---

### **STEP 3: Get Pincode Count**

Check how many pincode records are in the database.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4000/farmer/admin/pincode/count`
- **Headers:** None required

#### Expected Response

```json
{
    "message": "Pincode count retrieved",
    "data": 1656
}
```

---

### **STEP 4: Login to Get JWT Token (For Protected Endpoints)**

Before testing protected endpoints, you need to login via Auth Service to get a JWT token.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4004/auth/login`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body (Email/Password):**
  ```json
  {
      "email": "farmer@example.com",
      "password": "your-password"
  }
  ```

- **Body (Phone/OTP):**
  ```json
  {
      "phoneNumber": "9876543210",
      "otp": "123456"
  }
  ```

#### Expected Response

```json
{
    "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "user": {
        "id": 1,
        "username": "farmer1",
        "email": "farmer@example.com",
        "phoneNumber": "9876543210",
        "role": "FARMER",
        "isVerified": true
    }
}
```

> **Save the `accessToken` for subsequent requests!**

---

### **STEP 5: Address Lookup by Pincode**

Lookup address details (district, taluka, state, villages) for a given pincode.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/address/lookup?pincode=411001`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Expected Response

```json
{
    "message": "Address lookup successful",
    "data": {
        "pincode": "411001",
        "district": "Pune",
        "taluka": "Pune",
        "state": "Maharashtra",
        "villages": [
            "Village1",
            "Village2",
            "Village3"
        ]
    }
}
```

---

### **STEP 6: Get My Details (Farmer Profile)**

Get the current farmer's profile details.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/my-details`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Expected Response (Profile Exists)

```json
{
    "message": "Farmer profile retrieved successfully",
    "data": {
        "id": 1,
        "userId": 1,
        "firstName": "John",
        "lastName": "Doe",
        "dateOfBirth": "1990-01-01",
        "gender": "MALE",
        "email": "farmer@example.com",
        "phoneNumber": "9876543210",
        "alternatePhone": "9876543211",
        "pincode": "411001",
        "village": "Village1",
        "district": "Pune",
        "taluka": "Pune",
        "state": "Maharashtra"
    }
}
```

---

### **STEP 7: Create/Update My Details**

Create or update the farmer's profile details.

#### Request

- **Method:** `PUT`
- **URL:** `http://localhost:4004/farmer/profile/my-details`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer {your-access-token}
  ```
- **Body:**
  ```json
  {
      "firstName": "John",
      "lastName": "Doe",
      "dateOfBirth": "1990-01-01",
      "gender": "MALE",
      "alternatePhone": "9876543211",
      "pincode": "411001",
      "village": "Shivajinagar"
  }
  ```

#### Expected Response

```json
{
    "message": "Farmer profile saved successfully",
    "data": {
        "id": 1,
        "userId": 1,
        "firstName": "John",
        "lastName": "Doe",
        "dateOfBirth": "1990-01-01",
        "gender": "MALE",
        "email": "farmer@example.com",
        "phoneNumber": "9876543210",
        "alternatePhone": "9876543211",
        "pincode": "411001",
        "village": "Shivajinagar",
        "district": "Pune",
        "taluka": "Pune",
        "state": "Maharashtra"
    }
}
```

---

## 🌾 Farm Details Endpoints

> **Note:** Farmer profile must be created before adding farms.

### **STEP 8: Create a New Farm**

Add a new farm for the logged-in farmer.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4004/farmer/profile/farms`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer {your-access-token}
  ```
- **Body:**
  ```json
  {
      "farmName": "Main Farm",
      "farmType": "ORGANIC",
      "totalAreaAcres": 5.50,
      "pincode": "411001",
      "village": "Shivajinagar",
      "soilType": "BLACK",
      "irrigationType": "DRIP",
      "landOwnership": "OWNED",
      "surveyNumber": "123/45",
      "landRegistrationNumber": "REG-2024-001",
      "pattaNumber": "PAT-123",
      "estimatedLandValue": 500000,
      "encumbranceStatus": "FREE"
  }
  ```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `farmName` | String | Yes | Name of the farm |
| `farmType` | Enum | No | ORGANIC, CONVENTIONAL, MIXED, VERMI_COMPOST |
| `totalAreaAcres` | Decimal | Yes | Total area in acres |
| `pincode` | String | Yes | 6-digit pincode |
| `village` | String | Yes | Village from pincode lookup |
| `soilType` | Enum | No | BLACK, RED, SANDY, LOAMY, CLAY, MIXED |
| `irrigationType` | Enum | No | DRIP, SPRINKLER, RAINFED, CANAL, BORE_WELL, OPEN_WELL, MIXED |
| `landOwnership` | Enum | Yes | OWNED, LEASED, SHARED, GOVERNMENT_ALLOTTED |
| `surveyNumber` | String | No | Survey/Plot number |
| `landRegistrationNumber` | String | No | Land registration document number |
| `pattaNumber` | String | No | Patta/Record of Rights number |
| `estimatedLandValue` | Decimal | No | Estimated value in INR |
| `encumbranceStatus` | Enum | No | NOT_VERIFIED, FREE, ENCUMBERED, PARTIALLY_ENCUMBERED |
| `encumbranceRemarks` | String | No | Details if encumbered |
| `landDocumentUrl` | String | No | S3 URL for land document |
| `surveyMapUrl` | String | No | S3 URL for survey map |
| `registrationCertificateUrl` | String | No | S3 URL for registration certificate |

#### Expected Response (201 Created)

```json
{
    "message": "Farm created successfully",
    "data": {
        "id": 1,
        "farmerId": 1,
        "farmName": "Main Farm",
        "farmType": "ORGANIC",
        "totalAreaAcres": 5.50,
        "pincode": "411001",
        "village": "Shivajinagar",
        "district": "Pune",
        "taluka": "Pune",
        "state": "Maharashtra",
        "soilType": "BLACK",
        "irrigationType": "DRIP",
        "landOwnership": "OWNED",
        "surveyNumber": "123/45",
        "landRegistrationNumber": "REG-2024-001",
        "pattaNumber": "PAT-123",
        "estimatedLandValue": 500000,
        "encumbranceStatus": "FREE",
        "encumbranceRemarks": null,
        "landDocumentUrl": null,
        "surveyMapUrl": null,
        "registrationCertificateUrl": null,
        "isVerified": false,
        "verifiedBy": null,
        "verifiedAt": null,
        "verificationRemarks": null,
        "isActive": true,
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00"
    }
}
```

---

### **STEP 9: Get All Farms**

Get all farms for the logged-in farmer.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/farms`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Expected Response

```json
{
    "message": "Farms retrieved successfully",
    "data": [
        {
            "id": 1,
            "farmerId": 1,
            "farmName": "Main Farm",
            "farmType": "ORGANIC",
            "totalAreaAcres": 5.50,
            "pincode": "411001",
            "village": "Shivajinagar",
            "district": "Pune",
            "taluka": "Pune",
            "state": "Maharashtra",
            "landOwnership": "OWNED",
            "isVerified": false,
            "isActive": true
        },
        {
            "id": 2,
            "farmerId": 1,
            "farmName": "North Field",
            "farmType": "CONVENTIONAL",
            "totalAreaAcres": 3.00,
            "landOwnership": "LEASED",
            "isVerified": false,
            "isActive": true
        }
    ]
}
```

---

### **STEP 10: Get Farm by ID**

Get a specific farm by its ID.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/farms/{farmId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
GET http://localhost:4004/farmer/profile/farms/1
```

#### Expected Response

```json
{
    "message": "Farm retrieved successfully",
    "data": {
        "id": 1,
        "farmerId": 1,
        "farmName": "Main Farm",
        "farmType": "ORGANIC",
        "totalAreaAcres": 5.50,
        "pincode": "411001",
        "village": "Shivajinagar",
        "district": "Pune",
        "taluka": "Pune",
        "state": "Maharashtra",
        "soilType": "BLACK",
        "irrigationType": "DRIP",
        "landOwnership": "OWNED",
        "surveyNumber": "123/45",
        "estimatedLandValue": 500000,
        "encumbranceStatus": "FREE",
        "isVerified": false,
        "isActive": true,
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00"
    }
}
```

---

### **STEP 11: Update Farm**

Update an existing farm.

#### Request

- **Method:** `PUT`
- **URL:** `http://localhost:4004/farmer/profile/farms/{farmId}`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer {your-access-token}
  ```
- **Body:**
  ```json
  {
      "farmName": "Main Farm - Updated",
      "farmType": "MIXED",
      "totalAreaAcres": 6.00,
      "pincode": "411001",
      "village": "Shivajinagar",
      "soilType": "LOAMY",
      "irrigationType": "MIXED",
      "landOwnership": "OWNED",
      "surveyNumber": "123/45-A",
      "estimatedLandValue": 600000,
      "encumbranceStatus": "FREE"
  }
  ```

#### Expected Response

```json
{
    "message": "Farm updated successfully",
    "data": {
        "id": 1,
        "farmerId": 1,
        "farmName": "Main Farm - Updated",
        "farmType": "MIXED",
        "totalAreaAcres": 6.00,
        "soilType": "LOAMY",
        "irrigationType": "MIXED",
        "surveyNumber": "123/45-A",
        "estimatedLandValue": 600000,
        "updatedAt": "2024-01-15T11:00:00"
    }
}
```

---

### **STEP 12: Delete Farm**

Soft delete a farm (sets `isActive = false`).

#### Request

- **Method:** `DELETE`
- **URL:** `http://localhost:4004/farmer/profile/farms/{farmId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
DELETE http://localhost:4004/farmer/profile/farms/1
```

#### Expected Response

```json
{
    "message": "Farm deleted successfully",
    "data": null
}
```

---

### **STEP 13: Get Farm Count**

Get the count of active farms for the farmer.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/farms/count`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Expected Response

```json
{
    "message": "Farm count retrieved successfully",
    "data": 2
}
```

---

### **STEP 14: Get Valid Collateral Farms**

Get farms that are valid for use as loan collateral.

A farm is valid collateral if:
- `isVerified = true` (verified by on-field officer)
- `encumbranceStatus = FREE` (no encumbrances)
- `landOwnership` is `OWNED` or `GOVERNMENT_ALLOTTED`
- `estimatedLandValue > 0`

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4004/farmer/profile/farms/collateral`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Expected Response

```json
{
    "message": "Valid collateral farms retrieved successfully",
    "data": [
        {
            "id": 1,
            "farmName": "Main Farm",
            "totalAreaAcres": 5.50,
            "landOwnership": "OWNED",
            "estimatedLandValue": 500000,
            "encumbranceStatus": "FREE",
            "isVerified": true
        }
    ]
}
```

> **Note:** If no farms meet the collateral criteria, an empty array is returned.

---

## 🧪 Testing Directly on Farmer Service (Bypass API Gateway)

For testing admin endpoints or bypassing JWT validation, you can call the Farmer Service directly:

### Direct URL Format

```
http://localhost:4000/farmer/{endpoint}
```

### For Protected Endpoints (Direct Testing)

You need to manually add the `X-User-Id` header:

```
Headers:
  X-User-Id: 1
  Content-Type: application/json
```

---

## ✅ Validation Rules

### MyDetailsRequest Validation

| Field | Rules |
|-------|-------|
| `firstName` | Required, Not blank |
| `lastName` | Required, Not blank |
| `dateOfBirth` | Required, Must be in past (YYYY-MM-DD) |
| `gender` | Required, One of: MALE, FEMALE, OTHER |
| `alternatePhone` | Optional, Must be exactly 10 digits if provided |
| `pincode` | Required, Must be exactly 6 digits |
| `village` | Required, Must exist for the given pincode |

### FarmRequest Validation

| Field | Rules |
|-------|-------|
| `farmName` | Required, Max 200 characters |
| `farmType` | Optional, One of: ORGANIC, CONVENTIONAL, MIXED, VERMI_COMPOST |
| `totalAreaAcres` | Required, Must be > 0 |
| `pincode` | Required, Must be exactly 6 digits |
| `village` | Required, Must exist for the given pincode |
| `soilType` | Optional, One of: BLACK, RED, SANDY, LOAMY, CLAY, MIXED |
| `irrigationType` | Optional, One of: DRIP, SPRINKLER, RAINFED, CANAL, BORE_WELL, OPEN_WELL, MIXED |
| `landOwnership` | Required, One of: OWNED, LEASED, SHARED, GOVERNMENT_ALLOTTED |
| `surveyNumber` | Optional, Max 100 characters |
| `estimatedLandValue` | Optional, Must be >= 0 |
| `encumbranceStatus` | Optional, One of: NOT_VERIFIED, FREE, ENCUMBERED, PARTIALLY_ENCUMBERED |

---

## 🔍 Error Scenarios to Test

### 1. Invalid Pincode for Farm

**Request:**
```
POST http://localhost:4004/farmer/profile/farms
Body:
{
    "farmName": "Test Farm",
    "totalAreaAcres": 5.00,
    "pincode": "999999",
    "village": "Test",
    "landOwnership": "OWNED"
}
```

**Expected Response:**
```json
{
    "message": "Pincode not found: 999999",
    "data": null
}
```

### 2. Invalid Village for Pincode

**Request:**
```
POST http://localhost:4004/farmer/profile/farms
Body:
{
    "farmName": "Test Farm",
    "totalAreaAcres": 5.00,
    "pincode": "411001",
    "village": "InvalidVillage",
    "landOwnership": "OWNED"
}
```

**Expected Response:**
```json
{
    "message": "Village 'InvalidVillage' is not valid for pincode: 411001",
    "data": null
}
```

### 3. Duplicate Farm Name

**Request:**
```
POST http://localhost:4004/farmer/profile/farms
Body:
{
    "farmName": "Main Farm",
    "totalAreaAcres": 3.00,
    "pincode": "411001",
    "village": "Shivajinagar",
    "landOwnership": "LEASED"
}
```

**Expected Response (if "Main Farm" already exists):**
```json
{
    "message": "A farm with this name already exists",
    "data": null
}
```

### 4. Farm Not Found

**Request:**
```
GET http://localhost:4004/farmer/profile/farms/999
```

**Expected Response:**
```json
{
    "message": "Farm not found with ID: 999",
    "data": null
}
```

### 5. Farmer Profile Not Found

**Request (with user who hasn't created farmer profile):**
```
GET http://localhost:4004/farmer/profile/farms
```

**Expected Response:**
```json
{
    "message": "Farmer profile not found. Please complete your profile first.",
    "data": null
}
```

### 6. Validation Errors

**Request:**
```
POST http://localhost:4004/farmer/profile/farms
Body:
{
    "farmName": "",
    "totalAreaAcres": -5,
    "pincode": "123",
    "landOwnership": null
}
```

**Expected Response:**
```json
{
    "message": "Validation failed: farmName: Farm name is required, pincode: Pincode must be 6 digits, totalAreaAcres: Total area must be greater than 0, landOwnership: Land ownership is required, village: Village is required",
    "data": null
}
```

---

## 📦 Postman Collection Setup

### Environment Variables

Create a Postman environment with these variables:

| Variable | Initial Value | Current Value |
|----------|---------------|---------------|
| `base_url_gateway` | `http://localhost:4004` | `http://localhost:4004` |
| `base_url_direct` | `http://localhost:4000` | `http://localhost:4000` |
| `auth_token` | (empty) | (will be set after login) |
| `user_id` | `1` | `1` |
| `farm_id` | `1` | (will be set after creating farm) |
| `crop_type_id` | `1` | `1` (Vegetables) |
| `crop_name_id` | `1` | `1` (Tomato) |
| `crop_id` | `1` | (will be set after creating crop) |

### Collection Structure

```
Farmer Service Tests
├── 1. Health Check
│   └── GET /farmer/health
├── 2. Admin Endpoints (Pincode)
│   ├── POST /farmer/admin/pincode/import
│   └── GET /farmer/admin/pincode/count
├── 3. Authentication
│   └── POST /auth/login
├── 4. Address Lookup
│   └── GET /farmer/profile/address/lookup?pincode={pincode}
├── 5. Profile Management (My Details)
│   ├── GET /farmer/profile/my-details
│   └── PUT /farmer/profile/my-details
├── 6. Farm Management
│   ├── GET /farmer/profile/farms
│   ├── POST /farmer/profile/farms
│   ├── GET /farmer/profile/farms/{farmId}
│   ├── PUT /farmer/profile/farms/{farmId}
│   ├── DELETE /farmer/profile/farms/{farmId}
│   ├── GET /farmer/profile/farms/count
│   └── GET /farmer/profile/farms/collateral
├── 7. Crop Master Data (Dropdowns)
│   ├── GET /farmer/profile/crop-types
│   ├── GET /farmer/profile/crop-names?typeId={typeId}
│   └── GET /farmer/profile/crop-names/search?term={term}
├── 8. Crop Management (Farmer)
│   ├── GET /farmer/profile/crops
│   ├── POST /farmer/profile/crops
│   ├── GET /farmer/profile/crops/{cropId}
│   ├── PUT /farmer/profile/crops/{cropId}
│   ├── DELETE /farmer/profile/crops/{cropId}
│   ├── GET /farmer/profile/crops/farm/{farmId}
│   ├── GET /farmer/profile/crops/farm/{farmId}/count
│   └── GET /farmer/profile/crops/type/{cropTypeId}
├── 9. Admin - Crop Types
│   ├── GET /farmer/admin/crop-types
│   ├── POST /farmer/admin/crop-types
│   ├── GET /farmer/admin/crop-types/{id}
│   ├── PUT /farmer/admin/crop-types/{id}
│   ├── DELETE /farmer/admin/crop-types/{id}
│   └── POST /farmer/admin/crop-types/{id}/restore
└── 10. Admin - Crop Names
    ├── GET /farmer/admin/crop-names
    ├── GET /farmer/admin/crop-names?typeId={typeId}
    ├── GET /farmer/admin/crop-names/search?term={term}
    ├── POST /farmer/admin/crop-names
    ├── GET /farmer/admin/crop-names/{id}
    ├── PUT /farmer/admin/crop-names/{id}
    ├── DELETE /farmer/admin/crop-names/{id}
    └── POST /farmer/admin/crop-names/{id}/restore
```

---

## 🎯 Complete Testing Flow

### Recommended Test Order:

1. ✅ **Health Check** - Verify service is running
2. ✅ **Login** - Get JWT token and save it
3. ✅ **Import Pincode Data** - One-time setup (if not done)
4. ✅ **Check Pincode Count** - Verify import was successful
5. ✅ **Address Lookup** - Test with valid pincode
6. ✅ **Get My Details** - Should return empty profile initially
7. ✅ **Create Profile** - PUT with complete data
8. ✅ **Get My Details Again** - Verify profile was saved
9. ✅ **Create Farm** - POST with farm data
10. ✅ **Get All Farms** - Should show created farm
11. ✅ **Get Farm by ID** - Verify specific farm details
12. ✅ **Update Farm** - Modify and save
13. ✅ **Get Farm Count** - Verify count
14. ✅ **Get Collateral Farms** - May be empty (not verified yet)
15. ✅ **Delete Farm** - Soft delete
16. ✅ **Test Error Scenarios** - Invalid data, duplicates, etc.

---

## 💡 Tips

1. **Save JWT Token:** After login, save the token in Postman environment variables for reuse.
2. **Use Environment Variables:** Create Postman environments for different setups (local, docker, etc.)
3. **Test Error Cases:** Always test validation errors and edge cases.
4. **Check Logs:** Monitor Farmer Service logs for debugging.
5. **Farm Order:** Create farmer profile first, then farms.
6. **Collateral Status:** Farms must be verified by on-field officer to be valid collateral.

---

## 📚 Additional Resources

- **Service Documentation:** See `README.md`
- **Test Documentation:** See `TEST_README.md`
- **API Gateway Routes:** `/farmer/**` routes to `http://localhost:4000`

---

## 🐛 Troubleshooting

### Issue: 401 Unauthorized

**Solution:** 
- Make sure you have a valid JWT token
- Token might be expired (default: 24 hours)
- Login again to get a new token

### Issue: Connection Refused

**Solution:**
- Verify Farmer Service is running on port 4000
- Check if API Gateway is running on port 4004 (if using gateway)

### Issue: Pincode Not Found

**Solution:**
- Make sure you've imported pincode data (Step 2)
- Verify the pincode exists in your Excel file
- Check pincode count endpoint to see if data was imported

### Issue: gRPC Connection Error

**Solution:**
- Verify Auth Service is running on port 9090 (gRPC)
- Check Auth Service logs for connection issues

### Issue: Farmer Profile Not Found (when creating farm)

**Solution:**
- Create farmer profile first using PUT `/farmer/profile/my-details`
- Then create farms

---

## 🌱 Crop Details Endpoints

Crop Details allows farmers to add crops to their farms. The system uses database-driven master data (crop types and crop names) that admin can manage.

> **Prerequisites:** 
> - Farmer profile must be created
> - At least one farm must exist

---

### **STEP 15: Get Crop Types (Dropdown 1)**

Get all active crop types for the first dropdown in farmer app.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crop-types`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crop-types`
- **Headers:** None required (public endpoint)

#### Expected Response

```json
{
    "message": "Crop types retrieved successfully",
    "data": [
        {
            "id": 1,
            "typeName": "VEGETABLE",
            "displayName": "Vegetables",
            "description": "Fresh vegetables including leafy greens, root vegetables, and gourds",
            "iconUrl": null,
            "displayOrder": 1,
            "isActive": true,
            "cropNameCount": 31,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        },
        {
            "id": 2,
            "typeName": "FRUIT",
            "displayName": "Fruits",
            "description": "Fresh fruits including tropical, citrus, and seasonal fruits",
            "iconUrl": null,
            "displayOrder": 2,
            "isActive": true,
            "cropNameCount": 26,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        },
        {
            "id": 3,
            "typeName": "GRAIN_CEREAL",
            "displayName": "Grains & Cereals",
            "description": "Staple grains and cereals like wheat, rice, and millets",
            "iconUrl": null,
            "displayOrder": 3,
            "isActive": true,
            "cropNameCount": 9,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        }
    ]
}
```

> **Note:** The system is pre-seeded with 10 crop types and 144+ crop names.

---

### **STEP 16: Get Crop Names by Type (Dropdown 2)**

Get active crop names for a specific crop type. Used for the second dropdown when user selects a crop type.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crop-names?typeId=1`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crop-names?typeId=1`
- **Headers:** None required (public endpoint)
- **Query Parameters:**
  | Parameter | Required | Description |
  |-----------|----------|-------------|
  | `typeId` | Yes | The crop type ID from Dropdown 1 |

#### Expected Response (typeId=1 for Vegetables)

```json
{
    "message": "Crop names retrieved successfully",
    "data": [
        {
            "id": 1,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "TOMATO",
            "displayName": "Tomato",
            "localName": "टमाटर",
            "description": null,
            "iconUrl": null,
            "displayOrder": 1,
            "isActive": true,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        },
        {
            "id": 2,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "ONION",
            "displayName": "Onion",
            "localName": "कांदा",
            "description": null,
            "iconUrl": null,
            "displayOrder": 2,
            "isActive": true,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        },
        {
            "id": 3,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "POTATO",
            "displayName": "Potato",
            "localName": "बटाटा",
            "description": null,
            "iconUrl": null,
            "displayOrder": 3,
            "isActive": true,
            "createdAt": "2025-12-09T10:57:13",
            "updatedAt": "2025-12-09T10:57:13"
        }
    ]
}
```

---

### **STEP 17: Search Crop Names**

Search crop names by term (for autocomplete feature).

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crop-names/search?term=tom`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crop-names/search?term=tom`
- **Headers:** None required (public endpoint)
- **Query Parameters:**
  | Parameter | Required | Description |
  |-----------|----------|-------------|
  | `term` | Yes | Search term (searches displayName and localName) |

#### Expected Response

```json
{
    "message": "Crop names retrieved successfully",
    "data": [
        {
            "id": 1,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "TOMATO",
            "displayName": "Tomato",
            "localName": "टमाटर",
            "displayOrder": 1,
            "isActive": true
        }
    ]
}
```

---

### **STEP 18: Create a Crop**

Add a new crop to a farm.

#### Request

- **Method:** `POST`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer {your-access-token}
  ```
  OR (for direct testing):
  ```
  Content-Type: application/json
  X-User-Id: 1
  ```
- **Body:**
  ```json
  {
      "farmId": 1,
      "cropNameId": 1,
      "areaAcres": 2.50,
      "sowingDate": "2025-06-15",
      "harvestingDate": "2025-10-15",
      "cropStatus": "PLANNED"
  }
  ```
  

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `farmId` | Long | Yes | The farm ID to add crop to |
| `cropNameId` | Long | Yes | The crop name ID from Dropdown 2 |
| `areaAcres` | Decimal | Yes | Area in acres (must be > 0) |
| `sowingDate` | Date | No | Sowing date (YYYY-MM-DD format) |
| `harvestingDate` | Date | No | Expected/Actual harvest date (YYYY-MM-DD format) |
| `cropStatus` | Enum | No | PLANNED, SOWN, GROWING, HARVESTED, FAILED (default: PLANNED) |

#### Crop Status Options

| Status | Description |
|--------|-------------|
| `PLANNED` | Crop is planned but not yet sown |
| `SOWN` | Seeds have been planted |
| `GROWING` | Crop is actively growing |
| `HARVESTED` | Crop has been harvested |
| `FAILED` | Crop failed due to weather/pests/disease |

#### Expected Response (201 Created)

```json
{
    "message": "Crop created successfully",
    "data": {
        "id": 1,
        "farmId": 1,
        "farmName": "Main Farm",
        "cropTypeId": 1,
        "cropTypeName": "VEGETABLE",
        "cropTypeDisplayName": "Vegetables",
        "cropNameId": 1,
        "cropName": "TOMATO",
        "cropDisplayName": "Tomato",
        "cropLocalName": "टमाटर",
        "areaAcres": 2.50,
        "sowingDate": "2025-06-15",
        "harvestingDate": "2025-10-15",
        "cropStatus": "PLANNED",
        "isActive": true,
        "createdAt": "2025-12-09T11:07:40",
        "updatedAt": "2025-12-09T11:07:40"
    }
}
```

---

### **STEP 19: Get All Crops for Farmer**

Get all crops across all farms for the logged-in farmer.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```
  OR (for direct testing):
  ```
  X-User-Id: 1
  ```

#### Expected Response

```json
{
    "message": "Crops retrieved successfully",
    "data": [
        {
            "id": 1,
            "farmId": 1,
            "farmName": "Main Farm",
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "cropNameId": 1,
            "cropName": "TOMATO",
            "cropDisplayName": "Tomato",
            "cropLocalName": "टमाटर",
            "areaAcres": 2.50,
            "sowingDate": "2025-06-15",
            "harvestingDate": "2025-10-15",
            "cropStatus": "GROWING",
            "isActive": true,
            "createdAt": "2025-12-09T11:07:40",
            "updatedAt": "2025-12-09T11:07:40"
        },
        {
            "id": 2,
            "farmId": 1,
            "farmName": "Main Farm",
            "cropTypeId": 2,
            "cropTypeName": "FRUIT",
            "cropTypeDisplayName": "Fruits",
            "cropNameId": 33,
            "cropName": "MANGO",
            "cropDisplayName": "Mango",
            "cropLocalName": "आंबा",
            "areaAcres": 4.00,
            "sowingDate": null,
            "harvestingDate": "2025-05-01",
            "cropStatus": "PLANNED",
            "isActive": true,
            "createdAt": "2025-12-09T11:08:52",
            "updatedAt": "2025-12-09T11:08:52"
        }
    ]
}
```

---

### **STEP 20: Get Crops by Farm**

Get all crops for a specific farm.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/farm/{farmId}`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/farm/{farmId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
GET http://localhost:4000/farmer/profile/crops/farm/1
X-User-Id: 1
```

#### Expected Response

```json
{
    "message": "Crops retrieved successfully",
    "data": [
        {
            "id": 1,
            "farmId": 1,
            "farmName": "Main Farm",
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "cropNameId": 1,
            "cropName": "TOMATO",
            "cropDisplayName": "Tomato",
            "cropLocalName": "टमाटर",
            "areaAcres": 2.50,
            "sowingDate": "2025-06-15",
            "harvestingDate": "2025-10-15",
            "cropStatus": "GROWING",
            "isActive": true
        }
    ]
}
```

---

### **STEP 21: Get Crop by ID**

Get a specific crop by its ID.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/{cropId}`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/{cropId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
GET http://localhost:4000/farmer/profile/crops/1
X-User-Id: 1
```

#### Expected Response

```json
{
    "message": "Crop retrieved successfully",
    "data": {
        "id": 1,
        "farmId": 1,
        "farmName": "Main Farm",
        "cropTypeId": 1,
        "cropTypeName": "VEGETABLE",
        "cropTypeDisplayName": "Vegetables",
        "cropNameId": 1,
        "cropName": "TOMATO",
        "cropDisplayName": "Tomato",
        "cropLocalName": "टमाटर",
        "areaAcres": 2.50,
        "sowingDate": "2025-06-15",
        "harvestingDate": "2025-10-15",
        "cropStatus": "GROWING",
        "isActive": true,
        "createdAt": "2025-12-09T11:07:40",
        "updatedAt": "2025-12-09T11:07:40"
    }
}
```

---

### **STEP 22: Update Crop**

Update an existing crop (e.g., change area, update status after sowing).

#### Request

- **Method:** `PUT`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/{cropId}`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/{cropId}`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer {your-access-token}
  ```
- **Body:**
  ```json
  {
      "farmId": 1,
      "cropNameId": 1,
      "areaAcres": 3.00,
      "sowingDate": "2025-06-20",
      "harvestingDate": "2025-10-20",
      "cropStatus": "SOWN"
  }
  ```

#### Expected Response

```json
{
    "message": "Crop updated successfully",
    "data": {
        "id": 1,
        "farmId": 1,
        "farmName": "Main Farm",
        "cropTypeId": 1,
        "cropTypeName": "VEGETABLE",
        "cropTypeDisplayName": "Vegetables",
        "cropNameId": 1,
        "cropName": "TOMATO",
        "cropDisplayName": "Tomato",
        "cropLocalName": "टमाटर",
        "areaAcres": 3.00,
        "sowingDate": "2025-06-20",
        "harvestingDate": "2025-10-20",
        "cropStatus": "SOWN",
        "isActive": true,
        "createdAt": "2025-12-09T11:07:40",
        "updatedAt": "2025-12-09T11:15:00"
    }
}
```

---

### **STEP 23: Delete Crop**

Soft delete a crop (sets `isActive = false`).

#### Request

- **Method:** `DELETE`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/{cropId}`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/{cropId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
DELETE http://localhost:4000/farmer/profile/crops/1
X-User-Id: 1
```

#### Expected Response

```json
{
    "message": "Crop deleted successfully",
    "data": null
}
```

---

### **STEP 24: Get Crop Count for Farm**

Get the count of active crops for a specific farm.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/farm/{farmId}/count`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/farm/{farmId}/count`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
GET http://localhost:4000/farmer/profile/crops/farm/1/count
X-User-Id: 1
```

#### Expected Response

```json
{
    "message": "Crop count retrieved successfully",
    "data": 3
}
```

---

### **STEP 25: Get Crops by Type**

Get all crops of a specific type for the farmer.

#### Request

- **Method:** `GET`
- **URL (Direct):** `http://localhost:4000/farmer/profile/crops/type/{cropTypeId}`
- **URL (Via Gateway):** `http://localhost:4004/farmer/profile/crops/type/{cropTypeId}`
- **Headers:**
  ```
  Authorization: Bearer {your-access-token}
  ```

#### Example

```
GET http://localhost:4000/farmer/profile/crops/type/1
X-User-Id: 1
```

#### Expected Response

```json
{
    "message": "Crops retrieved successfully",
    "data": [
        {
            "id": 1,
            "farmId": 1,
            "farmName": "Main Farm",
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "cropNameId": 1,
            "cropName": "TOMATO",
            "cropDisplayName": "Tomato",
            "areaAcres": 2.50,
            "sowingDate": "2025-06-15",
            "harvestingDate": "2025-10-15",
            "cropStatus": "GROWING",
            "isActive": true
        },
        {
            "id": 2,
            "farmId": 1,
            "farmName": "Main Farm",
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "cropNameId": 2,
            "cropName": "ONION",
            "cropDisplayName": "Onion",
            "areaAcres": 3.00,
            "sowingDate": "2025-07-01",
            "harvestingDate": "2025-11-15",
            "cropStatus": "SOWN",
            "isActive": true
        }
    ]
}
```

---

## 👨‍💼 Admin Endpoints - Crop Management

These endpoints allow admins to manage crop types and names. Changes reflect immediately on the farmer app.

---

### **STEP 26: Admin - Get All Crop Types**

Get all crop types including inactive ones (for admin panel).

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4000/farmer/admin/crop-types`
- **Headers:** None required

#### Expected Response

```json
{
    "message": "Crop types retrieved successfully",
    "data": [
        {
            "id": 1,
            "typeName": "VEGETABLE",
            "displayName": "Vegetables",
            "description": "Fresh vegetables...",
            "displayOrder": 1,
            "isActive": true,
            "cropNameCount": 31
        },
        {
            "id": 11,
            "typeName": "NUTS_SEEDS",
            "displayName": "Nuts & Seeds",
            "description": "Edible nuts and seeds",
            "displayOrder": 11,
            "isActive": false,
            "cropNameCount": 5
        }
    ]
}
```

---

### **STEP 27: Admin - Create Crop Type**

Create a new crop type/category.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4000/farmer/admin/crop-types`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body:**
  ```json
  {
      "typeName": "ORGANIC_PRODUCE",
      "displayName": "Organic Produce",
      "description": "Certified organic farm products",
      "displayOrder": 12,
      "isActive": true
  }
  ```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `typeName` | String | Yes | Unique identifier (will be uppercased, spaces → underscores) |
| `displayName` | String | Yes | Display name for UI |
| `description` | String | No | Description of crop type |
| `iconUrl` | String | No | S3 URL for icon |
| `displayOrder` | Integer | No | Order in dropdown (lower = first) |
| `isActive` | Boolean | No | Default: true |

#### Expected Response (201 Created)

```json
{
    "message": "Crop type created successfully",
    "data": {
        "id": 12,
        "typeName": "ORGANIC_PRODUCE",
        "displayName": "Organic Produce",
        "description": "Certified organic farm products",
        "iconUrl": null,
        "displayOrder": 12,
        "isActive": true,
        "cropNameCount": 0,
        "createdAt": "2025-12-09T12:00:00",
        "updatedAt": "2025-12-09T12:00:00"
    }
}
```

---

### **STEP 28: Admin - Update Crop Type**

Update an existing crop type.

#### Request

- **Method:** `PUT`
- **URL:** `http://localhost:4000/farmer/admin/crop-types/{id}`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body:**
  ```json
  {
      "typeName": "ORGANIC_PRODUCE",
      "displayName": "Organic Products",
      "description": "Certified organic farm products - Updated",
      "displayOrder": 11,
      "isActive": true
  }
  ```

#### Expected Response

```json
{
    "message": "Crop type updated successfully",
    "data": {
        "id": 12,
        "typeName": "ORGANIC_PRODUCE",
        "displayName": "Organic Products",
        "description": "Certified organic farm products - Updated",
        "displayOrder": 11,
        "isActive": true,
        "cropNameCount": 0,
        "updatedAt": "2025-12-09T12:05:00"
    }
}
```

---

### **STEP 29: Admin - Delete Crop Type**

Soft delete a crop type (sets `isActive = false`).

#### Request

- **Method:** `DELETE`
- **URL:** `http://localhost:4000/farmer/admin/crop-types/{id}`
- **Headers:** None required

#### Example

```
DELETE http://localhost:4000/farmer/admin/crop-types/12
```

#### Expected Response

```json
{
    "message": "Crop type deleted successfully",
    "data": null
}
```

---

### **STEP 30: Admin - Restore Crop Type**

Restore a deleted crop type.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4000/farmer/admin/crop-types/{id}/restore`
- **Headers:** None required

#### Example

```
POST http://localhost:4000/farmer/admin/crop-types/12/restore
```

#### Expected Response

```json
{
    "message": "Crop type restored successfully",
    "data": {
        "id": 12,
        "typeName": "ORGANIC_PRODUCE",
        "displayName": "Organic Products",
        "isActive": true
    }
}
```

---

### **STEP 31: Admin - Get Crop Names**

Get all crop names for admin management.

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4000/farmer/admin/crop-names`
- **URL (filtered):** `http://localhost:4000/farmer/admin/crop-names?typeId=1`
- **Headers:** None required
- **Query Parameters:**
  | Parameter | Required | Description |
  |-----------|----------|-------------|
  | `typeId` | No | Filter by crop type ID |

#### Expected Response

```json
{
    "message": "Crop names retrieved successfully",
    "data": [
        {
            "id": 1,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "TOMATO",
            "displayName": "Tomato",
            "localName": "टमाटर",
            "displayOrder": 1,
            "isActive": true
        },
        {
            "id": 2,
            "cropTypeId": 1,
            "cropTypeName": "VEGETABLE",
            "cropTypeDisplayName": "Vegetables",
            "name": "ONION",
            "displayName": "Onion",
            "localName": "कांदा",
            "displayOrder": 2,
            "isActive": true
        }
    ]
}
```

---

### **STEP 32: Admin - Create Crop Name**

Create a new crop name under a crop type.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4000/farmer/admin/crop-names`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body:**
  ```json
  {
      "cropTypeId": 1,
      "name": "BITTER_MELON",
      "displayName": "Bitter Melon",
      "localName": "कारेले",
      "description": "Green bitter vegetable",
      "displayOrder": 50,
      "isActive": true
  }
  ```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `cropTypeId` | Long | Yes | Parent crop type ID |
| `name` | String | Yes | Unique name within type (will be uppercased) |
| `displayName` | String | Yes | Display name for UI |
| `localName` | String | No | Local/Regional name (e.g., Marathi, Hindi) |
| `description` | String | No | Description of crop |
| `iconUrl` | String | No | S3 URL for icon |
| `displayOrder` | Integer | No | Order in dropdown |
| `isActive` | Boolean | No | Default: true |

#### Expected Response (201 Created)

```json
{
    "message": "Crop name created successfully",
    "data": {
        "id": 145,
        "cropTypeId": 1,
        "cropTypeName": "VEGETABLE",
        "cropTypeDisplayName": "Vegetables",
        "name": "BITTER_MELON",
        "displayName": "Bitter Melon",
        "localName": "कारेले",
        "description": "Green bitter vegetable",
        "iconUrl": null,
        "displayOrder": 50,
        "isActive": true,
        "createdAt": "2025-12-09T12:10:00",
        "updatedAt": "2025-12-09T12:10:00"
    }
}
```

---

### **STEP 33: Admin - Update Crop Name**

Update an existing crop name.

#### Request

- **Method:** `PUT`
- **URL:** `http://localhost:4000/farmer/admin/crop-names/{id}`
- **Headers:**
  ```
  Content-Type: application/json
  ```
- **Body:**
  ```json
  {
      "cropTypeId": 1,
      "name": "BITTER_MELON",
      "displayName": "Bitter Melon (Karela)",
      "localName": "कारेला",
      "displayOrder": 17,
      "isActive": true
  }
  ```

#### Expected Response

```json
{
    "message": "Crop name updated successfully",
    "data": {
        "id": 145,
        "cropTypeId": 1,
        "name": "BITTER_MELON",
        "displayName": "Bitter Melon (Karela)",
        "localName": "कारेला",
        "displayOrder": 17,
        "isActive": true,
        "updatedAt": "2025-12-09T12:15:00"
    }
}
```

---

### **STEP 34: Admin - Delete Crop Name**

Soft delete a crop name.

#### Request

- **Method:** `DELETE`
- **URL:** `http://localhost:4000/farmer/admin/crop-names/{id}`
- **Headers:** None required

#### Example

```
DELETE http://localhost:4000/farmer/admin/crop-names/145
```

#### Expected Response

```json
{
    "message": "Crop name deleted successfully",
    "data": null
}
```

---

### **STEP 35: Admin - Restore Crop Name**

Restore a deleted crop name.

#### Request

- **Method:** `POST`
- **URL:** `http://localhost:4000/farmer/admin/crop-names/{id}/restore`
- **Headers:** None required

#### Expected Response

```json
{
    "message": "Crop name restored successfully",
    "data": {
        "id": 145,
        "name": "BITTER_MELON",
        "displayName": "Bitter Melon (Karela)",
        "isActive": true
    }
}
```

---

### **STEP 36: Admin - Search Crop Names**

Search crop names by term (for admin panel search).

#### Request

- **Method:** `GET`
- **URL:** `http://localhost:4000/farmer/admin/crop-names/search?term=mango`
- **Headers:** None required

#### Expected Response

```json
{
    "message": "Crop names retrieved successfully",
    "data": [
        {
            "id": 33,
            "cropTypeId": 2,
            "cropTypeName": "FRUIT",
            "cropTypeDisplayName": "Fruits",
            "name": "MANGO",
            "displayName": "Mango",
            "localName": "आंबा",
            "isActive": true
        }
    ]
}
```

---

## 🔍 Crop Error Scenarios to Test

### 1. Crop Area Exceeds Farm Size

**Request:**
```
POST http://localhost:4000/farmer/profile/crops
X-User-Id: 1
Body:
{
    "farmId": 1,
    "cropNameId": 1,
    "areaAcres": 100.00
}
```

**Expected Response (400 Bad Request):**
```json
{
    "message": "Total crop area (100.00 acres) cannot exceed farm area (10.50 acres). Available area: 4.00 acres",
    "data": null
}
```

### 2. Duplicate Crop on Same Farm

**Request:**
```
POST http://localhost:4000/farmer/profile/crops
X-User-Id: 1
Body:
{
    "farmId": 1,
    "cropNameId": 1,
    "areaAcres": 2.00
}
```

**Expected Response (if Tomato already exists on farm 1):**
```json
{
    "message": "This crop already exists on this farm. Please update the existing crop instead.",
    "data": null
}
```

### 3. Invalid Crop Name ID

**Request:**
```
POST http://localhost:4000/farmer/profile/crops
X-User-Id: 1
Body:
{
    "farmId": 1,
    "cropNameId": 9999,
    "areaAcres": 2.00
}
```

**Expected Response:**
```json
{
    "message": "Crop name not found or inactive with ID: 9999",
    "data": null
}
```

### 4. Crop Not Found

**Request:**
```
GET http://localhost:4000/farmer/profile/crops/999
X-User-Id: 1
```

**Expected Response:**
```json
{
    "message": "Crop not found with ID: 999",
    "data": null
}
```

### 5. Admin - Duplicate Crop Type Name

**Request:**
```
POST http://localhost:4000/farmer/admin/crop-types
Body:
{
    "typeName": "VEGETABLE",
    "displayName": "Veggies"
}
```

**Expected Response:**
```json
{
    "message": "Crop type with name 'VEGETABLE' already exists",
    "data": null
}
```

### 6. Admin - Duplicate Crop Name in Same Type

**Request:**
```
POST http://localhost:4000/farmer/admin/crop-names
Body:
{
    "cropTypeId": 1,
    "name": "TOMATO",
    "displayName": "Tomato Red"
}
```

**Expected Response:**
```json
{
    "message": "Crop name 'TOMATO' already exists for this crop type",
    "data": null
}
```

---

## ✅ CropRequest Validation Rules

| Field | Rules |
|-------|-------|
| `farmId` | Required, Must be valid farm ID owned by user |
| `cropNameId` | Required, Must be active crop name ID |
| `areaAcres` | Required, Must be > 0, Cannot exceed farm's available area |
| `sowingDate` | Optional, Date format: YYYY-MM-DD |
| `harvestingDate` | Optional, Date format: YYYY-MM-DD |
| `cropStatus` | Optional, One of: PLANNED, SOWN, GROWING, HARVESTED, FAILED (default: PLANNED) |

---

## 📊 Pre-Seeded Crop Data Summary

| Crop Type | Display Name | Crop Names Count |
|-----------|--------------|------------------|
| VEGETABLE | Vegetables | 31 |
| FRUIT | Fruits | 26 |
| GRAIN_CEREAL | Grains & Cereals | 9 |
| PULSES_LEGUMES | Pulses & Legumes | 12 |
| SPICES | Spices | 16 |
| OILSEEDS | Oilseeds | 10 |
| CASH_CROPS | Cash Crops | 8 |
| DAIRY_MILK | Dairy & Milk Products | 10 |
| FLOWERS | Flowers | 11 |
| MEDICINAL_HERBS | Medicinal & Herbs | 11 |
| **Total** | **10 Types** | **144 Crop Names** |

---

## 🎯 Complete Crop Testing Flow

### Recommended Test Order:

1. ✅ **Get Crop Types** - Verify 10+ types exist
2. ✅ **Get Crop Names (Vegetables)** - Verify dropdown data
3. ✅ **Search Crop Names** - Test autocomplete
4. ✅ **Create Crop (Tomato)** - Add first crop
5. ✅ **Create Crop (Onion)** - Add second crop
6. ✅ **Create Crop (Mango - Fruit)** - Add crop from different type
7. ✅ **Get All Crops** - Verify all crops shown
8. ✅ **Get Crops by Farm** - Verify farm-specific crops
9. ✅ **Get Crop by ID** - Verify specific crop
10. ✅ **Update Crop** - Modify area
11. ✅ **Test Area Validation** - Try to exceed farm size
12. ✅ **Test Duplicate Prevention** - Try to add same crop again
13. ✅ **Delete Crop** - Soft delete
14. ✅ **Get Crop Count** - Verify count decreased

### Admin Testing:

15. ✅ **Admin: Get All Types** - Verify admin view
16. ✅ **Admin: Create Type** - Add new category
17. ✅ **Admin: Create Name** - Add crop to new category
18. ✅ **Verify Farmer Dropdown** - New type appears
19. ✅ **Admin: Delete Type** - Soft delete
20. ✅ **Admin: Restore Type** - Restore deleted
21. ✅ **Test Admin Validations** - Duplicates, etc.

---

**Happy Testing! 🚀**
