# 🚀 Quick Fix - MQTT Data Not Showing

## The Problem
✅ MQTT Status: CONNECTED  
❌ ไม่มีข้อมูล MQTT (No data showing)

## The Solution
**Topic mismatch fixed!** App now subscribes to correct MQTT topics.

---

## 🔧 What You Need to Do

### 1. Rebuild Your Flutter App
```bash
flutter clean
flutter pub get
flutter run
```

**That's it!** The code is already fixed.

---

## 🧪 Test It (Optional)

### Send test earthquake data:
```bash
cd backend
node simulate-earthquake.js
```

You should see 10 earthquake events appear in your app!

---

## ✅ What Changed

### Before:
- App listened to: `earthquake/data` ❌
- Broker publishes to: `eqnode.tarita/hub/eqdata` ✅
- **Result**: No match = No data

### After:
- App now listens to: `eqnode.tarita/hub/#` ✅
- Broker publishes to: `eqnode.tarita/hub/eqdata` ✅
- **Result**: Match = Data flows! 🎉

---

## 📱 Expected Result

After rebuild, your app will show:

```
✅ MQTT Status: CONNECTED
   Total messages: 10

Real-time MQTT Data
━━━━━━━━━━━━━━━━━━━━
🌍 EQC-SIM-001
   Magnitude: 4.5 Richter
   Location: Bangkok
   Time: 16:46:29
━━━━━━━━━━━━━━━━━━━━
[More events...]
```

---

## 🎯 Quick Test Commands

```bash
# Test 1: Listen for MQTT messages
cd backend && node test-mqtt-connection.js

# Test 2: Send earthquake data
cd backend && node simulate-earthquake.js

# Test 3: Easy menu
./test_mqtt.sh
```

---

## 📋 Files Modified

- ✅ `lib/services/mqtt_manager.dart` - Fixed MQTT topics
- ✅ `backend/simulate-earthquake.js` - Fixed publish topic

---

## 🆘 Still Not Working?

1. Check internet connection
2. Verify MQTT broker is accessible: `mqtt.uiot.cloud:1883`
3. Check Flutter logs: `flutter logs`
4. Test MQTT separately: `cd backend && node test-mqtt-connection.js`

---

**Status**: ✅ FIXED - Just rebuild the app!

**Time to fix**: ~2 minutes (flutter clean + run)
