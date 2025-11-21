# ✅ Pre-Deployment Checklist

## 📋 สิ่งที่ต้องเตรียมก่อน Deploy ไป Railway

---

## 1️⃣ Database (MongoDB) - **จำเป็น**

### ปัญหา:
- Railway ไม่มี MongoDB built-in
- ตอนนี้ใช้ `mongodb://localhost:27017` (ใช้ได้แค่ local)

### วิธีแก้:

#### Option A: MongoDB Atlas (แนะนำ - ฟรี)

1. **สมัคร MongoDB Atlas**:
   - ไปที่: https://cloud.mongodb.com
   - สมัครด้วย Google/GitHub (ฟรี)

2. **สร้าง Cluster**:
   - เลือก **FREE** tier (M0 Sandbox)
   - เลือก region ใกล้ที่สุด (Singapore)
   - ตั้งชื่อ cluster: `earthquake-cluster`

3. **สร้าง Database User**:
   - Username: `eqnode_admin`
   - Password: สร้างรหัสผ่านที่ปลอดภัย (เก็บไว้)

4. **ตั้งค่า Network Access**:
   - คลิก "Add IP Address"
   - เลือก "Allow Access from Anywhere" (0.0.0.0/0)
   - (สำหรับ Railway ที่ IP เปลี่ยนได้)

5. **ได้ Connection String**:
   ```
   mongodb+srv://eqnode_admin:<password>@earthquake-cluster.xxxxx.mongodb.net/eqnode_prod
   ```

6. **เพิ่มใน Railway Variables**:
   ```bash
   railway variables set MONGODB_URI="mongodb+srv://eqnode_admin:YOUR_PASSWORD@earthquake-cluster.xxxxx.mongodb.net/eqnode_prod"
   ```

#### Option B: Railway MongoDB Plugin

```bash
# เพิ่ม MongoDB plugin ใน Railway
railway add mongodb

# Railway จะสร้าง MONGODB_URI ให้อัตโนมัติ
```

**ข้อเสีย**: ไม่ฟรี (ประมาณ $5/month)

---

## 2️⃣ Firebase (Push Notifications) - **Optional แต่แนะนำ**

### ปัญหา:
- ตอนนี้ใช้ mock notifications
- ไม่มี `serviceAccountKey.json`

### วิธีแก้:

#### ถ้าต้องการ Push Notifications:

1. **สร้าง Firebase Project**:
   - ไปที่: https://console.firebase.google.com
   - คลิก "Add project"
   - ตั้งชื่อ: `earthquake-alert-system`

2. **ดาวน์โหลด Service Account Key**:
   - Project Settings → Service accounts
   - คลิก "Generate new private key"
   - ได้ไฟล์ JSON

3. **เพิ่มใน Railway**:
   
   **วิธีที่ 1: ใช้ Environment Variable (แนะนำ)**
   ```bash
   # แปลง JSON เป็น base64
   cat serviceAccountKey.json | base64 > firebase-key-base64.txt
   
   # เพิ่มใน Railway
   railway variables set FIREBASE_SERVICE_ACCOUNT_BASE64="<paste-base64-here>"
   ```
   
   **วิธีที่ 2: ใช้ Railway Volumes**
   - Upload ไฟล์ผ่าน Railway dashboard
   - Mount ที่ `/app/serviceAccountKey.json`

4. **Update Code** (ถ้าใช้ base64):
   ```javascript
   // backend/src/services/notificationService.js
   const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
   if (serviceAccountBase64) {
     const serviceAccount = JSON.parse(
       Buffer.from(serviceAccountBase64, 'base64').toString('utf-8')
     );
     admin.initializeApp({
       credential: admin.credential.cert(serviceAccount),
     });
   }
   ```

#### ถ้าไม่ต้องการ Push Notifications (ตอนนี้):
- ✅ ไม่ต้องทำอะไร
- ระบบจะใช้ mock notifications
- ยังทำงานได้ปกติ แค่ไม่มีการแจ้งเตือนจริง

---

## 3️⃣ Environment Variables - **จำเป็น**

### ตั้งค่าใน Railway:

```bash
# Server
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database (จาก MongoDB Atlas)
MONGODB_URI=mongodb+srv://eqnode_admin:PASSWORD@cluster.mongodb.net/eqnode_prod

# JWT (สร้างใหม่)
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRES_IN=7d

# MQTT (ใช้ค่าเดิม)
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_railway

# CORS
ALLOWED_ORIGINS=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Firebase (optional)
FIREBASE_PROJECT_ID=earthquake-alert-system
FIREBASE_SERVICE_ACCOUNT_BASE64=<base64-encoded-json>
```

---

## 4️⃣ Domain/IP - **Railway จัดการให้**

### ไม่ต้องทำอะไร:
- ✅ Railway สร้าง domain ให้อัตโนมัติ
- ✅ HTTPS ให้ฟรี
- ✅ ได้ URL: `https://your-app.up.railway.app`

---

## 5️⃣ Flutter App Configuration - **ต้องแก้หลัง Deploy**

### หลัง Deploy เสร็จ:

```dart
// lib/config/app_config.dart
static String get baseUrl {
  switch (_environment) {
    case Environment.production:
      return 'https://your-app.up.railway.app/api/v1'; // ⬅️ เปลี่ยนตรงนี้
  }
}
```

---

## 📊 สรุป: ต้องทำอะไรบ้าง?

### ✅ ทำก่อน Deploy (จำเป็น):

1. **MongoDB Atlas**:
   - [ ] สมัคร MongoDB Atlas
   - [ ] สร้าง cluster (ฟรี)
   - [ ] ได้ connection string
   - [ ] เพิ่มใน Railway variables

### 🔶 ทำก่อน Deploy (Optional):

2. **Firebase** (ถ้าต้องการ push notifications):
   - [ ] สร้าง Firebase project
   - [ ] ดาวน์โหลด service account key
   - [ ] แปลงเป็น base64
   - [ ] เพิ่มใน Railway variables

### ✅ ทำหลัง Deploy:

3. **Update Flutter App**:
   - [ ] เปลี่ยน API URL
   - [ ] Rebuild app
   - [ ] ทดสอบ

---

## 🚀 Quick Setup (5-10 นาที)

### ถ้าต้องการ Deploy เร็วที่สุด:

```bash
# 1. Setup MongoDB Atlas (5 นาที)
# - ไปที่ https://cloud.mongodb.com
# - สมัคร → สร้าง cluster → ได้ connection string

# 2. Deploy ด้วย Railway CLI
cd backend
railway login
railway init

# 3. ตั้งค่า variables
railway variables set \
  NODE_ENV=production \
  PORT=3000 \
  MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/db" \
  MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883 \
  MQTT_USERNAME=ethernet \
  MQTT_PASSWORD=ei8jZz87wx \
  JWT_SECRET=$(openssl rand -base64 32)

# 4. Deploy
railway up

# 5. สร้าง domain
railway domain

# เสร็จ! ได้ URL
```

---

## 🎯 แนะนำสำหรับคุณ

### ตอนนี้ (MVP/Testing):

**MongoDB**: ✅ ใช้ MongoDB Atlas (ฟรี)
- เพียงพอสำหรับทดสอบ
- Setup ง่าย 5 นาที
- ไม่ต้องจ่ายเงิน

**Firebase**: ⚠️ ข้ามไปก่อน
- ใช้ mock notifications ไปก่อน
- ระบบยังทำงานได้ปกติ
- ค่อยเพิ่มทีหลังเมื่อต้องการ push notifications จริง

### ภายหลัง (Production):

**MongoDB**: อัพเกรดเป็น paid tier ถ้าจำเป็น
**Firebase**: เพิ่ม push notifications

---

## 🐛 Troubleshooting

### ถ้า Deploy แล้วเจอ Error:

#### "Cannot connect to database"
```bash
# ตรวจสอบ MONGODB_URI
railway variables | grep MONGODB_URI

# ทดสอบ connection string
mongosh "mongodb+srv://user:pass@cluster.mongodb.net/db"
```

#### "MQTT connection failed"
```bash
# ตรวจสอบ MQTT variables
railway variables | grep MQTT

# ทดสอบ MQTT
mosquitto_sub -h mqtt.uiot.cloud -p 1883 -u ethernet -P "ei8jZz87wx" -t "#"
```

#### "Firebase not initialized"
```bash
# ไม่เป็นไร - ระบบจะใช้ mock notifications
# ดู logs
railway logs
```

---

## 📝 Next Steps

1. **ตอนนี้**: Setup MongoDB Atlas (5 นาที)
2. **Deploy**: ใช้ Railway CLI (5 นาที)
3. **Test**: ทดสอบ API endpoints
4. **Update**: แก้ Flutter app config
5. **ภายหลัง**: เพิ่ม Firebase ถ้าต้องการ

---

**คุณพร้อม Deploy แล้วหรือยัง?**

- ✅ ถ้าพร้อม: ไปที่ขั้นตอน "Setup MongoDB Atlas" ก่อน
- ⚠️ ถ้ายังไม่พร้อม: บอกผมว่าต้องการความช่วยเหลือตรงไหน

---

**Last Updated**: November 21, 2025
