# MQTT Data Flow Diagram

## Before Fix (Not Working) ❌

```
┌─────────────────────┐
│  Real MQTT Broker   │
│  mqtt.uiot.cloud    │
└──────────┬──────────┘
           │
           │ Publishes to:
           │ "eqnode.tarita/hub/eqdata"
           │
           ▼
    ╔═════════════╗
    ║   BROKER    ║
    ╚═════════════╝
           │
           │ No match!
           │
           ▼
    ┌─────────────┐
    │ Flutter App │
    │ Subscribes: │
    │ "earthquake/│  ← Wrong topic!
    │    data"    │
    └─────────────┘
           │
           ▼
    ❌ No data received
```

---

## After Fix (Working) ✅

```
┌─────────────────────┐
│  Real MQTT Broker   │
│  mqtt.uiot.cloud    │
└──────────┬──────────┘
           │
           │ Publishes to:
           │ "eqnode.tarita/hub/eqdata"
           │
           ▼
    ╔═════════════╗
    ║   BROKER    ║
    ╚═════════════╝
           │
           │ ✅ Match!
           │
           ▼
    ┌─────────────┐
    │ Flutter App │
    │ Subscribes: │
    │ "eqnode.    │  ← Correct topic!
    │  tarita/    │
    │  hub/#"     │
    └─────────────┘
           │
           ▼
    ✅ Data received!
    ✅ Displayed in UI
    ✅ Notifications sent
```

---

## Complete System Flow

```
┌──────────────────────────────────────────────────────────────┐
│                     MQTT ECOSYSTEM                            │
└──────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐
│ Earthquake      │         │  Test Simulator │
│ Sensors (Real)  │         │  (Development)  │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │ Publish                   │ Publish
         │                           │
         ▼                           ▼
    ╔════════════════════════════════════╗
    ║      MQTT Broker                   ║
    ║      mqtt.uiot.cloud:1883          ║
    ║                                    ║
    ║  Topics:                           ║
    ║  • eqnode.tarita/hub/eqdata       ║
    ║  • eqnode.tarita/hub/alert        ║
    ║  • pmac/#                          ║
    ║  • TPO/#                           ║
    ╚════════════════════════════════════╝
         │                           │
         │ Subscribe                 │ Subscribe
         │                           │
         ▼                           ▼
┌─────────────────┐         ┌─────────────────┐
│  Flutter App    │         │  Backend Server │
│  (Mobile)       │         │  (Node.js)      │
│                 │         │                 │
│  • Display data │         │  • Process data │
│  • Send alerts  │         │  • Store in DB  │
│  • Show on map  │         │  • Analytics    │
└─────────────────┘         └─────────────────┘
```

---

## Topic Structure

```
mqtt.uiot.cloud:1883
│
├── eqnode.tarita/
│   └── hub/
│       ├── eqdata          ← Main earthquake data
│       ├── alert           ← Alert messages
│       ├── status          ← Status updates
│       └── ...             ← Other subtopics
│
├── pmac/
│   └── [device_id]/
│       └── data            ← PMAC device data
│
├── TPO/
│   └── [device_id]/
│       └── data            ← TPO device data
│
└── earthquake/             ← Legacy topics
    ├── data                ← (backward compatibility)
    ├── alert
    └── status
```

---

## Data Flow Example

### 1. Sensor Detects Earthquake
```json
{
  "deviceId": "EQC-001",
  "magnitude": 4.5,
  "location": "Bangkok",
  "timestamp": "2025-11-20T16:46:29.612Z"
}
```

### 2. Published to MQTT
```
Topic: eqnode.tarita/hub/eqdata
Payload: [JSON above]
```

### 3. Flutter App Receives
```dart
// App is subscribed to: eqnode.tarita/hub/#
// Receives message → Parses JSON → Updates UI
```

### 4. User Sees
```
📱 App Screen:
━━━━━━━━━━━━━━━━━━━━
🌍 EQC-001
   Magnitude: 4.5 Richter
   Location: Bangkok
   Time: 16:46:29
━━━━━━━━━━━━━━━━━━━━

🔔 Notification:
   "Earthquake Alert!"
   "Magnitude 4.5 detected"
```

---

## Subscription Patterns

### Wildcard `#` (Multi-level)
```
eqnode.tarita/hub/#
├── Matches: eqnode.tarita/hub/eqdata
├── Matches: eqnode.tarita/hub/alert
├── Matches: eqnode.tarita/hub/status
└── Matches: eqnode.tarita/hub/device/001/data
```

### Wildcard `+` (Single-level)
```
device/+/status
├── Matches: device/001/status
├── Matches: device/002/status
└── NOT: device/001/sensor/status
```

---

## Testing Flow

```
┌──────────────┐
│ Run Simulator│
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ Publish 10 events    │
│ to MQTT broker       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Broker distributes   │
│ to all subscribers   │
└──────┬───────────────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│ Flutter App │   │ Test Listener│
│ Shows data  │   │ Logs messages│
└─────────────┘   └─────────────┘
```

---

## Summary

**Problem**: Topic mismatch  
**Solution**: Updated app to subscribe to correct topics  
**Result**: Data flows from broker → app → user  

✅ **Status**: Fixed and ready to use!
