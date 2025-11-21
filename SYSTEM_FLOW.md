# 🔄 Flow การทำงานของระบบ eQNode

## 📊 ภาพรวมระบบ

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLOW การทำงานทั้งหมด                          │
└─────────────────────────────────────────────────────────────────┘

1. ผู้ใช้เปิด Flutter App
2. Login เข้าสู่ระบบ → Backend API
3. ลงทะเบียนอุปกรณ์ (QR Scanner) → Backend API → Database
4. อุปกรณ์ IoT ส่งข้อมูล → MQTT Broker
5. Backend รับข้อมูล MQTT → บันทึก Database
6. Backend ส่ง Push Notification → Flutter App
7. Flutter App แสดงข้อมูล Real-time
```

## 🎯 Flow แบบละเอียด

### 1️⃣ การเข้าสู่ระบบ (Login Flow)

```
[Flutter App] 
    ↓ POST /api/v1/auth/login
    ↓ {email, password}
[Backend API]
    ↓ ตรวจสอบ email/password
    ↓ Query PostgreSQL
[Database]
    ↓ ส่งข้อมูล user กลับ
[Backend API]
    ↓ สร้าง JWT Token
    ↓ Response {token, user}
[Flutter App]
    ↓ เก็บ token ใน Secure Storage
    ✅ Login สำเร็จ
```

### 2️⃣ การลงทะเบียนอุปกรณ์ (Device Registration Flow)

```
[Flutter App]
    ↓ สแกน QR Code → ได้ Device ID
    ↓ ขอ GPS Location
    ↓ POST /api/v1/devices/register
    ↓ Header: Authorization: Bearer {token}
    ↓ Body: {deviceId, name, location, lat, lng}
[Backend API]
    ↓ ตรวจสอบ JWT Token
    ↓ ตรวจสอบ Device ID ซ้ำหรือไม่
    ↓ ตรวจสอบจำนวนอุปกรณ์ (max 10)
    ↓ INSERT INTO devices
[Database]
    ↓ บันทึกข้อมูลอุปกรณ์
    ↓ Response {success, device}
[Flutter App]
    ✅ แสดงอุปกรณ์ใน Dashboard
```

### 3️⃣ การรับข้อมูล Real-time (MQTT Flow)

```
[IoT Device/Sensor]
    ↓ ตรวจจับแผ่นดินไหว
    ↓ Publish MQTT
    ↓ Topic: earthquake/data
    ↓ Payload: {deviceId, magnitude, location, timestamp}
[MQTT Broker] (mqtt.uiot.cloud)
    ↓ รับข้อมูล
    ↓ Forward ไปยัง Subscribers
    ├─→ [Backend API]
    │       ↓ รับข้อมูล MQTT
    │       ↓ INSERT INTO earthquake_events
    │       ↓ UPDATE devices (last_seen)
    │       ↓ ถ้า magnitude >= 3.0
    │       ↓ ส่ง Push Notification (FCM)
    │       [Database]
    │           ✅ บันทึกเหตุการณ์
    │
    └─→ [Flutter App] (ถ้าเปิดอยู่)
            ↓ รับข้อมูล MQTT โดยตรง
            ↓ แสดงใน Dashboard Real-time
            ✅ อัพเดท UI
```

### 4️⃣ การดูประวัติ (History Flow)

```
[Flutter App]
    ↓ GET /api/v1/events/earthquake
    ↓ Query params: ?page=1&limit=20&deviceId=EQC-001
    ↓ Header: Authorization: Bearer {token}
[Backend API]
    ↓ ตรวจสอบ JWT Token
    ↓ Query earthquake_events
    ↓ Filter เฉพาะอุปกรณ์ของ user
    ↓ Pagination
[Database]
    ↓ ส่งข้อมูลกลับ
[Backend API]
    ↓ Response {events, pagination}
[Flutter App]
    ✅ แสดงรายการประวัติ
```

### 5️⃣ การแจ้งเตือน (Push Notification Flow)

```
[Backend API]
    ↓ ตรวจจับ magnitude >= 3.0
    ↓ ดึง FCM Token ของ device owner
    ↓ ส่ง HTTP Request ไปยัง FCM
[Firebase Cloud Messaging]
    ↓ ส่ง notification
[Flutter App] (แม้ปิดอยู่)
    ↓ รับ notification
    ↓ แสดง Alert
    ✅ ผู้ใช้เห็นการแจ้งเตือน
```

---

## 🛠️ สิ่งที่ต้องเตรียมเพื่อให้แอพทำงานได้

### ✅ ขั้นตอนที่ 1: เตรียม Backend Server

#### Option A: ทดสอบบนเครื่องตัวเอง (Development) ⭐ แนะนำเริ่มต้น

```bash
# 1. ติดตั้ง Docker Desktop (ถ้ายังไม่มี)
# Download: https://www.docker.com/products/docker-desktop

# 2. เริ่ม Backend
cd backend
cp .env.example .env
docker-compose up -d

# 3. รัน Migration
docker-compose exec api npm run migrate

# 4. ตรวจสอบว่ารันแล้ว
curl http://localhost:3000/health
```

**ผลลัพธ์ที่ควรเห็น:**
```json
{
  "success": true,
  "status": "healthy",
  "mqtt": "connected"
}
```

#### Option B: Deploy บน Cloud Server (Production)

คุณต้องมี:
1. **VPS/Cloud Server** (AWS, DigitalOcean, Linode, etc.)
2. **Domain Name** (optional แต่แนะนำ)
3. **SSL Certificate** (สำหรับ HTTPS)

---

### ✅ ขั้นตอนที่ 2: เชื่อมต่อ Flutter App กับ Backend

#### 2.1 หา IP Address ของเครื่อง

**macOS:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig
```

**Linux:**
```bash
hostname -I
```

คุณจะได้ IP แบบนี้: `192.168.1.100` (ตัวอย่าง)

#### 2.2 แก้ไข Flutter Config

เปิดไฟล์ `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      // เปลี่ยนจาก localhost เป็น IP ของคุณ
      return 'http://192.168.1.100:3000/api/v1'; // ⬅️ เปลี่ยนตรงนี้
    case Environment.staging:
      return 'https://staging-api.eqnode.com/api/v1';
    case Environment.production:
      return 'https://api.eqnode.com/api/v1';
  }
}
```

#### 2.3 ตั้งค่า CORS ใน Backend

แก้ไขไฟล์ `backend/.env`:

```env
ALLOWED_ORIGINS=http://localhost:3000,http://192.168.1.100:3000,http://10.0.2.2:3000
```

**หมายเหตุ:** 
- `10.0.2.2` = IP สำหรับ Android Emulator
- `192.168.1.100` = IP จริงของเครื่องคุณ

#### 2.4 Restart Backend

```bash
docker-compose restart api
```

---

### ✅ ขั้นตอนที่ 3: ทดสอบการเชื่อมต่อ

#### 3.1 ทดสอบจาก Browser

เปิด browser ไปที่:
```
http://192.168.1.100:3000/health
```

ถ้าเห็น JSON response = เชื่อมต่อได้แล้ว ✅

#### 3.2 ทดสอบจาก Flutter App

```bash
# รัน Flutter App
flutter run

# หรือถ้าต้องการเลือก device
flutter devices
flutter run -d <device-id>
```

#### 3.3 ทดสอบ Login

ใน Flutter App:
1. เปิดหน้า Login
2. ใส่:
   - Email: `user@eqnode.com`
   - Password: `password123`
3. กด Login

**ถ้า Login สำเร็จ** = Backend เชื่อมต่อได้แล้ว! 🎉

---

### ✅ ขั้นตอนที่ 4: ทดสอบฟีเจอร์ต่างๆ

#### 4.1 ทดสอบลงทะเบียนอุปกรณ์

1. Login เข้าแอพ
2. ไปที่ "ตั้งค่าระบบ"
3. กด "สแกน QR Code" หรือ "ป้อนด้วยตนเอง"
4. ใส่:
   - Device ID: `EQC-TEST-001`
   - ชื่ออุปกรณ์: `อุปกรณ์ทดสอบ`
   - ตำแหน่ง: `Bangkok`
5. กด "ลงทะเบียน"

**ตรวจสอบใน Database:**
```bash
docker-compose exec postgres psql -U postgres -d eqnode_dev -c "SELECT * FROM devices;"
```

#### 4.2 ทดสอบ MQTT Real-time

Backend จะสร้างข้อมูลจำลองทุก 4 วินาที (ใน Development mode)

ดูใน Flutter App:
- Dashboard จะแสดงข้อมูล Real-time
- ประวัติจะมีรายการใหม่เพิ่มขึ้นเรื่อยๆ

**ดู Logs:**
```bash
docker-compose logs -f api
```

คุณจะเห็น:
```
📨 MQTT Message [earthquake/data]: {...}
✅ Earthquake event saved: 1
```

#### 4.3 ทดสอบ Push Notification (Optional)

ต้องตั้งค่า Firebase FCM ก่อน (ข้ามไปก่อนได้)

---

## 📋 Checklist การเตรียมความพร้อม

### สำหรับ Development (ทดสอบบนเครื่อง)

- [ ] ติดตั้ง Docker Desktop
- [ ] Clone/Pull โค้ดล่าสุด
- [ ] รัน `docker-compose up -d` ใน backend/
- [ ] รัน `npm run migrate` เพื่อสร้าง database
- [ ] ตรวจสอบ `http://localhost:3000/health`
- [ ] หา IP Address ของเครื่อง
- [ ] แก้ไข `lib/config/app_config.dart` ใส่ IP
- [ ] แก้ไข `backend/.env` ตั้งค่า CORS
- [ ] Restart backend: `docker-compose restart api`
- [ ] รัน Flutter: `flutter run`
- [ ] ทดสอบ Login ด้วย `user@eqnode.com` / `password123`
- [ ] ทดสอบลงทะเบียนอุปกรณ์
- [ ] ตรวจสอบข้อมูล Real-time ใน Dashboard

### สำหรับ Production (Deploy จริง)

- [ ] เช่า VPS/Cloud Server
- [ ] ติดตั้ง Docker บน Server
- [ ] ซื้อ Domain Name (optional)
- [ ] ตั้งค่า DNS Records
- [ ] ติดตั้ง SSL Certificate (Let's Encrypt)
- [ ] Deploy Backend ขึ้น Server
- [ ] ตั้งค่า Environment Variables
- [ ] ตั้งค่า Firewall (เปิด port 80, 443, 3000)
- [ ] ตั้งค่า PostgreSQL Production
- [ ] ตั้งค่า MQTT Broker (หรือใช้ของเดิม)
- [ ] ตั้งค่า Firebase FCM
- [ ] แก้ไข Flutter config ใช้ Production URL
- [ ] Build APK/AAB สำหรับ Production
- [ ] ทดสอบทุกฟีเจอร์
- [ ] Upload ขึ้น Play Store/App Store

---

## 🎯 สรุป: ต้องทำอะไรบ้าง?

### แบบง่ายสุด (ทดสอบบนเครื่อง):

```bash
# 1. เริ่ม Backend
cd backend
docker-compose up -d
docker-compose exec api npm run migrate

# 2. หา IP
ifconfig | grep "inet "  # macOS/Linux
ipconfig                  # Windows

# 3. แก้ไข Flutter
# เปิด lib/config/app_config.dart
# เปลี่ยน localhost เป็น IP ของคุณ

# 4. แก้ไข Backend CORS
# เปิด backend/.env
# เพิ่ม IP ของคุณใน ALLOWED_ORIGINS

# 5. Restart
cd backend
docker-compose restart api

# 6. รัน Flutter
cd ..
flutter run

# 7. ทดสอบ
# Login: user@eqnode.com / password123
```

---

## 🆘 ถ้ามีปัญหา

### ปัญหา: Flutter ไม่เชื่อมต่อ Backend

**ตรวจสอบ:**
1. Backend รันอยู่หรือไม่: `curl http://localhost:3000/health`
2. IP ถูกต้องหรือไม่: ลอง ping IP
3. Firewall บล็อกหรือไม่: ปิด firewall ชั่วคราว
4. CORS ตั้งค่าถูกหรือไม่: ดู backend logs
5. Mobile/Emulator อยู่ network เดียวกันหรือไม่

### ปัญหา: MQTT ไม่เชื่อมต่อ

**ตรวจสอบ:**
1. Internet connection
2. MQTT credentials ใน `.env`
3. ดู backend logs: `docker-compose logs -f api`
4. MQTT Broker อาจจะ down (ไม่เป็นไร จะ auto-reconnect)

### ปัญหา: Database error

**แก้ไข:**
```bash
# ลบและสร้างใหม่
docker-compose down -v
docker-compose up -d
docker-compose exec api npm run migrate
```

---

## 💡 Tips

1. **ใช้ Android Emulator:** ใช้ IP `10.0.2.2` แทน `localhost`
2. **ใช้ iOS Simulator:** ใช้ `localhost` ได้เลย
3. **ใช้ Real Device:** ต้องอยู่ WiFi เดียวกัน + ใช้ IP จริง
4. **Debug:** เปิด logs ทั้ง Backend และ Flutter
5. **Postman:** ใช้ทดสอบ API ก่อนจะดีมาก

---

## 🎉 เมื่อทำครบแล้ว

คุณจะได้:
- ✅ Backend API ทำงานได้
- ✅ Database พร้อมใช้งาน
- ✅ MQTT Real-time ทำงาน
- ✅ Flutter App เชื่อมต่อ Backend
- ✅ Login/Register ได้
- ✅ ลงทะเบียนอุปกรณ์ได้
- ✅ ดูข้อมูล Real-time ได้
- ✅ ดูประวัติได้

**พร้อมใช้งานจริงแล้ว!** 🚀
