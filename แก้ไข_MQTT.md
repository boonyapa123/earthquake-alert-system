# 🔧 แก้ไขปัญหา MQTT ไม่แสดงข้อมูล

## ปัญหา
- แอพแสดง "MQTT Status: CONNECTED" ✅
- แต่ไม่มีข้อมูล MQTT แสดง ❌
- ข้อความ "ไม่มีข้อมูล MQTT" และ "รอข้อมูลจาก MQTT Broker..."

## สาเหตุ
**Topic ไม่ตรงกัน!**

- แอพ subscribe: `earthquake/data` ❌
- Broker ส่งข้อมูลไปที่: `eqnode.tarita/hub/eqdata` ✅
- ผลลัพธ์: ไม่ตรงกัน = ไม่ได้รับข้อมูล

---

## วิธีแก้ไข

### ✅ ขั้นตอนที่ 1: Build แอพใหม่
```bash
flutter clean
flutter pub get
flutter run
```

**เท่านี้ก็เสร็จแล้ว!** โค้ดแก้ไขเรียบร้อยแล้ว

---

## 🧪 ทดสอบ (ถ้าต้องการ)

### ส่งข้อมูลทดสอบ:
```bash
cd backend
node simulate-earthquake.js
```

จะส่งข้อมูลแผ่นดินไหว 10 ครั้ง ไปที่ MQTT Broker

---

## 📱 ผลลัพธ์ที่คาดหวัง

หลัง build ใหม่ แอพจะแสดง:

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
🌍 EQC-SIM-002
   Magnitude: 3.2 Richter
   Location: Chiang Mai
   Time: 16:46:32
━━━━━━━━━━━━━━━━━━━━
[ข้อมูลเพิ่มเติม...]
```

---

## 🔍 สิ่งที่แก้ไข

### 1. ไฟล์ `lib/services/mqtt_manager.dart`
เปลี่ยน Topic ที่ subscribe:

**ก่อน:**
```dart
final String _dataTopic = 'earthquake/data';
final String _alertTopic = 'earthquake/alert';
```

**หลัง:**
```dart
final String _dataTopic = 'eqnode.tarita/hub/#';
final String _alertTopic = 'eqnode.tarita/hub/alert';
final String _legacyDataTopic = 'earthquake/data';
```

### 2. ไฟล์ `backend/simulate-earthquake.js`
เปลี่ยน Topic ที่ publish:

**ก่อน:**
```javascript
const MQTT_TOPIC = 'earthquake/data';
```

**หลัง:**
```javascript
const MQTT_TOPIC = 'eqnode.tarita/hub/eqdata';
```

---

## 🛠️ เครื่องมือทดสอบใหม่

### 1. ฟังข้อมูล MQTT
```bash
cd backend
node test-mqtt-connection.js
```

### 2. ส่งข้อมูลทดสอบ
```bash
cd backend
node simulate-earthquake.js
```

### 3. เมนูทดสอบง่ายๆ
```bash
./test_mqtt.sh
```

---

## 📊 โครงสร้าง Topic

```
mqtt.uiot.cloud:1883
│
├── eqnode.tarita/hub/
│   ├── eqdata          ← ข้อมูลแผ่นดินไหวหลัก
│   ├── alert           ← ข้อความแจ้งเตือน
│   └── status          ← สถานะ
│
├── pmac/#              ← อุปกรณ์ PMAC
├── TPO/#               ← อุปกรณ์ TPO
└── earthquake/#        ← Topic เก่า (รองรับย้อนหลัง)
```

---

## ✅ การตรวจสอบ

หลัง build แอพใหม่:

1. ✅ เปิดแอพ → ไปที่แท็บ "MQTT Real-time"
2. ✅ ต้องแสดง "CONNECTED"
3. ✅ รัน: `cd backend && node simulate-earthquake.js`
4. ✅ แอพต้องแสดงข้อมูลแผ่นดินไหว
5. ✅ ตัวเลข "Total messages" ต้องเพิ่มขึ้น
6. ✅ การแจ้งเตือนต้องทำงาน (magnitude >= 3.0)

---

## 🆘 ถ้ายังไม่ทำงาน

1. ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
2. ตรวจสอบว่าเข้าถึง `mqtt.uiot.cloud:1883` ได้
3. ดู Flutter logs: `flutter logs`
4. ทดสอบ MQTT แยก: `cd backend && node test-mqtt-connection.js`

---

## 📝 ข้อมูล MQTT Broker

```
Hostname: mqtt.uiot.cloud
Port: 1883
Username: ethernet
Password: ei8jZz87wx
```

---

## 📚 เอกสารเพิ่มเติม

- `QUICK_FIX.md` - คู่มือแก้ไขด่วน (ภาษาอังกฤษ)
- `MQTT_FIX_SUMMARY.md` - สรุปการแก้ไขแบบละเอียด
- `MQTT_TROUBLESHOOTING.md` - คู่มือแก้ปัญหา
- `MQTT_FLOW_DIAGRAM.md` - แผนภาพการทำงาน

---

## 🎯 สรุป

**ปัญหา**: Topic ไม่ตรงกัน  
**วิธีแก้**: อัพเดท Topic ให้ตรงกัน  
**ผลลัพธ์**: ข้อมูลไหลจาก Broker → แอพ → ผู้ใช้  

✅ **สถานะ**: แก้ไขเรียบร้อย - พร้อมใช้งาน!

---

## ⏱️ เวลาที่ใช้

- Build แอพใหม่: ~2 นาที
- ทดสอบ: ~1 นาที
- **รวม: ~3 นาที**

---

**หมายเหตุ**: แค่ build แอพใหม่ก็เสร็จแล้ว! โค้ดแก้ไขหมดแล้ว ✅
