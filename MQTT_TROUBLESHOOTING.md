# MQTT Connection Troubleshooting Guide

## Issue: App shows "CONNECTED" but no data received

### Root Cause
The app was subscribing to wrong MQTT topics:
- **Old topics**: `earthquake/data`, `earthquake/alert`, `earthquake/status`
- **Correct topics**: `eqnode.tarita/hub/#`, `pmac/#`, `TPO/#`

### Solution Applied

#### 1. Updated Flutter App Topics
File: `lib/services/mqtt_manager.dart`

Changed from:
```dart
final String _dataTopic = 'earthquake/data';
final String _alertTopic = 'earthquake/alert';
final String _statusTopic = 'earthquake/status';
```

To:
```dart
final String _dataTopic = 'eqnode.tarita/hub/#';
final String _alertTopic = 'eqnode.tarita/hub/alert';
final String _statusTopic = 'eqnode.tarita/hub/status';
final String _legacyDataTopic = 'earthquake/data';
final String _legacyAlertTopic = 'earthquake/alert';
```

#### 2. Updated Simulator Topic
File: `backend/simulate-earthquake.js`

Changed from:
```javascript
const MQTT_TOPIC = 'earthquake/data';
```

To:
```javascript
const MQTT_TOPIC = 'eqnode.tarita/hub/eqdata';
```

#### 3. Enhanced Data Processing
Made the app more flexible to accept data from various topic patterns and field names.

---

## Testing Steps

### Step 1: Test MQTT Connection
```bash
cd backend
node test-mqtt-connection.js
```

This will listen to all topics and show incoming messages.

### Step 2: Send Test Data (in another terminal)
```bash
cd backend
node simulate-earthquake.js
```

This will send 10 earthquake events to the broker.

### Step 3: Rebuild Flutter App
```bash
# Stop the app if running
flutter clean
flutter pub get
flutter run
```

### Step 4: Verify in App
1. Open the app
2. Check "MQTT Real-time" tab
3. You should now see:
   - ✅ MQTT Status: CONNECTED
   - ✅ Real-time earthquake data appearing
   - ✅ Total messages count increasing

---

## MQTT Broker Details

```
Hostname: mqtt.uiot.cloud
Port: 1883
Username: ethernet
Password: ei8jZz87wx
```

### Topics Structure
```
eqnode.tarita/hub/
├── eqdata          # Earthquake data
├── alert           # Alert messages
├── status          # Status updates
└── #               # Wildcard (all subtopics)

pmac/               # PMAC device data
TPO/                # TPO device data
earthquake/         # Legacy topics (backward compatibility)
```

---

## Verification Checklist

- [ ] Backend connects to MQTT broker successfully
- [ ] Backend can publish messages
- [ ] Test listener receives messages
- [ ] Flutter app shows "CONNECTED" status
- [ ] Flutter app receives and displays data
- [ ] Notifications work for magnitude >= 3.0

---

## Common Issues

### Issue: "Connection Refused"
**Solution**: Check credentials and network connectivity
```bash
# Test with mosquitto_pub (if installed)
mosquitto_pub -h mqtt.uiot.cloud -p 1883 -u ethernet -P ei8jZz87wx -t "test" -m "hello"
```

### Issue: Connected but no data
**Solution**: 
1. Verify topics match between publisher and subscriber
2. Check QoS levels (use QoS 1 for guaranteed delivery)
3. Ensure data format is valid JSON

### Issue: App crashes on MQTT message
**Solution**: Check data parsing logic handles missing fields gracefully

---

## Next Steps

1. **Rebuild the app** with the updated code
2. **Run the simulator** to send test data
3. **Monitor the app** to see real-time data
4. **Test notifications** with magnitude >= 3.0 events

---

## Real Device Integration

When connecting real earthquake sensors:

1. Ensure devices publish to: `eqnode.tarita/hub/eqdata`
2. Use this JSON format:
```json
{
  "deviceId": "EQC-001",
  "timestamp": "2025-11-20T16:46:29.612Z",
  "magnitude": 4.5,
  "latitude": 13.7563,
  "longitude": 100.5018,
  "depth": 25,
  "location": "Bangkok",
  "intensity": "medium"
}
```

3. The app will automatically:
   - Display data in real-time
   - Send notifications for magnitude >= 3.0
   - Store events in local database
   - Show on map (if coordinates provided)

---

## Support

If issues persist:
1. Check `flutter logs` for error messages
2. Verify MQTT broker is accessible from your network
3. Test with `backend/test-mqtt-connection.js` first
4. Ensure Flutter app has internet permissions (already configured)
