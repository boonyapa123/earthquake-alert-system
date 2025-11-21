# 🚂 Railway Deployment - Step by Step

## ⏱️ เวลาที่ใช้: 5-10 นาที

---

## 📋 ขั้นตอนที่ 1: เตรียม Repository (ทำแล้ว ✅)

ไฟล์ที่เตรียมไว้แล้ว:
- ✅ `backend/package.json` - มี start script
- ✅ `backend/railway.json` - Railway config
- ✅ `backend/.railwayignore` - ไฟล์ที่ไม่ต้อง deploy
- ✅ `backend/.env.railway` - Template environment variables

---

## 📋 ขั้นตอนที่ 2: Push Code ไป GitHub (ถ้ายังไม่ได้ทำ)

```bash
# 1. Initialize git (ถ้ายังไม่ได้ทำ)
git init
git add .
git commit -m "Prepare for Railway deployment"

# 2. Create GitHub repository
# ไปที่ https://github.com/new
# สร้าง repository ชื่อ "earthquake-app"

# 3. Push code
git remote add origin https://github.com/YOUR_USERNAME/earthquake-app.git
git branch -M main
git push -u origin main
```

---

## 📋 ขั้นตอนที่ 3: Deploy บน Railway

### 3.1 สมัคร Railway (ถ้ายังไม่มี account)

1. ไปที่ https://railway.app
2. คลิก "Login with GitHub"
3. Authorize Railway

### 3.2 สร้าง Project ใหม่

1. คลิก "New Project"
2. เลือก "Deploy from GitHub repo"
3. **รอให้โหลด repositories เสร็จ** (ตรงนี้อาจใช้เวลา 1-2 นาที)
4. เลือก repository ของคุณ
5. เลือก `backend` folder (ถ้ามีให้เลือก)

### 3.3 ตั้งค่า Environment Variables

คลิกที่ "Variables" แล้วเพิ่ม:

```
NODE_ENV=production
PORT=3000
API_VERSION=v1
MONGODB_URI=mongodb://localhost:27017/eqnode_prod
JWT_SECRET=your-random-secret-key-here-change-this
JWT_EXPIRES_IN=7d
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_railway
ALLOWED_ORIGINS=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

**สำคัญ:** เปลี่ยน `JWT_SECRET` เป็นค่าที่ปลอดภัย:
```bash
# Generate random secret
openssl rand -base64 32
```

### 3.4 Deploy

1. Railway จะ auto-deploy ทันที
2. รอ 2-3 นาที
3. ดู logs ว่า deploy สำเร็จหรือไม่

### 3.5 ได้ URL

1. คลิกที่ "Settings"
2. คลิก "Generate Domain"
3. ได้ URL: `https://your-app-name.up.railway.app`

---

## 📋 ขั้นตอนที่ 4: ทดสอบ Server

```bash
# ทดสอบ health check
curl https://your-app-name.up.railway.app/health

# ควรได้:
{
  "success": true,
  "status": "healthy",
  "mqtt": "connected",
  "version": "v1"
}
```

---

## 📋 ขั้นตอนที่ 5: Update Flutter App

แก้ไข `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://localhost:3000/api/v1';
    case Environment.staging:
      return 'https://your-app-name.up.railway.app/api/v1'; // ⬅️ เปลี่ยนตรงนี้
    case Environment.production:
      return 'https://your-app-name.up.railway.app/api/v1'; // ⬅️ เปลี่ยนตรงนี้
  }
}
```

---

## 📋 ขั้นตอนที่ 6: Rebuild Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎉 เสร็จแล้ว!

ตอนนี้คุณมี:
- ✅ Production server บน Railway
- ✅ HTTPS อัตโนมัติ
- ✅ Auto-deploy จาก GitHub
- ✅ MQTT เชื่อมต่อ
- ✅ Flutter app เชื่อมต่อ production server

---

## 🐛 Troubleshooting

### ปัญหา: Railway โหลดนาน

**สาเหตุ:**
- GitHub API rate limit
- Network ช้า
- Repository มีขนาดใหญ่

**วิธีแก้:**
1. รอสักครู่ (1-2 นาที)
2. Refresh หน้าเว็บ
3. ลอง logout/login ใหม่

### ปัญหา: Deploy ล้มเหลว

**ตรวจสอบ:**
1. ดู logs ใน Railway dashboard
2. ตรวจสอบ package.json มี start script
3. ตรวจสอบ environment variables ครบ

### ปัญหา: MQTT ไม่เชื่อมต่อ

**ตรวจสอบ:**
1. Environment variables ถูกต้อง
2. MQTT credentials ถูกต้อง
3. ดู logs: `MQTT Connected` หรือไม่

---

## 💡 Tips

### 1. ใช้ MongoDB Atlas (Free)

Railway ไม่มี MongoDB built-in ให้ใช้ MongoDB Atlas:

1. ไปที่ https://cloud.mongodb.com
2. สมัคร free tier
3. สร้าง cluster
4. ได้ connection string
5. เพิ่มใน Railway variables: `MONGODB_URI`

### 2. ดู Logs Real-time

```
Railway Dashboard → Deployments → View Logs
```

### 3. Auto-deploy

ทุกครั้งที่ push code ไป GitHub, Railway จะ auto-deploy ให้อัตโนมัติ

---

## 🎯 สรุป

**ขั้นตอนสั้นๆ:**
1. ⏳ รอ Railway โหลด repositories (1-2 นาที)
2. ✅ เลือก repository
3. ✅ ตั้งค่า environment variables
4. ✅ Deploy (auto)
5. ✅ ได้ URL
6. ✅ Update Flutter app
7. ✅ Test!

**ตอนนี้:** รอให้ Railway โหลดเสร็จ แล้วเลือก repository ของคุณ

---

**Last Updated**: November 21, 2025
