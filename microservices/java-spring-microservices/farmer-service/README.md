# Farmer Service

Farmer Profile and Management Service for Krushi Kranti platform.

## Overview

The Farmer Service manages farmer profiles including:
- **My Details**: Personal Information, Contact Details, Address Details
- **Farm Details**: Farm information used as collateral for loan approval
- **Crop Details**: Crops grown on farms (database-driven master data)

## Architecture

- **Database**: PostgreSQL (farmer_db)
- **Inter-Service Communication**: gRPC (calls Auth Service for user info)
- **API Gateway**: Routes `/farmer/**` requests to this service
- **Authentication**: JWT validation handled by API Gateway (X-User-Id header passed)

## Database Schema

### farmers table
- Stores farmer profile information
- Links to `auth.users` via `user_id`

### farms table
- Stores farm details (basic info + collateral data)
- Links to `farmers` via `farmer_id`
- Used for loan collateral verification

### pincode_master table
- Stores pincode → address mapping (district, taluka, state, villages)
- Populated from Excel file import

### crop_types table (Master)
- Stores crop categories (Vegetables, Fruits, Grains, etc.)
- Admin can add/edit/delete - reflects on farmer app

### crop_names table (Master)
- Stores crop names under each type (Tomato, Onion, etc.)
- Includes local language names (Marathi)
- Admin can add/edit/delete - reflects on farmer app

### crops table
- Stores farmer's crops on farms
- Links to `farms` via `farm_id`
- Links to `crop_names` via `crop_name_id`

## API Endpoints

### Profile Management - My Details

#### GET `/farmer/profile/my-details`
Get farmer's "My Details" profile.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: `MyDetailsResponse` with all profile data including email/phone from Auth Service

#### PUT `/farmer/profile/my-details`
Create or update farmer's "My Details" profile.
- **Headers**: `X-User-Id` (from API Gateway)
- **Body**: `MyDetailsRequest`
- **Response**: `MyDetailsResponse`

### Farm Management

#### GET `/farmer/profile/farms`
Get all farms for the logged-in farmer.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: List of `FarmResponse`

#### GET `/farmer/profile/farms/{farmId}`
Get a specific farm by ID.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: `FarmResponse`

#### POST `/farmer/profile/farms`
Create a new farm.
- **Headers**: `X-User-Id` (from API Gateway)
- **Body**: `FarmRequest`
- **Response**: `FarmResponse` (201 Created)

#### PUT `/farmer/profile/farms/{farmId}`
Update an existing farm.
- **Headers**: `X-User-Id` (from API Gateway)
- **Body**: `FarmRequest`
- **Response**: `FarmResponse`

#### DELETE `/farmer/profile/farms/{farmId}`
Soft delete a farm.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: Success message

#### GET `/farmer/profile/farms/count`
Get count of active farms for the farmer.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: Count (Long)

#### GET `/farmer/profile/farms/collateral`
Get farms that are valid for loan collateral.
- **Headers**: `X-User-Id` (from API Gateway)
- **Response**: List of valid collateral `FarmResponse`

### Address Lookup

#### GET `/farmer/profile/address/lookup?pincode={pincode}`
Lookup address details by pincode.
- **Query Params**: `pincode` (6 digits)
- **Response**: `AddressLookupResponse` with district, taluka, state, and list of villages

### Admin/Development

#### POST `/farmer/admin/pincode/import`
Import pincode data from Excel file.
- **Body**: `{ "filePath": "path/to/file.xlsx" }`
- **Response**: Number of records imported

#### GET `/farmer/admin/pincode/count`
Get count of pincode records in database.

### Crop Management

#### GET `/farmer/profile/crop-types`
Get all active crop types for dropdown.

#### GET `/farmer/profile/crop-names?typeId={id}`
Get crop names for a specific crop type.

#### GET `/farmer/profile/crops`
Get all crops for the logged-in farmer (across all farms).

#### GET `/farmer/profile/crops/farm/{farmId}`
Get crops for a specific farm.

#### POST `/farmer/profile/crops`
Create a new crop on a farm.
- **Body**: `{ "farmId": 1, "cropNameId": 1, "areaAcres": 2.5 }`

#### PUT `/farmer/profile/crops/{cropId}`
Update an existing crop.

#### DELETE `/farmer/profile/crops/{cropId}`
Soft delete a crop.

### Crop Admin (For Admin Panel)

#### CRUD `/farmer/admin/crop-types`
Full CRUD for crop types (admin only).

#### CRUD `/farmer/admin/crop-names`
Full CRUD for crop names (admin only).

See [CropDetails.md](CropDetails.md) for complete API documentation.

## Farm Details Schema

### Basic Farm Information (Farmer fills)
- `farmName`: Name of the farm
- `farmType`: ORGANIC, CONVENTIONAL, MIXED, VERMI_COMPOST
- `totalAreaAcres`: Total area in acres
- `pincode`, `village`, `district`, `taluka`, `state`: Address
- `soilType`: BLACK, RED, SANDY, LOAMY, CLAY, MIXED
- `irrigationType`: DRIP, SPRINKLER, RAINFED, CANAL, BORE_WELL, OPEN_WELL, MIXED
- `landOwnership`: OWNED, LEASED, SHARED, GOVERNMENT_ALLOTTED

### Collateral Information (For Loan Recovery)
- `surveyNumber`: Survey/Plot number
- `landRegistrationNumber`: Land registration document number
- `pattaNumber`: Patta/Record of Rights number
- `estimatedLandValue`: Estimated value in INR
- `encumbranceStatus`: NOT_VERIFIED, FREE, ENCUMBERED, PARTIALLY_ENCUMBERED
- `encumbranceRemarks`: Details if encumbered
- Document URLs (S3): `landDocumentUrl`, `surveyMapUrl`, `registrationCertificateUrl`

### Verification Status (On-field Officer fills)
- `isVerified`: Whether verified by on-field officer
- `verifiedBy`: Officer user ID
- `verifiedAt`: Verification timestamp
- `verificationRemarks`: Officer's remarks

## Loan Collateral Validation

A farm is valid for loan collateral if:
- `isVerified = true` (verified by on-field officer)
- `encumbranceStatus = FREE` (no encumbrances)
- `landOwnership` is `OWNED` or `GOVERNMENT_ALLOTTED`
- `estimatedLandValue > 0`

## gRPC Integration

The service calls Auth Service via gRPC to fetch user information:
- **Method**: `GetUserById(userId)`
- **Returns**: email, phoneNumber, username, roles, active status

## Running the Service

### Local Development
```bash
mvn spring-boot:run -pl farmer-service
```

### Docker
```bash
docker-compose up farmer-service
```

## Configuration

### application.yml (localhost)
- Database: `localhost:5450/farmer_db`
- gRPC Auth Service: `localhost:9090`

### application-docker.yml (Docker)
- Database: `farmer-db:5432/farmer_db`
- gRPC Auth Service: `auth-service:9090`

## Dependencies

- Spring Boot 3.2.0
- PostgreSQL
- gRPC Client (for Auth Service)
- Apache POI (for Excel import)
- Flyway (for database migrations)
- Lombok

## Testing

Run all tests:
```bash
mvn test -pl :farmer-service
```

Run specific tests:
```bash
mvn test -pl :farmer-service -Dtest=FarmServiceTest
mvn test -pl :farmer-service -Dtest=FarmRepositoryTest
mvn test -pl :farmer-service -Dtest=FarmControllerIntegrationTest
```

## Next Steps

Future enhancements:
- On-field Officer verification endpoints (ONFIELD_OFFICER role)
- KYC section
- ~~Crop management~~ ✅ Implemented
- Bank details
- gRPC endpoints for Funding Service integration
