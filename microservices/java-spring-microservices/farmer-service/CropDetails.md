# Crop Details - Farmer Service

## Overview

The Crop Details module allows farmers to add crops to their farms. The crop data is powered by **database-driven master tables** that admin can manage, ensuring dynamic updates without code changes.

## Architecture

### Database Tables

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  crop_types     │       │  crop_names     │       │  crops          │
│  (Master)       │       │  (Master)       │       │  (Farmer Data)  │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id              │◄──────│ crop_type_id    │       │ id              │
│ type_name       │       │ id              │◄──────│ crop_name_id    │
│ display_name    │       │ name            │       │ farm_id         │
│ icon_url        │       │ display_name    │       │ area_acres      │
│ display_order   │       │ local_name      │       │ ...             │
│ is_active       │       │ display_order   │       │ is_active       │
└─────────────────┘       │ is_active       │       └─────────────────┘
     Admin                └─────────────────┘            Farmer
     Manages                   Admin                     Owns
                               Manages
```

## Crop Types (10 Categories)

| Type Name | Display Name | Description |
|-----------|--------------|-------------|
| VEGETABLE | Vegetables | Fresh vegetables including leafy greens, root vegetables, and gourds |
| FRUIT | Fruits | Fresh fruits including tropical, citrus, and seasonal fruits |
| GRAIN_CEREAL | Grains & Cereals | Staple grains and cereals like wheat, rice, and millets |
| PULSES_LEGUMES | Pulses & Legumes | Protein-rich pulses and legumes including dals and beans |
| SPICES | Spices | Aromatic spices and seasonings |
| OILSEEDS | Oilseeds | Oil-producing seeds like groundnut, mustard, and sesame |
| CASH_CROPS | Cash Crops | Commercial crops like sugarcane, cotton, and jute |
| DAIRY_MILK | Dairy & Milk Products | Milk and dairy products from farm animals |
| FLOWERS | Flowers | Ornamental and commercial flowers |
| MEDICINAL_HERBS | Medicinal & Herbs | Medicinal plants and culinary herbs |

## API Endpoints

### Farmer App APIs (Protected - Requires X-User-Id Header)

#### Master Data (Read-Only - For Dropdowns)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/farmer/profile/crop-types` | Get active crop types (Dropdown 1) |
| `GET` | `/farmer/profile/crop-names?typeId={id}` | Get crop names by type (Dropdown 2) |
| `GET` | `/farmer/profile/crop-names/search?term={term}` | Search crop names |

#### Farmer's Crops (CRUD)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/farmer/profile/crops` | Get all crops for farmer |
| `GET` | `/farmer/profile/crops/{cropId}` | Get specific crop |
| `GET` | `/farmer/profile/crops/farm/{farmId}` | Get crops for a farm |
| `GET` | `/farmer/profile/crops/farm/{farmId}/count` | Get crop count for farm |
| `GET` | `/farmer/profile/crops/type/{cropTypeId}` | Get crops by type |
| `POST` | `/farmer/profile/crops` | Create new crop |
| `PUT` | `/farmer/profile/crops/{cropId}` | Update crop |
| `DELETE` | `/farmer/profile/crops/{cropId}` | Delete crop (soft delete) |

### Admin Panel APIs (For Next.js Admin Panel)

#### Crop Types Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/farmer/admin/crop-types` | Get all crop types |
| `GET` | `/farmer/admin/crop-types/{id}` | Get specific crop type |
| `POST` | `/farmer/admin/crop-types` | Create new crop type |
| `PUT` | `/farmer/admin/crop-types/{id}` | Update crop type |
| `DELETE` | `/farmer/admin/crop-types/{id}` | Delete crop type (soft) |
| `POST` | `/farmer/admin/crop-types/{id}/restore` | Restore deleted type |

#### Crop Names Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/farmer/admin/crop-names?typeId={id}` | Get crop names (optionally by type) |
| `GET` | `/farmer/admin/crop-names/{id}` | Get specific crop name |
| `GET` | `/farmer/admin/crop-names/search?term={term}` | Search crop names |
| `POST` | `/farmer/admin/crop-names` | Create new crop name |
| `PUT` | `/farmer/admin/crop-names/{id}` | Update crop name |
| `DELETE` | `/farmer/admin/crop-names/{id}` | Delete crop name (soft) |
| `POST` | `/farmer/admin/crop-names/{id}/restore` | Restore deleted name |

## Request/Response Examples

### Get Crop Types (Dropdown 1)

**Request:**
```
GET /farmer/profile/crop-types
```

**Response:**
```json
{
  "message": "Crop types retrieved successfully",
  "data": [
    {
      "id": 1,
      "typeName": "VEGETABLE",
      "displayName": "Vegetables",
      "description": "Fresh vegetables...",
      "iconUrl": null,
      "displayOrder": 1,
      "isActive": true,
      "cropNameCount": 31
    },
    {
      "id": 2,
      "typeName": "FRUIT",
      "displayName": "Fruits",
      "description": "Fresh fruits...",
      "iconUrl": null,
      "displayOrder": 2,
      "isActive": true,
      "cropNameCount": 26
    }
  ]
}
```

### Get Crop Names (Dropdown 2)

**Request:**
```
GET /farmer/profile/crop-names?typeId=1
```

**Response:**
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

### Create Crop

**Request:**
```
POST /farmer/profile/crops
X-User-Id: 1

{
  "farmId": 1,
  "cropNameId": 1,
  "areaAcres": 2.5
}
```

**Response:**
```json
{
  "message": "Crop created successfully",
  "data": {
    "id": 1,
    "farmId": 1,
    "farmName": "Green Valley Farm",
    "cropTypeId": 1,
    "cropTypeName": "VEGETABLE",
    "cropTypeDisplayName": "Vegetables",
    "cropNameId": 1,
    "cropName": "TOMATO",
    "cropDisplayName": "Tomato",
    "cropLocalName": "टमाटर",
    "areaAcres": 2.50,
    "isActive": true,
    "createdAt": "2025-12-09T10:30:00",
    "updatedAt": "2025-12-09T10:30:00"
  }
}
```

### Admin: Create New Crop Type

**Request:**
```
POST /farmer/admin/crop-types

{
  "typeName": "NUTS_SEEDS",
  "displayName": "Nuts & Seeds",
  "description": "Edible nuts and seeds",
  "displayOrder": 11,
  "isActive": true
}
```

### Admin: Create New Crop Name

**Request:**
```
POST /farmer/admin/crop-names

{
  "cropTypeId": 11,
  "name": "ALMOND",
  "displayName": "Almond",
  "localName": "बदाम",
  "displayOrder": 1,
  "isActive": true
}
```

## Business Rules

1. **Crop Area Validation**: Total crop area on a farm cannot exceed the farm's total area
2. **Unique Crop per Farm**: Same crop cannot be added twice to the same farm
3. **Soft Delete**: All deletes are soft deletes (is_active = false)
4. **Admin Control**: Admin can add/edit/delete crop types and names
5. **Instant Reflect**: Changes by admin reflect immediately on farmer app

## Seed Data

The system is pre-seeded with:
- **10 Crop Types**
- **140+ Crop Names** with local (Marathi) translations

Each category includes an "Other" option for unlisted items.

## Files Created

```
farmer-service/
├── src/main/resources/db/migration/
│   ├── V4__create_crop_types_table.sql
│   ├── V5__create_crop_names_table.sql
│   ├── V6__create_crops_table.sql
│   └── V7__seed_crop_master_data.sql
│
├── src/main/java/com/krushikranti/farmer/
│   ├── model/
│   │   ├── CropType.java
│   │   ├── CropName.java
│   │   └── Crop.java
│   ├── repository/
│   │   ├── CropTypeRepository.java
│   │   ├── CropNameRepository.java
│   │   └── CropRepository.java
│   ├── dto/
│   │   ├── CropTypeRequest.java
│   │   ├── CropTypeResponse.java
│   │   ├── CropNameRequest.java
│   │   ├── CropNameResponse.java
│   │   ├── CropRequest.java
│   │   └── CropResponse.java
│   ├── service/
│   │   ├── CropTypeService.java
│   │   ├── CropNameService.java
│   │   └── CropService.java
│   └── controller/
│       ├── CropTypeAdminController.java
│       ├── CropNameAdminController.java
│       ├── CropMasterController.java
│       └── CropController.java
```

## Testing

Run the farmer-service and test the endpoints:

```bash
# Build
mvn clean install -pl :farmer-service -am

# Run
mvn spring-boot:run -pl :farmer-service

# Or with Docker
docker-compose up farmer-service farmer-db
```

## Next Steps

- [ ] Add Redis caching for master data
- [ ] Add bulk import for crop names (Excel)
- [ ] Add icon upload for crop types/names via File Service
- [ ] Add localization support for multiple languages

