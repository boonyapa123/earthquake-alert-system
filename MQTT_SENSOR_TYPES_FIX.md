# แก้ไขการแสดงเซ็นเซอร์ทั้ง 3 ประเภทจาก MQTT

## ปัญหา
- แอปแสดงเฉพาะเซ็นเซอร์แผ่นดินไหว
- ไม่แสดงเซ็นเซอร์สึนามิและความเอียง
- ต้องการใช้ข้อมูลจาก MQTT จริง

## ข้อมูล MQTT ที่มีอยู่

จากการตรวจสอบ MQTT Broker พบว่ามีข้อมูล 3 ประเภท:

### 1. แผ่นดินไหว (Earthquake)
**Topic**: `eqnode.tarita/hub/1/eqdata`
- มี 2 topics, 110 messages
- ข้อมูล: `deviceId`, `magnitude`, `latitude`, `longitude`, `timestamp`

### 2. คลื่นซึนามิ (Tsunami)  
**Topic**: `eqnode.tarita/hub/1/tsunami`
- มี 1 topic, 6 messages
- ข้อมูล: `deviceId`, `wave_height` หรือ `magnitude`, `location`, `timestamp`

### 3. ความเอียง (Tilt)
**Topic**: `eqnode.tarita/hub/1/tilt`
- มี 1 topic, 5 messages
- ข้อมูล: `deviceId`, `angle` หรือ `magnitude`, `location`, `timestamp`

## การแก้ไข

### 1. แก้ไข `lib/services/mqtt_manager.dart`

เพิ่มฟังก์ชันประมวลผลข้อมูลแยกตามประเภท:

```dart
// Process Tsunami Data
Future<void> _processTsunamiData(String topic, Map<String, dynamic> data) async {
  // ดึง deviceId, wave_height, location, timestamp
  // สร้าง MqttLog ด้วย sensorType: 'tsunami'
}

// Process Tilt Data  
Future<void> _processTiltData(String topic, Map<String, dynamic> data) async {
  // ดึง deviceId, angle, location, timestamp
  // สร้าง MqttLog ด้วย sensorType: 'tilt'
}
```

### 2. อัปเดต `_processRealMqttData()`

แยก routing ตาม topic:
```dart
if (topic.contains('/eqdata')) {
  await _processEarthquakeData(topic, data);
}
else if (topic.contains('/tsunami')) {
  await _processTsunamiData(topic, data);
}
else if (topic.contains('/tilt')) {
  await _processTiltData(topic, data);
}
```

### 3. UI แสดงผลแยกตามประเภท

ใน `lib/screens/home_screen.dart` มีการจัดกลุ่มข้อมูลแล้ว:
```dart
final earthquakeLogs = logs.where((log) => log.sensorType == 'earthquake').toList();
final tsunamiLogs = logs.where((log) => log.sensorType == 'tsunami').toList();
final tiltLogs = logs.where((log) => log.sensorType == 'tilt').toList();
```

แสดงเป็นการ์ดแยกกัน:
- 🌍 เซ็นเซอร์แผ่นดินไหว (สีแดง)
- 🌊 เซ็นเซอร์คลื่นซึนามิ (สีน้ำเงิน)
- 📐 เซ็นเซอร์วัดความเอียง (สีม่วง)

## การทดสอบ

### 1. ตรวจสอบ MQTT Topics
```bash
cd backend
node mqtt-data-inspector.js
```

ควรเห็น:
- `eqnode.tarita/hub/1/eqdata` - ข้อมูลแผ่นดินไหว
- `eqnode.tarita/hub/1/tsunami` - ข้อมูลคลื่นซึนามิ
- `eqnode.tarita/hub/1/tilt` - ข้อมูลความเอียง

### 2. บิ้ว APK
```bash
flutter build apk --release
```

### 3. ติดตั้งและทดสอบ
1. ติดตั้ง APK บนมือถือ
2. เปิดแอป และไปที่แท็บ "MQTT Real-time"
3. ควรเห็นการ์ดทั้ง 3 ประเภท:
   - เซ็นเซอร์แผ่นดินไหว
   - เซ็นเซอร์คลื่นซึนามิ
   - เซ็นเซอร์วัดความเอียง
4. กดเข้าไปในแต่ละการ์ดเพื่อดูรายละเอียด

## โครงสร้างข้อมูล

### MqttLog Model
```dart
class MqttLog {
  final String deviceId;
  final double magnitude;      // Richter / เมตร / องศา
  final DateTime timestamp;
  final String location;
  final String type;
  final String ownerId;
  final String sensorType;     // 'earthquake', 'tsunami', 'tilt'
}
```

### Sensor Type Mapping
| sensorType | หน่วย | Threshold | Icon |
|-----------|------|-----------|------|
| earthquake | Richter | >= 4.0 | 🌍 |
| tsunami | เมตร | >= 0.5 | 🌊 |
| tilt | องศา | >= 0.5 | 📐 |

## ผลลัพธ์

✅ แอปแสดงเซ็นเซอร์ทั้ง 3 ประเภทแยกกัน
✅ ใช้ข้อมูลจาก MQTT จริง 100%
✅ แสดงรายละเอียดเมื่อกดเข้าไปในการ์ด
✅ มีการแจ้งเตือนตาม threshold ของแต่ละประเภท

## APK Location
```
build/app/outputs/flutter-apk/app-release.apk (66.6MB)
```
