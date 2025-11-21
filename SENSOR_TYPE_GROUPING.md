# 🎯 การแยกกลุ่มตามประเภทเซ็นเซอร์

## ✨ การปรับปรุงใหม่

### ก่อนปรับปรุง:
- แยกเฉพาะตามความรุนแรง (Critical, High, Normal)
- ไม่แยกตามประเภทเซ็นเซอร์

### หลังปรับปรุง:
- ✅ **แยกตามประเภทเซ็นเซอร์** (3 ประเภท)
- ✅ **แยกตามความรุนแรงภายในแต่ละประเภท**
- ✅ **ใช้สีและไอคอนเฉพาะแต่ละประเภท**
- ✅ **แสดงหน่วยที่เหมาะสมกับแต่ละประเภท**

---

## 📊 ประเภทเซ็นเซอร์ทั้งหมด

### 1. 🌍 เซ็นเซอร์แผ่นดินไหว (Earthquake)

**Device ID Pattern**:
- `EQC-*` - EQNODE
- `PMAC-*` - PMAC

**สี**: แดง (Red.shade700)  
**ไอคอน**: 📊 show_chart  
**หน่วย**: Richter  
**ฟิลด์ข้อมูล**: `pga`, `magnitude`

**ตัวอย่าง**:
```
🌍 เซ็นเซอร์แผ่นดินไหว [10 รายการ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 รุนแรงมาก (2)
  [Card: 6.4 Richter]
  [Card: 6.2 Richter]

⚠️ รุนแรง (5)
  [Card: 5.3 Richter]
  [Card: 4.5 Richter]
  ...

🟢 ปกติ (3)
  [Card: 2.8 Richter]
  ...
```

---

### 2. 🌊 เซ็นเซอร์คลื่นซึนามิ (Tsunami)

**Device ID Pattern**:
- `TSU-*` - Tsunami Sensor
- `TSUNAMI-*`

**สี**: น้ำเงิน (Blue.shade700)  
**ไอคอน**: 🌊 waves  
**หน่วย**: เมตร (m)  
**ฟิลด์ข้อมูล**: `wave_height`, `magnitude`

**ตัวอย่าง**:
```
🌊 เซ็นเซอร์คลื่นซึนามิ [5 รายการ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 รุนแรงมาก (1)
  [Card: 8.50 เมตร]

⚠️ รุนแรง (2)
  [Card: 4.20 เมตร]
  [Card: 3.80 เมตร]

🟢 ปกติ (2)
  [Card: 1.50 เมตร]
  [Card: 0.80 เมตร]
```

---

### 3. 📐 เซ็นเซอร์วัดความเอียง (Tilt)

**Device ID Pattern**:
- `TILT-*` - Tilt Sensor
- `INCLINE-*` - Inclinometer

**สี**: ม่วง (Purple.shade700)  
**ไอคอน**: 📐 architecture  
**หน่วย**: องศา (°)  
**ฟิลด์ข้อมูล**: `angle`, `magnitude`

**ตัวอย่าง**:
```
📐 เซ็นเซอร์วัดความเอียง [3 รายการ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 รุนแรงมาก (1)
  [Card: 7.50 องศา]

⚠️ รุนแรง (1)
  [Card: 4.20 องศา]

🟢 ปกติ (1)
  [Card: 1.80 องศา]
```

---

## 🔍 การตรวจจับประเภทเซ็นเซอร์

### จาก Device ID:
```dart
if (deviceId.contains('EQC-') || deviceId.contains('PMAC-')) {
  sensorType = 'earthquake';
} else if (deviceId.contains('TSU-') || deviceId.contains('TSUNAMI')) {
  sensorType = 'tsunami';
} else if (deviceId.contains('TILT-') || deviceId.contains('INCLINE')) {
  sensorType = 'tilt';
}
```

### จาก Topic:
```dart
if (topic.contains('tsunami')) {
  sensorType = 'tsunami';
} else if (topic.contains('tilt') || topic.contains('incline')) {
  sensorType = 'tilt';
}
```

### จาก Data Field:
```dart
if (data.containsKey('type')) {
  final dataType = data['type'].toString().toLowerCase();
  if (dataType.contains('tsunami')) {
    sensorType = 'tsunami';
  } else if (dataType.contains('tilt')) {
    sensorType = 'tilt';
  }
}
```

---

## 📱 โครงสร้าง UI

### Level 1: ประเภทเซ็นเซอร์
```
┌─────────────────────────────────────┐
│ [Icon] 🌍 เซ็นเซอร์แผ่นดินไหว      │
│                        [10 รายการ]  │
└─────────────────────────────────────┘
```

### Level 2: ความรุนแรง
```
  🚨 รุนแรงมาก (2)
  ⚠️ รุนแรง (5)
  🟢 ปกติ (3)
```

### Level 3: รายการข้อมูล
```
┌─────────────────────────────────────┐
│ ⚠️  [EQNODE] EQC-001      [CRITICAL]│
│     17:43:28                         │
│                                      │
│ 🎯 Magnitude: 6.40 Richter          │
│ 📍 Bangkok                           │
└─────────────────────────────────────┘
```

---

## 🎨 สีและไอคอนสำหรับแต่ละประเภท

| ประเภท | สี | ไอคอน | Badge Color |
|--------|-----|--------|-------------|
| **Earthquake** | 🔴 Red | 📊 show_chart | Red.shade100 |
| **Tsunami** | 🔵 Blue | 🌊 waves | Blue.shade100 |
| **Tilt** | 🟣 Purple | 📐 architecture | Purple.shade100 |

---

## 📊 การแสดงข้อมูลตามประเภท

### Earthquake (แผ่นดินไหว):
```
🎯 Magnitude: 6.40 Richter
📍 Location: Bangkok
```

### Tsunami (คลื่นซึนามิ):
```
🌊 ความสูงคลื่น: 4.20 เมตร
📍 Location: Phuket Coast
```

### Tilt (ความเอียง):
```
📐 มุมเอียง: 3.50 องศา
📍 Location: Building A
```

---

## 🔧 การทำงาน

### 1. รับข้อมูล MQTT
```dart
Future<void> _processEarthquakeData(String topic, Map<String, dynamic> data) async {
  // ตรวจจับประเภทเซ็นเซอร์
  String sensorType = 'earthquake';
  
  if (deviceId.contains('TSU-')) {
    sensorType = 'tsunami';
  } else if (deviceId.contains('TILT-')) {
    sensorType = 'tilt';
  }
  
  // สร้าง log พร้อม sensorType
  final log = MqttLog(
    deviceId: deviceId,
    magnitude: magnitude,
    sensorType: sensorType,
    ...
  );
}
```

### 2. จัดกลุ่มตามประเภท
```dart
final earthquakeLogs = logs.where((log) => log.sensorType == 'earthquake').toList();
final tsunamiLogs = logs.where((log) => log.sensorType == 'tsunami').toList();
final tiltLogs = logs.where((log) => log.sensorType == 'tilt').toList();
```

### 3. แสดงผลแยกกลุ่ม
```dart
Column(
  children: [
    if (earthquakeLogs.isNotEmpty) ...[
      _buildSensorTypeHeader('🌍 เซ็นเซอร์แผ่นดินไหว', ...),
      ..._buildGroupedLogs(earthquakeLogs, 'earthquake'),
    ],
    if (tsunamiLogs.isNotEmpty) ...[
      _buildSensorTypeHeader('🌊 เซ็นเซอร์คลื่นซึนามิ', ...),
      ..._buildGroupedLogs(tsunamiLogs, 'tsunami'),
    ],
    if (tiltLogs.isNotEmpty) ...[
      _buildSensorTypeHeader('📐 เซ็นเซอร์วัดความเอียง', ...),
      ..._buildGroupedLogs(tiltLogs, 'tilt'),
    ],
  ],
)
```

---

## 🧪 การทดสอบ

### 1. ทดสอบ Earthquake
```bash
# ส่งข้อมูลแผ่นดินไหว
cd backend
node simulate-earthquake.js
```

### 2. ทดสอบ Tsunami (ต้องสร้าง simulator)
```javascript
// simulate-tsunami.js
const data = {
  deviceId: 'TSU-001',
  wave_height: 4.5,
  location: 'Phuket Coast',
  timestamp: new Date().toISOString()
};
```

### 3. ทดสอบ Tilt (ต้องสร้าง simulator)
```javascript
// simulate-tilt.js
const data = {
  deviceId: 'TILT-001',
  angle: 3.2,
  location: 'Building A',
  timestamp: new Date().toISOString()
};
```

---

## 📋 ไฟล์ที่แก้ไข

### 1. `lib/services/mqtt_manager.dart`
- ✅ เพิ่ม field `sensorType` ใน `MqttLog`
- ✅ เพิ่มการตรวจจับประเภทเซ็นเซอร์
- ✅ รองรับ field ต่างๆ (`pga`, `wave_height`, `angle`)

### 2. `lib/screens/home_screen.dart`
- ✅ แก้ไข `_buildMqttDevicesList()` - จัดกลุ่มตามประเภทเซ็นเซอร์
- ✅ เพิ่ม `_buildSensorTypeHeader()` - Header แต่ละประเภท
- ✅ เพิ่ม `_buildSeveritySubHeader()` - Sub-header ความรุนแรง
- ✅ เพิ่ม `_buildGroupedLogs()` - จัดกลุ่มตามความรุนแรง
- ✅ แก้ไข `_buildMqttLogCard()` - แสดงหน่วยตามประเภท

---

## ✅ สรุป

### ก่อน:
- แยกเฉพาะตามความรุนแรง
- ไม่แยกประเภทเซ็นเซอร์

### หลัง:
- ✅ แยก 3 ประเภทเซ็นเซอร์ (Earthquake, Tsunami, Tilt)
- ✅ แยกความรุนแรงภายในแต่ละประเภท
- ✅ ใช้สีและไอคอนเฉพาะ
- ✅ แสดงหน่วยที่เหมาะสม (Richter, เมตร, องศา)
- ✅ Badge สีต่างกันตามประเภท
- ✅ Header สวยงามแยกชัดเจน

---

**สถานะ**: ✅ เสร็จสมบูรณ์ - Rebuild แอพเพื่อดูผลลัพธ์

**คำแนะนำ**: 
- Rebuild แอพ: `flutter clean && flutter pub get && flutter run`
- ทดสอบด้วย simulator: `cd backend && node simulate-earthquake.js`
- ข้อมูลจาก EQNODE จริงจะแสดงในหมวด "เซ็นเซอร์แผ่นดินไหว"
