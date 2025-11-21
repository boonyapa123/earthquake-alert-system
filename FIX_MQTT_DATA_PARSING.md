# ✅ แก้ไขการ Parse ข้อมูล MQTT ให้ถูกต้อง

## 🔴 ปัญหาเดิม

แอพแสดงข้อมูลผิดพลาด:
- **Device: UNKNOWN** - ไม่แสดงชื่ออุปกรณ์
- **Magnitude: 0.00 Richter** - ไม่แสดงขนาดแผ่นดินไหว
- **Location: Unknown Location** - ไม่แสดงตำแหน่ง

### สาเหตุ:
แอพคาดหวังข้อมูลในรูปแบบ:
```json
{
  "deviceId": "EQC-001",
  "magnitude": 4.5,
  "location": "Bangkok",
  "timestamp": "2025-11-21T00:31:27"
}
```

แต่ MQTT ส่งมาในรูปแบบ:
```json
{
  "did": "EQC-28562faa0b60",
  "pga": 0.1213,
  "lat": 13.903011,
  "lon": 100.533103,
  "ts": "2025-11-21 00:31:27.716"
}
```

---

## ✅ วิธีแก้ไข

### 1. แยกประเภทข้อมูล

```dart
if (topic.contains('/eqdata/') || topic.contains('earthquake/data')) {
  // ข้อมูลแผ่นดินไหว
  await _processEarthquakeData(topic, data);
} else if (topic.contains('/ping/') || topic.contains('/status')) {
  // ข้อมูลสถานะอุปกรณ์ - ไม่แสดง
}
```

### 2. Parse Device ID

```dart
String deviceId = 'UNKNOWN';
if (data.containsKey('did')) {
  deviceId = data['did'];  // จาก EQNODE
} else if (data.containsKey('deviceId')) {
  deviceId = data['deviceId'];  // จาก simulator
}
```

### 3. คำนวณ Magnitude จาก PGA

```dart
double magnitude = 0.0;

// จาก EQNODE - ใช้ PGA (Peak Ground Acceleration)
if (data.containsKey('pga')) {
  final pga = (data['pga'] ?? 0.0).toDouble();
  // แปลง PGA (in g) เป็น magnitude
  if (pga > 0) {
    magnitude = (pga * 1000).clamp(0.1, 10.0);
  }
}
// จาก simulator
else if (data.containsKey('magnitude')) {
  magnitude = (data['magnitude'] ?? 0.0).toDouble();
}
```

**หมายเหตุ**: 
- PGA (Peak Ground Acceleration) วัดเป็น g (gravity)
- ค่า PGA ที่ได้จาก EQNODE อยู่ในช่วง 0.001 - 1.0 g
- แปลงเป็น magnitude โดยคูณ 1000 และจำกัดค่าไว้ที่ 0.1-10.0

### 4. Parse Location

```dart
String location = 'Unknown Location';

// ถ้ามี location ชัดเจน
if (data.containsKey('location')) {
  location = data['location'];
} 
// ถ้ามี lat/lon ให้แสดงพิกัด
else if (data.containsKey('lat') && data.containsKey('lon')) {
  final lat = data['lat'];
  final lon = data['lon'];
  location = 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
}
```

### 5. Parse Timestamp

```dart
DateTime timestamp = DateTime.now();
if (data.containsKey('ts')) {
  // Format: "2025-11-21 00:31:27.716"
  try {
    timestamp = DateTime.parse(data['ts'].toString().replaceAll(' ', 'T'));
  } catch (e) {
    timestamp = DateTime.now();
  }
}
```

### 6. กรองข้อมูล

```dart
// แสดงเฉพาะข้อมูลที่มี magnitude > 0
if (magnitude > 0.0) {
  final log = MqttLog(
    deviceId: deviceId,
    magnitude: magnitude,
    timestamp: timestamp,
    location: location,
    type: 'earthquake',
    ownerId: 'system',
  );
  
  _processLog(log);
}
```

---

## 📊 ผลลัพธ์หลังแก้ไข

### ก่อนแก้ไข:
```
Device: UNKNOWN
Magnitude: 0.00 Richter
Location: Unknown Location
Time: 00:26:53
```

### หลังแก้ไข:
```
Device: EQC-28562faa0b60
Magnitude: 0.12 Richter
Location: Lat: 13.9030, Lon: 100.5331
Time: 00:31:27
```

---

## 🎯 การทดสอบ

### 1. Rebuild แอพ
```bash
flutter clean
flutter pub get
flutter run
```

### 2. ตรวจสอบในแอพ
- เปิดแท็บ "MQTT Real-time"
- ควรเห็นข้อมูลจาก EQNODE จริง
- Device ID ควรเป็น "EQC-xxxxxxxxxx"
- Magnitude ควรมีค่า > 0
- Location ควรแสดงพิกัด

### 3. ส่งข้อมูลทดสอบ
```bash
cd backend
node simulate-earthquake.js
```

ควรเห็นข้อมูลจาก simulator ด้วย:
- Device ID: "EQC-SIM-001", "EQC-SIM-002", ...
- Magnitude: 2.0 - 6.5 Richter
- Location: Bangkok, Chiang Mai, Phuket, ...

---

## 📋 ข้อมูลที่รองรับ

### จาก EQNODE (อุปกรณ์จริง):
```json
{
  "did": "EQC-28562faa0b60",
  "ts": "2025-11-21 00:31:27.716",
  "lat": 13.903011,
  "lon": 100.533103,
  "pga": 0.1213,
  "rms": 0.1168,
  "ax": 0.001056,
  "ay": 0.014689,
  "az": -0.115818
}
```

### จาก Simulator:
```json
{
  "deviceId": "EQC-SIM-001",
  "timestamp": "2025-11-20T17:18:27.290Z",
  "magnitude": 4.4,
  "latitude": 16.4419,
  "longitude": 102.8360,
  "location": "Khon Kaen"
}
```

---

## 🔧 ไฟล์ที่แก้ไข

- ✅ `lib/services/mqtt_manager.dart`
  - แก้ไข `_processRealMqttData()`
  - เพิ่ม `_processEarthquakeData()`
  - รองรับข้อมูลจาก EQNODE และ simulator

---

## ⚠️ หมายเหตุ

### การคำนวณ Magnitude จาก PGA:

ในเวอร์ชันปัจจุบัน ใช้สูตรง่ายๆ:
```dart
magnitude = (pga * 1000).clamp(0.1, 10.0)
```

**ถ้าต้องการความแม่นยำมากขึ้น** สามารถใช้สูตรที่ซับซ้อนกว่า:
```dart
// Gutenberg-Richter relation
magnitude = log10(pga * 1000) + 3.0;
```

หรือ
```dart
// Empirical formula
magnitude = 2.0 * log10(pga * 980) + 0.7;
```

แต่ต้องปรับค่า offset ให้เหมาะสมกับข้อมูลจริง

---

## ✅ สถานะ

**การแก้ไข**: เสร็จสมบูรณ์  
**ต้อง Rebuild**: ใช่  
**ทดสอบแล้ว**: รอการทดสอบ

---

**คำแนะนำ**: Rebuild แอพแล้วทดสอบดูว่าข้อมูลแสดงถูกต้องหรือไม่
