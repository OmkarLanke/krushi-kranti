# Field Officer Service

Field Officer Management and Farm Verification Service for Krushi Kranti platform.

## Overview

The Field Officer Service manages:
- **Field Officer Profiles**: Personal information and contact details
- **Assignments**: Assignment of field officers to farmers for farm verification
- **Farm Verifications**: Verification of farms with photos and feedback
- **Verification Photos**: Photo management for farm verifications

## Architecture

- **Database**: PostgreSQL (field_officer_db)
- **Inter-Service Communication**: 
  - REST (WebClient) to call Auth Service and Farmer Service
  - gRPC (future) for optimized communication
- **API Gateway**: Routes `/field-officer/**` and `/admin/field-officers/**` requests to this service
- **Authentication**: JWT validation handled by API Gateway (X-User-Id header passed)

## Database Schema

### field_officers table
- Stores field officer profile information
- Links to `auth.users` via `user_id`

### field_officer_assignments table
- Stores assignments of field officers to farmers
- Tracks assignment status (ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED)

### farm_verifications table
- Stores farm verification records
- Links to farms in farmer-service (via `farm_id`)
- Tracks verification status (PENDING, VERIFIED, REJECTED, IN_PROGRESS)

### verification_photos table
- Stores photo metadata for verifications
- Photo URLs point to S3 (via File Service)

## API Endpoints

### Admin Endpoints

#### POST `/admin/field-officers`
Create a new field officer.
- **Headers**: `Authorization: Bearer <token>` (ADMIN role required)
- **Body**: `CreateFieldOfficerRequest`
- **Response**: `FieldOfficerSummaryDto`

#### GET `/admin/field-officers`
Get paginated list of all field officers.
- **Headers**: `Authorization: Bearer <token>` (ADMIN role required)
- **Query Params**: `page`, `size`, `search`, `isActive`
- **Response**: Paginated list of `FieldOfficerSummaryDto`

### Field Officer Endpoints

#### GET `/field-officer/profile`
Get field officer's own profile.
- **Headers**: `Authorization: Bearer <token>` (FIELD_OFFICER role required)
- **Response**: Field officer profile

#### GET `/field-officer/health`
Health check endpoint.
- **Response**: Service status

## Building

```bash
mvn clean install -pl :field-officer-service -am
```

## Running

```bash
# Local
mvn spring-boot:run -pl :field-officer-service

# Docker
docker-compose up field-officer-service
```

## Port

- **4015** (Local)
- **4015** (Docker)

## Future Enhancements

- Assignment management endpoints
- Farm verification endpoints with photo upload
- Field officer dashboard with statistics
- Visit scheduling and route optimization
- GPS tracking for field visits

