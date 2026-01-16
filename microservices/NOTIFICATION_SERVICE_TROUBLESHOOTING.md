# Notification Service Troubleshooting Guide

## Issue: Notifications Not Received in Farmer App

### Root Cause
Kafka was not running, so:
1. Field Officer Service could not send events to Kafka (events were lost)
2. Notification Service could not consume events from Kafka
3. No notifications were stored in the database
4. Farmer app had nothing to fetch

### Solution Applied
1. **Fixed Kafka Configuration**: Updated `docker-compose.yml` to fix listener configuration
2. **Started Kafka**: Restarted Kafka and Zookeeper containers

### Verification Steps

#### 1. Check Kafka is Running
```powershell
docker ps | findstr kafka
docker ps | findstr zookeeper
```

Both should show "Up" status.

#### 2. Check Kafka Logs
```powershell
docker logs kafka --tail 50
```

Look for:
- `INFO [KafkaServer id=1] started` - Kafka started successfully
- `INFO [GroupCoordinator 1]: Stabilized group notification-service-group` - Consumer connected

#### 3. Check Notification Service Logs
Look for:
- `Connection to node -1 (localhost/127.0.0.1:9092) could not be established` - **BAD** (Kafka not accessible)
- `Received notification event` - **GOOD** (Events being consumed)

#### 4. Test the Flow

**Step 1: Request OTP from Field Officer**
- Field Officer requests OTP for a farm
- Check Field Officer Service logs for: `Sent farm verification OTP notification event`

**Step 2: Check Notification Service**
- Check Notification Service logs for: `Received notification event`
- Check Notification Service logs for: `Notification saved successfully`

**Step 3: Check Database**
```sql
SELECT * FROM notifications 
WHERE event_type = 'FARM_VERIFICATION_OTP' 
ORDER BY created_at DESC 
LIMIT 5;
```

**Step 4: Check Farmer App**
- Farmer app polls every 10 seconds
- Check browser/device console for API calls to `/notification/unread/FARM_VERIFICATION_OTP`
- OTP should appear as a banner on home screen

### Common Issues

#### Issue 1: Kafka Not Running
**Symptoms:**
- Notification Service logs show: `Connection to node -1 could not be established`
- No events being consumed

**Solution:**
```powershell
cd microservices
docker-compose up -d zookeeper kafka
# Wait 10-15 seconds for Kafka to start
docker logs kafka --tail 20
```

#### Issue 2: Kafka Configuration Error
**Symptoms:**
- Kafka container exits immediately
- Logs show: `Each listener must have a different port`

**Solution:**
- Already fixed in `docker-compose.yml`
- If issue persists, restart Kafka:
```powershell
docker stop kafka
docker rm kafka
docker-compose up -d kafka
```

#### Issue 3: Notification Service Not Consuming
**Symptoms:**
- Kafka is running
- Field Officer sends events (logs show "Sent notification event")
- But Notification Service doesn't receive them

**Solution:**
1. Check Notification Service is running:
```powershell
# Check if service is running on port 4016
netstat -ano | findstr :4016
```

2. Restart Notification Service:
```powershell
# Stop the service (Ctrl+C if running in terminal)
# Then restart:
cd microservices/java-spring-microservices
mvn spring-boot:run -pl :notification-service
```

3. Check consumer group:
```powershell
docker exec -it kafka kafka-consumer-groups --bootstrap-server localhost:9092 --group notification-service-group --describe
```

#### Issue 4: Farmer App Not Fetching Notifications
**Symptoms:**
- Notifications exist in database
- But farmer app doesn't show them

**Solution:**
1. Check API Gateway is routing correctly:
   - Request should go to: `http://localhost:4004/notification/unread/FARM_VERIFICATION_OTP`
   - Should route to: `http://localhost:4016/notification/unread/FARM_VERIFICATION_OTP`

2. Check farmer app console for errors:
   - Open browser DevTools (F12)
   - Check Network tab for `/notification/unread/FARM_VERIFICATION_OTP` requests
   - Check Console for errors

3. Verify user ID is being sent:
   - Check request headers include: `X-User-Id: <farmerUserId>`
   - This should be set by API Gateway from JWT token

### Testing Commands

#### Test Kafka Topic
```powershell
# List topics
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list

# Check NOTIFICATION_EVENTS topic
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic NOTIFICATION_EVENTS

# Consume messages manually (for testing)
docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic NOTIFICATION_EVENTS --from-beginning
```

#### Test Notification API
```powershell
# Get unread notifications (replace USER_ID with actual farmer user ID)
$headers = @{
    "X-User-Id" = "USER_ID"
    "Authorization" = "Bearer YOUR_TOKEN"
}
Invoke-WebRequest -Uri "http://localhost:4004/notification/unread/FARM_VERIFICATION_OTP" -Headers $headers
```

### Quick Fix Checklist

When notifications are not working:

- [ ] Kafka is running (`docker ps | findstr kafka`)
- [ ] Zookeeper is running (`docker ps | findstr zookeeper`)
- [ ] Notification Service is running (port 4016)
- [ ] Field Officer Service is sending events (check logs)
- [ ] Notification Service is consuming events (check logs)
- [ ] Notifications exist in database (check PostgreSQL)
- [ ] API Gateway is routing correctly (port 4004 → 4016)
- [ ] Farmer app is polling (check browser console)
- [ ] User ID is being sent in headers (check Network tab)

### Next Steps After Fix

1. **Request OTP again** from Field Officer (old events may have been lost)
2. **Wait 10-15 seconds** for farmer app to poll
3. **Check farmer app home screen** for OTP notification banner
4. **Verify OTP matches** what was sent to Kafka
