# eQNode Backend API

Backend server สำหรับระบบแจ้งเตือนแผ่นดินไหว eQNode

## 🚀 Quick Start

### 1. ติดตั้ง Dependencies

```bash
cd backend
npm install
```

### 2. ตั้งค่า Environment Variables

```bash
cp .env.example .env
```

แก้ไขไฟล์ `.env` ตามความเหมาะสม:
- Database credentials (PostgreSQL)
- JWT secret key
- MQTT broker settings
- FCM server key (optional)

### 3. ตั้งค่า PostgreSQL Database

```bash
# สร้าง database
createdb eqnode_dev

# หรือใช้ psql
psql -U postgres
CREATE DATABASE eqnode_dev;
\q
```

### 4. รัน Database Migration

```bash
npm run migrate
```

คำสั่งนี้จะ:
- สร้างตารางทั้งหมด (users, devices, earthquake_events)
- สร้าง indexes
- สร้างบัญชีทดสอบ: `user@eqnode.com` / `password123`

### 5. เริ่มต้น Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

Server จะรันที่: `http://localhost:3000`

## 📡 API Endpoints

### Authentication

- `POST /api/v1/auth/register` - สมัครสมาชิก
- `POST /api/v1/auth/login` - เข้าสู่ระบบ
- `GET /api/v1/auth/profile` - ดูโปรไฟล์ (ต้อง login)
- `PUT /api/v1/auth/profile` - แก้ไขโปรไฟล์
- `PUT /api/v1/auth/change-password` - เปลี่ยนรหัสผ่าน
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - ออกจากระบบ

### Devices

- `POST /api/v1/devices/register` - ลงทะเบียนอุปกรณ์
- `GET /api/v1/devices/user` - ดูอุปกรณ์ทั้งหมดของผู้ใช้
- `GET /api/v1/devices/:id` - ดูรายละเอียดอุปกรณ์
- `PUT /api/v1/devices/:id` - แก้ไขอุปกรณ์
- `DELETE /api/v1/devices/:id` - ลบอุปกรณ์
- `GET /api/v1/devices/:id/status` - ดูสถานะอุปกรณ์
- `PUT /api/v1/devices/:id/transfer` - โอนความเป็นเจ้าของ
- `GET /api/v1/devices/:id/statistics` - ดูสถิติอุปกรณ์

### Events

- `GET /api/v1/events/earthquake` - ดูเหตุการณ์แผ่นดินไหว (มี pagination และ filter)
- `GET /api/v1/events/:id` - ดูรายละเอียดเหตุการณ์
- `PUT /api/v1/events/:id/report-false-positive` - รายงาน false positive
- `GET /api/v1/events/alerts/recent` - ดูการแจ้งเตือนล่าสุด

### Health Check

- `GET /health` - ตรวจสอบสถานะ server

## 🔐 Authentication

API ใช้ JWT (JSON Web Token) สำหรับ authentication

### การใช้งาน:

1. Login เพื่อรับ token:
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@eqnode.com","password":"password123"}'
```

2. ใช้ token ใน header:
```bash
curl -X GET http://localhost:3000/api/v1/devices/user \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 📊 Database Schema

### Users Table
- id, name, email, password, phone, address
- timestamps: created_at, updated_at

### Devices Table
- id, device_id, name, type, location, latitude, longitude
- owner_id (FK to users)
- status, last_seen
- timestamps: created_at, updated_at

### Earthquake Events Table
- id, device_id, magnitude, location, latitude, longitude
- type, severity, raw_data (JSONB)
- timestamp, processed, notification_sent, false_positive
- timestamps: created_at, updated_at

## 🔌 MQTT Integration

Server เชื่อมต่อกับ MQTT Broker และ subscribe topics:
- `earthquake/data` - ข้อมูลแผ่นดินไหว
- `earthquake/alert` - การแจ้งเตือน
- `earthquake/status` - สถานะระบบ
- `device/+/status` - สถานะอุปกรณ์

เมื่อได้รับข้อมูล MQTT:
1. บันทึกลง database
2. อัพเดทสถานะอุปกรณ์
3. ส่ง push notification (ถ้า magnitude >= 3.0)

## 🧪 Testing

### ทดสอบด้วย curl:

```bash
# Health check
curl http://localhost:3000/health

# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "phone": "080-000-0000"
  }'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@eqnode.com",
    "password": "password123"
  }'
```

### ทดสอบด้วย Postman:

Import collection จาก `postman_collection.json` (ถ้ามี)

## 🛠️ Development

### โครงสร้างโปรเจกต์:

```
backend/
├── src/
│   ├── config/          # Configuration files
│   │   ├── database.js  # Database connections
│   │   └── mqtt.js      # MQTT client
│   ├── models/          # Data models
│   │   ├── User.js
│   │   ├── Device.js
│   │   └── EarthquakeEvent.js
│   ├── routes/          # API routes
│   │   ├── auth.js
│   │   ├── devices.js
│   │   └── events.js
│   ├── middleware/      # Express middleware
│   │   └── auth.js
│   ├── database/        # Database scripts
│   │   ├── schema.sql
│   │   └── migrate.js
│   └── server.js        # Main server file
├── .env.example         # Environment variables template
├── .gitignore
├── package.json
└── README.md
```

## 🚀 Deployment

### Production Checklist:

- [ ] ตั้งค่า environment variables ที่ปลอดภัย
- [ ] ใช้ HTTPS
- [ ] ตั้งค่า CORS ให้เหมาะสม
- [ ] เปิด rate limiting
- [ ] ตั้งค่า database backup
- [ ] ตั้งค่า monitoring และ logging
- [ ] ใช้ process manager (PM2, systemd)
- [ ] ตั้งค่า reverse proxy (Nginx)

### Deploy ด้วย PM2:

```bash
npm install -g pm2
pm2 start src/server.js --name eqnode-api
pm2 save
pm2 startup
```

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NODE_ENV | Environment (development/production) | development |
| PORT | Server port | 3000 |
| DB_HOST | PostgreSQL host | localhost |
| DB_PORT | PostgreSQL port | 5432 |
| DB_NAME | Database name | eqnode_dev |
| DB_USER | Database user | postgres |
| DB_PASSWORD | Database password | - |
| JWT_SECRET | JWT secret key | - |
| MQTT_BROKER_URL | MQTT broker URL | mqtt://mqtt.uiot.cloud:1883 |
| MQTT_USERNAME | MQTT username | ethernet |
| MQTT_PASSWORD | MQTT password | - |

## 🐛 Troubleshooting

### Database connection error:
```bash
# ตรวจสอบว่า PostgreSQL รันอยู่
pg_isready

# ตรวจสอบ credentials
psql -U postgres -d eqnode_dev
```

### MQTT connection error:
- ตรวจสอบ broker URL และ credentials
- ตรวจสอบ firewall/network
- ลองใช้ MQTT client อื่นทดสอบ (MQTT Explorer)

### Port already in use:
```bash
# หา process ที่ใช้ port
lsof -i :3000

# Kill process
kill -9 <PID>
```

## 📞 Support

สำหรับคำถามหรือปัญหา:
- Email: dev@eqnode.com
- GitHub Issues: [repository-url]

## 📄 License

MIT License
