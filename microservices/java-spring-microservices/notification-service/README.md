# Notification Service

## Overview
The Notification Service consumes Kafka events from the `NOTIFICATION_EVENTS` topic and stores them in the database. It provides REST API endpoints for clients (Farmer App, Admin Portal, etc.) to fetch their notifications.

## Port
- **4016**

## Features
- Kafka Consumer for `NOTIFICATION_EVENTS` topic
- Stores notifications in PostgreSQL database
- REST API for fetching notifications
- Support for different notification types (FARM_VERIFICATION_OTP, etc.)
- Unread notification tracking
- Pagination support

## Database
- **Schema**: `notification_db`
- **Port**: `5441` (localhost), `5432` (Docker)

## Kafka Configuration
- **Topic**: `NOTIFICATION_EVENTS`
- **Consumer Group**: `notification-service-group`
- **Auto Offset Reset**: `earliest`

## API Endpoints

### Get Unread Notifications by Type
```
GET /notification/unread/{eventType}
Headers: X-User-Id: <userId>
Example: GET /notification/unread/FARM_VERIFICATION_OTP
```

### Get All Unread Notifications
```
GET /notification/unread
Headers: X-User-Id: <userId>
```

### Get All Notifications (Paginated)
```
GET /notification?page=0&size=20
Headers: X-User-Id: <userId>
```

### Get Unread Count
```
GET /notification/unread-count
Headers: X-User-Id: <userId>
```

### Mark Notification as Read
```
PUT /notification/{notificationId}/read
Headers: X-User-Id: <userId>
```

### Mark All Notifications as Read
```
PUT /notification/read-all
Headers: X-User-Id: <userId>
```

## Notification Event Structure

The service consumes `NotificationEvent` from Kafka with the following structure:
```json
{
  "eventType": "FARM_VERIFICATION_OTP",
  "recipientUserId": 123,
  "recipientPhoneNumber": "+919876543210",
  "title": "Farm Verification OTP",
  "message": "Field Officer John is verifying your farm 'Farm Name'. Your OTP: 123456",
  "data": {
    "otp": "123456",
    "farmId": 1,
    "farmName": "Farm Name",
    "fieldOfficerName": "John"
  },
  "timestamp": "2024-01-13T10:30:00",
  "priority": "HIGH"
}
```

## Building
```bash
mvn clean install -pl :notification-service -am
```

## Running

### Local
```bash
# Make sure PostgreSQL and Kafka are running
# Update application.yml with correct database and Kafka URLs
mvn spring-boot:run -pl :notification-service
```

### Docker
```bash
docker-compose up notification-service
```

## Testing

1. **Start Kafka and PostgreSQL**:
   ```bash
   docker-compose up kafka zookeeper notification-db
   ```

2. **Start Notification Service**:
   ```bash
   mvn spring-boot:run -pl :notification-service
   ```

3. **Send a test event to Kafka** (from Field Officer Service):
   - Request OTP for a farm verification
   - The event will be automatically consumed and stored

4. **Fetch notifications**:
   ```bash
   curl -H "X-User-Id: 123" http://localhost:4004/notification/unread/FARM_VERIFICATION_OTP
   ```

## Integration with Farmer App

The Farmer App polls the notification service every 10 seconds to fetch new OTP notifications:

```dart
// In home_screen.dart
_notificationService.startPolling(interval: const Duration(seconds: 10));
```

The app displays OTP notifications as banners on the home screen, allowing farmers to see the OTP when a field officer requests farm verification.

## Future Enhancements

- [ ] Push notifications via FCM (Firebase Cloud Messaging)
- [ ] SMS notifications via SMS gateway
- [ ] Email notifications
- [ ] WebSocket support for real-time notifications
- [ ] Notification preferences per user
- [ ] Retry mechanism for failed notifications
- [ ] Dead letter queue for failed events
