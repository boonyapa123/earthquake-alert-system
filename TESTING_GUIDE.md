# 🧪 คู่มือการทดสอบระบบจริง (Real System Testing)

## 📋 ภาพรวม

คู่มือนี้จะแนะนำวิธีการเชื่อมต่อและทดสอบระบบจริงทั้งหมด:
- ✅ Backend API (Node.js + PostgreSQL)
- ✅ MQTT Cloud (mqtt.uiot.cloud)
- ✅ Flutter App (iOS/Android)

---

## 🎯 สถานะการตั้งค่า

### ✅ ตั้งค่าแล้ว

```dart
// lib/config/app_config.dart
static bool get enableMockData {
  case Environment.development:
    return false; // ✅ ปิด Mock Data แล้ว
}
```

### 📡 ข้อมูลการเชื่อมต่อ

#### Backend API
- **URL**: `http://10.134.94.222:3000/api/v1`
- **Port**: 3000
- **Database**: PostgreSQL

#### MQTT Cloud
- **Host**: `mqtt.uiot.cloud`
- **Port**: 1883 (TCP) / 8083 (WebSocket)
- **Username**: `ethernet`
- **Password**: `ei8jZz87wx`
- **Topics**:
  - Subscribe: `eqnode.tarita/hub/#`
  - Publish: `eqnode.tarita/hub/data`

---

## 🚀 ขั้นตอนการเตรียมระบบ

### ขั้นตอนที่ 1: เริ่ม Backend Server

```bash
cd backend

# ติดตั้ง dependencies (ครั้งแรกเท่านั้น)
npm install

# เริ่ม PostgreSQL (ถ้าใช้ Docker)
docker-compose up -d postgres

# รอ PostgreSQL พร้อม (ประมาณ 10 วินาที)
sleep 10

# สร้าง Database และ Tables
npm run db:setup

# เริ่ม Backend Server
npm run dev
```

**ตรวจสอบว่า Backend ทำงาน:**
```bash
curl http://10.134.94.222:3000/api/v1/health
# ควรได้: {"status":"ok","timestamp":"..."}
```

### ขั้นตอนที่ 2: ตรวจสอบ MQTT Connection

```bash
# ติดตั้ง MQTT Client (ถ้ายังไม่มี)
brew install mosquitto  # macOS
# หรือ
sudo apt-get install mosquitto-clients  # Linux

# ทดสอบ Subscribe
mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/#" -v

# ทดสอบ Publish (เปิด terminal ใหม่)
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/data" \
  -m '{"deviceId":"TEST-001","magnitude":3.5,"location":"Bangkok","timestamp":"2025-01-20T10:00:00Z"}'
```

### ขั้นตอนที่ 3: เริ่ม Flutter App

```bash
# ดูรายการ devices
flutter devices

# รันบน iOS Simulator
flutter run -d "iPhone 15 Pro"

# หรือรันบน Android Emulator
flutter run

# หรือรันบน Chrome (สำหรับ debug UI)
flutter run -d chrome
```

---

## 🧪 การทดสอบแต่ละส่วน

### 1. ทดสอบ Backend API

#### 1.1 Health Check
```bash
curl http://10.134.94.222:3000/api/v1/health
```

#### 1.2 Register User
```bash
curl -X POST http://10.134.94.222:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "phone": "0812345678"
  }'
```

#### 1.3 Login
```bash
curl -X POST http://10.134.94.222:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**บันทึก token ที่ได้:**
```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### 1.4 Register Device
```bash
curl -X POST http://10.134.94.222:3000/api/v1/devices/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "deviceId": "EQC-TEST-001",
    "name": "Test Sensor Bangkok",
    "type": "earthquake",
    "location": "Bangkok, Thailand",
    "latitude": 13.7563,
    "longitude": 100.5018
  }'
```

#### 1.5 Get User Devices
```bash
curl http://10.134.94.222:3000/api/v1/devices \
  -H "Authorization: Bearer $TOKEN"
```

### 2. ทดสอบ MQTT Connection

#### 2.1 Subscribe to All Topics
```bash
mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/#" -v
```

#### 2.2 Publish Test Data
```bash
# Earthquake Event
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/data" \
  -m '{
    "deviceId": "EQC-TEST-001",
    "magnitude": 4.2,
    "location": "Bangkok, Thailand",
    "latitude": 13.7563,
    "longitude": 100.5018,
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "type": "earthquake",
    "ownerId": "test@example.com"
  }'

# Alert (magnitude >= 3.0)
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/alert" \
  -m '{
    "deviceId": "EQC-TEST-001",
    "magnitude": 5.5,
    "location": "Chiang Mai, Thailand",
    "severity": "high",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

### 3. ทดสอบ Flutter App

#### 3.1 Login
1. เปิดแอพ
2. กรอก email: `test@example.com`
3. กรอก password: `password123`
4. กด Login

**ตรวจสอบ:**
- ✅ Login สำเร็จ
- ✅ เห็นหน้า Dashboard
- ✅ ไม่มี error ใน console

#### 3.2 ดูข้อมูล Real-time
1. ไปที่หน้า Home/Dashboard
2. ดูว่ามีข้อมูลแผ่นดินไหวแสดงหรือไม่

**ทดสอบโดยส่งข้อมูลผ่าน MQTT:**
```bash
# ส่งข้อมูลทดสอบ
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/data" \
  -m '{
    "deviceId": "EQC-TEST-001",
    "magnitude": 3.8,
    "location": "Test Location",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

**ตรวจสอบ:**
- ✅ ข้อมูลแสดงใน Dashboard
- ✅ ได้รับ Notification (ถ้า magnitude >= 3.0)
- ✅ กราฟอัพเดท

#### 3.3 Register Device
1. ไปที่หน้า Devices
2. กด "Add Device" หรือ "Scan QR"
3. กรอกข้อมูล:
   - Device ID: `EQC-TEST-002`
   - Name: `Test Sensor 2`
   - Location: `Bangkok`

**ตรวจสอบ:**
- ✅ Device ถูกเพิ่มใน Backend
- ✅ แสดงในรายการ Devices
- ✅ สามารถดู Details ได้

#### 3.4 ทดสอบ Notification
1. ส่งข้อมูลแผ่นดินไหวขนาดใหญ่:
```bash
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "eqnode.tarita/hub/alert" \
  -m '{
    "deviceId": "EQC-TEST-001",
    "magnitude": 6.5,
    "location": "Bangkok",
    "severity": "critical",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

**ตรวจสอบ:**
- ✅ ได้รับ Notification
- ✅ แสดงข้อมูลถูกต้อง
- ✅ มีเสียงแจ้งเตือน

---

## 📊 ตรวจสอบ Logs

### Backend Logs
```bash
# ดู logs แบบ real-time
cd backend
npm run dev

# หรือดู logs จาก Docker
docker-compose logs -f backend
```

### Flutter Logs
```bash
# ดู logs ใน terminal
flutter run --verbose

# หรือดูใน console ของ IDE
```

### MQTT Logs
```bash
# Subscribe เพื่อดูข้อมูลทั้งหมด
mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "#" -v
```

---

## 🐛 Troubleshooting

### ปัญหา: Backend ไม่ทำงาน

**ตรวจสอบ:**
```bash
# ตรวจสอบว่า PostgreSQL ทำงาน
docker ps | grep postgres

# ตรวจสอบ port 3000
lsof -i :3000

# ดู logs
cd backend && npm run dev
```

**วิธีแก้:**
```bash
# Restart PostgreSQL
docker-compose restart postgres

# Restart Backend
cd backend
npm run dev
```

### ปัญหา: MQTT ไม่เชื่อมต่อ

**ตรวจสอบ:**
```bash
# ทดสอบ connection
mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P ei8jZz87wx \
  -t "test" -v

# ตรวจสอบ credentials
echo "Username: ethernet"
echo "Password: ei8jZz87wx"
```

**วิธีแก้:**
- ตรวจสอบ username/password
- ตรวจสอบ internet connection
- ลอง port 8083 (WebSocket)

### ปัญหา: Flutter App ไม่เชื่อมต่อ Backend

**ตรวจสอบ:**
```bash
# ตรวจสอบ IP address
ifconfig | grep "inet "

# ทดสอบจาก simulator/emulator
curl http://10.134.94.222:3000/api/v1/health
```

**วิธีแก้:**
1. ตรวจสอบว่า Backend ทำงาน
2. ตรวจสอบ IP address ใน `app_config.dart`
3. ตรวจสอบ Firewall settings
4. ใช้ `localhost` ถ้ารันบน emulator

### ปัญหา: ไม่ได้รับ Notification

**ตรวจสอบ:**
1. Permission ของ Notification
2. ดู console logs
3. ทดสอบด้วย Test Alert ใน Settings

**วิธีแก้:**
```bash
# iOS: Reset permissions
xcrun simctl privacy booted reset all

# Android: ไปที่ Settings → Apps → Permissions
```

---

## ✅ Checklist การทดสอบ

### Backend API
- [ ] Health check ทำงาน
- [ ] Register user สำเร็จ
- [ ] Login สำเร็จ
- [ ] Register device สำเร็จ
- [ ] Get devices ได้ข้อมูล
- [ ] Get events ได้ข้อมูล

### MQTT Connection
- [ ] Subscribe สำเร็จ
- [ ] Publish สำเร็จ
- [ ] ได้รับข้อมูล real-time
- [ ] Alert ทำงาน

### Flutter App
- [ ] Login/Logout ทำงาน
- [ ] Dashboard แสดงข้อมูล
- [ ] Real-time update ทำงาน
- [ ] Notification ทำงาน
- [ ] Add/Edit/Delete device ทำงาน
- [ ] กราฟแสดงถูกต้อง

---

## 📝 สคริปต์ช่วยทดสอบ

### สคริปต์ส่งข้อมูลทดสอบ

สร้างไฟล์ `test_mqtt.sh`:

```bash
#!/bin/bash

echo "🧪 Sending test earthquake data..."

for i in {1..10}; do
  magnitude=$(echo "scale=1; 1 + $RANDOM % 60 / 10" | bc)
  
  mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
    -u ethernet -P ei8jZz87wx \
    -t "eqnode.tarita/hub/data" \
    -m "{
      \"deviceId\": \"EQC-TEST-001\",
      \"magnitude\": $magnitude,
      \"location\": \"Test Location $i\",
      \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"
  
  echo "✅ Sent: magnitude=$magnitude"
  sleep 2
done

echo "✅ Test completed!"
```

รัน:
```bash
chmod +x test_mqtt.sh
./test_mqtt.sh
```

---

## 🎯 ขั้นตอนถัดไป

เมื่อทดสอบเสร็จแล้ว:

1. ✅ แก้ไข bugs ที่พบ
2. ✅ ปรับปรุง UI/UX
3. ✅ เพิ่ม error handling
4. ✅ เตรียม build สำหรับ production

---

## 📞 ติดต่อ

หากพบปัญหา:
1. ดู logs ใน console
2. ตรวจสอบ network connection
3. ทดสอบแต่ละส่วนแยกกัน
4. อ่าน error messages ให้ละเอียด

---

**ขอให้การทดสอบราบรื่น! 🚀**
