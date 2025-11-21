# ✅ Backend Server สร้างเสร็จแล้ว!

## 🎉 สิ่งที่สร้างเสร็จแล้ว

### 📁 โครงสร้าง Backend

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js          # PostgreSQL + MongoDB connection
│   │   └── mqtt.js              # MQTT client manager
│   ├── models/
│   │   ├── User.js              # User model
│   │   ├── Device.js            # Device model
│   │   └── EarthquakeEvent.js   # Event model
│   ├── routes/
│   │   ├── auth.js              # Authentication APIs
│   │   ├── devices.js           # Device management APIs
│   │   └── events.js            # Event/Alert APIs
│   ├── middleware/
│   │   └── auth.js              # JWT authentication
│   ├── database/
│   │   ├── schema.sql           # Database schema
│   │   └── migrate.js           # Migration script
│   └── server.js                # Main server
├── .env.example                 # Environment template
├── .gitignore
├── package.json
├── Dockerfile                   # Docker image
├── docker-compose.yml           # Docker services
├── README.md                    # Documentation
└── SETUP_GUIDE.md              # Setup instructions
```

## ✨ Features ที่พร้อมใช้งาน

### 🔐 Authentication
- ✅ Register (สมัครสมาชิก)
- ✅ Login (เข้าสู่ระบบ)
- ✅ JWT Token authentication
- ✅ Get/Update Profile
- ✅ Change Password
- ✅ Refresh Token
- ✅ Logout

### 📱 Device Management
- ✅ Register Device (ลงทะเบียนอุปกรณ์)
- ✅ Get User Devices (ดูอุปกรณ์ทั้งหมด)
- ✅ Get Device Details
- ✅ Update Device
- ✅ Delete Device
- ✅ Get Device Status
- ✅ Transfer Ownership (โอนความเป็นเจ้าของ)
- ✅ Get Device Statistics

### 🌍 Earthquake Events
- ✅ Get Events (with pagination & filters)
- ✅ Get Event Details
- ✅ Report False Positive
- ✅ Get Recent Alerts
- ✅ Auto-save MQTT data to database

### 🔌 MQTT Integration
- ✅ Auto-connect to MQTT Broker
- ✅ Subscribe to earthquake topics
- ✅ Process real-time data
- ✅ Auto-reconnect on disconnect
- ✅ Save events to database
- ✅ Update device status

### 🛡️ Security
- ✅ JWT authentication
- ✅ Password hashing (bcrypt)
- ✅ Rate limiting
- ✅ CORS protection
- ✅ Helmet security headers
- ✅ Input validation

### 📊 Database
- ✅ PostgreSQL schema
- ✅ Auto-migration script
- ✅ Indexes for performance
- ✅ Foreign key constraints
- ✅ Timestamps (created_at, updated_at)

## 🚀 วิธีเริ่มใช้งาน

### แบบง่าย (Docker) - แนะนำ! ⭐

```bash
cd backend
cp .env.example .env
docker-compose up -d
docker-compose exec api npm run migrate
```

✅ เสร็จแล้ว! API พร้อมที่ `http://localhost:3000`

### แบบ Manual

```bash
cd backend
npm install
cp .env.example .env
# แก้ไข .env ให้ถูกต้อง
npm run migrate
npm run dev
```

## 🧪 ทดสอบ API

### 1. Health Check
```bash
curl http://localhost:3000/health
```

### 2. Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@eqnode.com","password":"password123"}'
```

### 3. Get Devices (ต้องใส่ token)
```bash
curl http://localhost:3000/api/v1/devices/user \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔗 เชื่อมต่อกับ Flutter App

### 1. หา IP Address ของเครื่อง

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig
```

### 2. แก้ไข Flutter Config

แก้ไขไฟล์ `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://192.168.1.100:3000/api/v1'; // ⬅️ เปลี่ยนเป็น IP ของคุณ
    // ...
  }
}
```

### 3. ตั้งค่า CORS

แก้ไขไฟล์ `backend/.env`:
```env
ALLOWED_ORIGINS=http://localhost:3000,http://192.168.1.100:3000
```

### 4. Restart Backend
```bash
docker-compose restart api
# หรือ
npm run dev
```

### 5. ทดสอบจาก Flutter
```bash
flutter run
```

Login ด้วย:
- Email: `user@eqnode.com`
- Password: `password123`

## 📡 API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication
- `POST /auth/register` - สมัครสมาชิก
- `POST /auth/login` - เข้าสู่ระบบ
- `GET /auth/profile` - ดูโปรไฟล์
- `PUT /auth/profile` - แก้ไขโปรไฟล์
- `PUT /auth/change-password` - เปลี่ยนรหัสผ่าน
- `POST /auth/refresh` - Refresh token
- `POST /auth/logout` - ออกจากระบบ

### Devices
- `POST /devices/register` - ลงทะเบียนอุปกรณ์
- `GET /devices/user` - ดูอุปกรณ์ทั้งหมด
- `GET /devices/:id` - ดูรายละเอียด
- `PUT /devices/:id` - แก้ไข
- `DELETE /devices/:id` - ลบ
- `GET /devices/:id/status` - ดูสถานะ
- `PUT /devices/:id/transfer` - โอนความเป็นเจ้าของ
- `GET /devices/:id/statistics` - ดูสถิติ

### Events
- `GET /events/earthquake` - ดูเหตุการณ์ (มี filter)
- `GET /events/:id` - ดูรายละเอียด
- `PUT /events/:id/report-false-positive` - รายงาน
- `GET /events/alerts/recent` - ดูการแจ้งเตือน

## 📊 Database Schema

### Users
- id, name, email, password (hashed)
- phone, address
- created_at, updated_at

### Devices
- id, device_id, name, type
- location, latitude, longitude
- owner_id, status, last_seen
- created_at, updated_at

### Earthquake Events
- id, device_id, magnitude
- location, latitude, longitude
- type, severity, raw_data
- timestamp, processed, notification_sent
- false_positive, created_at, updated_at

## 🔌 MQTT Topics

Backend subscribe topics:
- `earthquake/data` - ข้อมูลแผ่นดินไหว
- `earthquake/alert` - การแจ้งเตือน
- `earthquake/status` - สถานะระบบ
- `device/+/status` - สถานะอุปกรณ์ (wildcard)

## 🎯 ขั้นตอนถัดไป

1. ✅ Backend Server สร้างเสร็จแล้ว
2. ✅ Database พร้อมใช้งาน
3. ✅ MQTT เชื่อมต่อแล้ว
4. 🔄 **ต่อไป: เชื่อมต่อ Flutter App**
5. 🔄 ทดสอบการทำงานแบบ end-to-end
6. 🔄 Deploy ขึ้น Production Server

## 💡 Tips

### Development
- ใช้ `npm run dev` สำหรับ auto-reload
- ดู logs: `docker-compose logs -f api`
- ทดสอบ API ด้วย Postman/Insomnia
- ทดสอบ MQTT ด้วย MQTT Explorer

### Production
- ตั้งค่า `JWT_SECRET` ที่ปลอดภัย
- เปลี่ยน database password
- ตั้งค่า HTTPS
- ใช้ environment variables
- ตั้งค่า monitoring
- ทำ database backup

## 🐛 Troubleshooting

### Port 3000 ถูกใช้แล้ว
```bash
lsof -i :3000
kill -9 <PID>
```

### Database connection error
```bash
# ตรวจสอบ PostgreSQL
pg_isready
docker-compose ps
docker-compose logs postgres
```

### MQTT connection error
- ตรวจสอบ internet
- ตรวจสอบ credentials ใน .env
- Server จะ auto-reconnect

### Flutter app ไม่เชื่อมต่อ
1. ตรวจสอบ Backend รันอยู่
2. ตรวจสอบ IP address
3. ตรวจสอบ CORS settings
4. ตรวจสอบ network (same WiFi)

## 📦 Dependencies

### Main
- express - Web framework
- pg - PostgreSQL client
- mongoose - MongoDB ODM
- mqtt - MQTT client
- bcryptjs - Password hashing
- jsonwebtoken - JWT authentication
- express-validator - Input validation
- helmet - Security headers
- cors - CORS middleware
- morgan - HTTP logger

### Dev
- nodemon - Auto-reload

## 📝 บัญชีทดสอบ

หลัง migration จะมีบัญชี:
- **Email:** user@eqnode.com
- **Password:** password123

## 🎉 สรุป

Backend Server พร้อมใช้งานแล้ว! มีครบทุกฟีเจอร์ที่ Flutter App ต้องการ:

✅ Authentication & User Management
✅ Device Registration & Management  
✅ Earthquake Event Tracking
✅ MQTT Real-time Integration
✅ Security & Validation
✅ Database with Auto-migration
✅ Docker Support
✅ API Documentation

**ขั้นตอนถัดไป:** เชื่อมต่อ Flutter App กับ Backend แล้วทดสอบการทำงาน!

---

📖 **อ่านเพิ่มเติม:**
- `backend/README.md` - Documentation
- `backend/SETUP_GUIDE.md` - Setup instructions
- `backend/.env.example` - Configuration template

🚀 **พร้อมแล้ว! ลองเริ่มใช้งานได้เลย**
