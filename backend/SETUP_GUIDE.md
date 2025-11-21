# 🚀 คู่มือการติดตั้ง Backend Server

## วิธีที่ 1: ติดตั้งแบบง่าย (ใช้ Docker) ⭐ แนะนำ

### ข้อกำหนด:
- Docker และ Docker Compose ติดตั้งแล้ว

### ขั้นตอน:

```bash
# 1. เข้าไปในโฟลเดอร์ backend
cd backend

# 2. สร้างไฟล์ .env
cp .env.example .env

# 3. เริ่มต้น services ทั้งหมด (PostgreSQL + MongoDB + API)
docker-compose up -d

# 4. รอ services พร้อม (ประมาณ 30 วินาที)
docker-compose logs -f api

# 5. รัน database migration
docker-compose exec api npm run migrate

# 6. ทดสอบ API
curl http://localhost:3000/health
```

✅ เสร็จแล้ว! API พร้อมใช้งานที่ `http://localhost:3000`

### คำสั่งที่มีประโยชน์:

```bash
# ดู logs
docker-compose logs -f

# หยุด services
docker-compose down

# หยุดและลบข้อมูล
docker-compose down -v

# Restart
docker-compose restart api
```

---

## วิธีที่ 2: ติดตั้งแบบ Manual

### ข้อกำหนด:
- Node.js 18+ ติดตั้งแล้ว
- PostgreSQL 12+ ติดตั้งแล้ว
- MongoDB 5+ (optional - สำหรับ logs)

### ขั้นตอน:

#### 1. ติดตั้ง Dependencies

```bash
cd backend
npm install
```

#### 2. ตั้งค่า PostgreSQL

```bash
# เข้าสู่ PostgreSQL
psql -U postgres

# สร้าง database
CREATE DATABASE eqnode_dev;

# สร้าง user (optional)
CREATE USER eqnode_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE eqnode_dev TO eqnode_user;

# ออกจาก psql
\q
```

#### 3. ตั้งค่า Environment Variables

```bash
# Copy ไฟล์ตัวอย่าง
cp .env.example .env

# แก้ไขไฟล์ .env
nano .env
```

แก้ไขค่าต่อไปนี้:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=eqnode_dev
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your_super_secret_key_change_this_to_random_string

MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
```

#### 4. รัน Database Migration

```bash
npm run migrate
```

คุณจะเห็น:
```
✅ Database schema created successfully
✅ Test user created/updated: user@eqnode.com
   Email: user@eqnode.com
   Password: password123
```

#### 5. เริ่มต้น Server

```bash
# Development mode (auto-reload)
npm run dev

# หรือ Production mode
npm start
```

คุณจะเห็น:
```
=================================
🚀 eQNode Backend Server Started
=================================
Environment: development
Port: 3000
API Version: v1
API URL: http://localhost:3000/api/v1
Health Check: http://localhost:3000/health
=================================

✅ PostgreSQL connected
✅ MongoDB connected
🔌 Connecting to MQTT Broker: mqtt://mqtt.uiot.cloud:1883
✅ MQTT Connected
📡 Subscribed to: earthquake/data
📡 Subscribed to: earthquake/alert
📡 Subscribed to: earthquake/status
📡 Subscribed to: device/+/status
```

---

## 🧪 ทดสอบ API

### 1. Health Check

```bash
curl http://localhost:3000/health
```

ผลลัพธ์:
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2024-11-20T10:30:00.000Z",
  "mqtt": "connected",
  "version": "v1"
}
```

### 2. Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@eqnode.com",
    "password": "password123"
  }'
```

ผลลัพธ์:
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "ผู้ใช้ทดสอบ",
    "email": "user@eqnode.com",
    "phone": "090-000-0000"
  }
}
```

### 3. ลงทะเบียนอุปกรณ์

```bash
# เก็บ token ไว้ในตัวแปร
TOKEN="your_token_from_login"

curl -X POST http://localhost:3000/api/v1/devices/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "deviceId": "EQC-001",
    "name": "อุปกรณ์ทดสอบ 1",
    "type": "earthquake",
    "location": "Bangkok, Thailand",
    "latitude": 13.7563,
    "longitude": 100.5018
  }'
```

### 4. ดูอุปกรณ์ทั้งหมด

```bash
curl -X GET http://localhost:3000/api/v1/devices/user \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔗 เชื่อมต่อกับ Flutter App

### 1. แก้ไขไฟล์ `lib/config/app_config.dart`

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      // เปลี่ยนจาก localhost เป็น IP ของเครื่องคุณ
      return 'http://192.168.1.100:3000/api/v1'; // เปลี่ยน IP ตามเครื่องคุณ
    case Environment.staging:
      return 'https://staging-api.eqnode.com/api/v1';
    case Environment.production:
      return 'https://api.eqnode.com/api/v1';
  }
}
```

### 2. หา IP Address ของเครื่องคุณ

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig
```

ใช้ IP ที่ขึ้นต้นด้วย `192.168.x.x` หรือ `10.x.x.x`

### 3. ตั้งค่า CORS ใน Backend

แก้ไขไฟล์ `.env`:
```env
ALLOWED_ORIGINS=http://localhost:3000,http://192.168.1.100:3000
```

Restart server:
```bash
# ถ้าใช้ Docker
docker-compose restart api

# ถ้าใช้ npm
# กด Ctrl+C แล้วรันใหม่
npm run dev
```

### 4. ทดสอบจาก Flutter App

```bash
cd ..  # กลับไปที่ root project
flutter run
```

ลอง Login ด้วย:
- Email: `user@eqnode.com`
- Password: `password123`

---

## 📊 ดูข้อมูลใน Database

### ใช้ psql:

```bash
# เข้าสู่ database
psql -U postgres -d eqnode_dev

# ดูตาราง
\dt

# ดูข้อมูล users
SELECT * FROM users;

# ดูข้อมูล devices
SELECT * FROM devices;

# ดูข้อมูล earthquake events
SELECT * FROM earthquake_events ORDER BY timestamp DESC LIMIT 10;

# ออกจาก psql
\q
```

### ใช้ Docker:

```bash
docker-compose exec postgres psql -U postgres -d eqnode_dev
```

---

## 🐛 แก้ไขปัญหา

### ปัญหา: Port 3000 ถูกใช้งานแล้ว

```bash
# หา process ที่ใช้ port
lsof -i :3000

# Kill process
kill -9 <PID>

# หรือเปลี่ยน port ใน .env
PORT=3001
```

### ปัญหา: PostgreSQL connection error

```bash
# ตรวจสอบว่า PostgreSQL รันอยู่
pg_isready

# ถ้าใช้ Docker
docker-compose ps

# ดู logs
docker-compose logs postgres
```

### ปัญหา: MQTT connection error

- ตรวจสอบ internet connection
- ตรวจสอบ credentials ใน `.env`
- MQTT broker อาจจะ down ชั่วคราว (ไม่เป็นไร server จะ auto-reconnect)

### ปัญหา: Flutter app ไม่เชื่อมต่อ Backend

1. ตรวจสอบว่า Backend รันอยู่: `curl http://localhost:3000/health`
2. ตรวจสอบ IP address ใน `app_config.dart`
3. ตรวจสอบว่าเครื่อง mobile/emulator อยู่ network เดียวกัน
4. ตรวจสอบ CORS settings ใน Backend

---

## 📝 บัญชีทดสอบ

หลังจากรัน migration แล้ว จะมีบัญชีทดสอบ:

- **Email:** `user@eqnode.com`
- **Password:** `password123`

คุณสามารถสร้างบัญชีใหม่ผ่าน API `/api/v1/auth/register` หรือผ่าน Flutter app

---

## 🎯 ขั้นตอนถัดไป

1. ✅ Backend Server รันแล้ว
2. ✅ Database พร้อมใช้งาน
3. ✅ MQTT เชื่อมต่อแล้ว
4. 🔄 เชื่อมต่อ Flutter App กับ Backend
5. 🔄 ทดสอบการลงทะเบียนอุปกรณ์
6. 🔄 ทดสอบการรับข้อมูล MQTT
7. 🔄 Deploy ขึ้น Production Server

---

## 💡 Tips

- ใช้ **Postman** หรือ **Insomnia** สำหรับทดสอบ API
- ใช้ **MQTT Explorer** สำหรับทดสอบ MQTT
- ใช้ **pgAdmin** หรือ **DBeaver** สำหรับจัดการ PostgreSQL
- เปิด **Debug Logging** ใน development: `ENABLE_DEBUG_LOGGING=true`

---

## 📞 ต้องการความช่วยเหลือ?

ถ้ามีปัญหาหรือคำถาม:
1. ตรวจสอบ logs: `docker-compose logs -f` หรือดูใน terminal
2. ตรวจสอบ `.env` ว่าตั้งค่าถูกต้อง
3. ลอง restart services: `docker-compose restart`
4. ถามได้เลยครับ! 😊
