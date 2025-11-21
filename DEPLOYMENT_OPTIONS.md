# 🚀 ตัวเลือกการ Deploy Backend

## ปัญหาปัจจุบัน
- Backend URL: `http://10.134.94.222:3000/api/v1`
- ใช้ได้เฉพาะใน WiFi เดียวกันเท่านั้น
- ไม่สามารถใช้งานผ่าน 4G/5G ได้

---

## ✅ วิธีแก้ไข: Deploy Backend ไปบน Cloud

### **ตัวเลือกที่ 1: Railway (ฟรี, ง่ายที่สุด)**

1. สมัคร Railway: https://railway.app
2. เชื่อม GitHub repository
3. Deploy backend โดยอัตโนมัติ
4. ได้ URL: `https://your-app.railway.app`

**ข้อดี:**
- ฟรี 500 ชั่วโมง/เดือน
- Deploy อัตโนมัติจาก Git
- มี PostgreSQL ให้ใช้ฟรี
- Setup ง่าย

### **ตัวเลือกที่ 2: Render (ฟรี)**

1. สมัคร Render: https://render.com
2. เชื่อม GitHub
3. Deploy backend
4. ได้ URL: `https://your-app.onrender.com`

**ข้อดี:**
- ฟรีตลอดไป
- PostgreSQL ฟรี
- Auto-deploy

**ข้อเสีย:**
- Sleep หลัง 15 นาทีไม่ใช้งาน
- ตื่นช้า (30 วินาที)

### **ตัวเลือกที่ 3: Heroku (เสียเงิน)**

1. สมัคร Heroku: https://heroku.com
2. Deploy ผ่าน Git
3. ได้ URL: `https://your-app.herokuapp.com`

**ข้อดี:**
- เสถียร
- ไม่ sleep

**ข้อเสีย:**
- เสียเงิน $7/เดือน

### **ตัวเลือกที่ 4: DigitalOcean / AWS / Google Cloud**

**ข้อดี:**
- ควบคุมได้เต็มที่
- Performance ดี

**ข้อเสีย:**
- ซับซ้อน
- เสียเงิน

---

## 🔧 วิธี Deploy บน Railway (แนะนำ)

### ขั้นตอนที่ 1: เตรียม Backend

```bash
# ไฟล์ที่ต้องมี
backend/
├── package.json
├── Dockerfile (มีอยู่แล้ว)
├── .env (ต้องตั้งค่าบน Railway)
└── src/
```

### ขั้นตอนที่ 2: Deploy

1. ไปที่ https://railway.app
2. Sign in with GitHub
3. New Project → Deploy from GitHub repo
4. เลือก repository นี้
5. เลือก `backend` folder
6. Add PostgreSQL database
7. ตั้งค่า Environment Variables:
   ```
   NODE_ENV=production
   PORT=3000
   DB_HOST=<railway-postgres-host>
   DB_PORT=5432
   DB_NAME=railway
   DB_USER=postgres
   DB_PASSWORD=<railway-generated>
   MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
   MQTT_USERNAME=ethernet
   MQTT_PASSWORD=ei8jZz87wx
   JWT_SECRET=<your-secret>
   ```

8. Deploy!

### ขั้นตอนที่ 3: อัพเดท Flutter App

แก้ไข `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://10.134.94.222:3000/api/v1'; // Local
    case Environment.staging:
      return 'https://your-app.railway.app/api/v1'; // Railway
    case Environment.production:
      return 'https://your-app.railway.app/api/v1'; // Railway
  }
}
```

### ขั้นตอนที่ 4: Build APK ใหม่

```bash
# เปลี่ยนเป็น production mode
# แก้ไข lib/main.dart
AppConfig.setEnvironment(Environment.production);

# Build APK
flutter build apk --release
```

---

## 📱 วิธีใช้งานหลัง Deploy

### สำหรับ Development (WiFi เดียวกัน)
```dart
AppConfig.setEnvironment(Environment.development);
// ใช้ http://10.134.94.222:3000/api/v1
```

### สำหรับ Production (ใช้ได้ทุกที่)
```dart
AppConfig.setEnvironment(Environment.production);
// ใช้ https://your-app.railway.app/api/v1
```

---

## 🔒 Security Checklist สำหรับ Production

- [ ] เปลี่ยน JWT_SECRET เป็นค่าที่ปลอดภัย
- [ ] เปลี่ยน DB_PASSWORD
- [ ] ใช้ HTTPS (Railway ให้ฟรี)
- [ ] ตั้งค่า CORS ให้ถูกต้อง
- [ ] เปิด Firebase Cloud Messaging
- [ ] ตั้งค่า Rate Limiting

---

## 💰 ค่าใช้จ่าย

| Service | ฟรี | เสียเงิน |
|---------|-----|----------|
| Railway | 500 ชม./เดือน | $5/เดือน (unlimited) |
| Render | ไม่จำกัด (มี sleep) | $7/เดือน (no sleep) |
| Heroku | ไม่มี | $7/เดือน |

---

## 🎯 สรุป

**สำหรับทดสอบ:**
- ใช้ WiFi เดียวกัน → ใช้งานได้เลย

**สำหรับใช้งานจริง:**
- Deploy บน Railway (ฟรี 500 ชม./เดือน)
- อัพเดท URL ใน app config
- Build APK ใหม่

---

## 📞 ต้องการความช่วยเหลือ?

ถ้าต้องการให้ช่วย:
1. Deploy backend ไปบน Railway
2. อัพเดท config
3. Build APK production

บอกได้เลยครับ!
