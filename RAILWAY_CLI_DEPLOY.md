# 🚂 Deploy ด้วย Railway CLI (วิธีเร็ว)

## ⚡ ข้อดี
- ✅ ไม่ต้องรอ GitHub UI โหลด
- ✅ Deploy ได้ทันที
- ✅ ควบคุมได้มากกว่า
- ✅ ใช้เวลาแค่ 5 นาที

---

## 📋 ขั้นตอนที่ 1: ติดตั้ง Railway CLI

### macOS (ใช้ Homebrew):
```bash
brew install railway
```

### หรือใช้ npm:
```bash
npm install -g @railway/cli
```

### ตรวจสอบการติดตั้ง:
```bash
railway --version
```

---

## 📋 ขั้นตอนที่ 2: Login Railway

```bash
railway login
```

- จะเปิด browser ให้ login ด้วย GitHub
- กลับมาที่ terminal จะเห็น "Logged in as [your-email]"

---

## 📋 ขั้นตอนที่ 3: สร้าง Project

```bash
# ไปที่ folder backend
cd backend

# สร้าง project ใหม่
railway init

# ตั้งชื่อ project: "earthquake-backend"
```

---

## 📋 ขั้นตอนที่ 4: ตั้งค่า Environment Variables

```bash
# ตั้งค่าทีละตัว
railway variables set NODE_ENV=production
railway variables set PORT=3000
railway variables set API_VERSION=v1

# MQTT
railway variables set MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
railway variables set MQTT_USERNAME=ethernet
railway variables set MQTT_PASSWORD=ei8jZz87wx
railway variables set MQTT_CLIENT_ID=eqnode_backend_railway

# JWT (สร้าง secret key ใหม่)
railway variables set JWT_SECRET=$(openssl rand -base64 32)
railway variables set JWT_EXPIRES_IN=7d

# CORS
railway variables set ALLOWED_ORIGINS=*

# Rate Limiting
railway variables set RATE_LIMIT_WINDOW_MS=900000
railway variables set RATE_LIMIT_MAX_REQUESTS=100
```

### หรือตั้งค่าทั้งหมดพร้อมกัน:
```bash
railway variables set \
  NODE_ENV=production \
  PORT=3000 \
  API_VERSION=v1 \
  MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883 \
  MQTT_USERNAME=ethernet \
  MQTT_PASSWORD=ei8jZz87wx \
  MQTT_CLIENT_ID=eqnode_backend_railway \
  JWT_SECRET=$(openssl rand -base64 32) \
  JWT_EXPIRES_IN=7d \
  ALLOWED_ORIGINS=* \
  RATE_LIMIT_WINDOW_MS=900000 \
  RATE_LIMIT_MAX_REQUESTS=100
```

---

## 📋 ขั้นตอนที่ 5: Deploy

```bash
# Deploy ทันที
railway up

# รอ 2-3 นาที
# จะเห็น progress bar และ logs
```

---

## 📋 ขั้นตอนที่ 6: สร้าง Public URL

```bash
# สร้าง domain
railway domain

# จะได้ URL: https://earthquake-backend-production.up.railway.app
```

---

## 📋 ขั้นตอนที่ 7: ทดสอบ

```bash
# ดู logs
railway logs

# ทดสอบ API
curl https://your-app.up.railway.app/health
```

---

## 🎯 คำสั่งที่ใช้บ่อย

```bash
# ดู logs real-time
railway logs -f

# ดู environment variables
railway variables

# Redeploy
railway up

# เปิด dashboard
railway open

# ดู status
railway status

# Link กับ project ที่มีอยู่
railway link

# Unlink project
railway unlink
```

---

## 🐛 Troubleshooting

### ปัญหา: railway command not found

**วิธีแก้:**
```bash
# ติดตั้งใหม่
npm install -g @railway/cli

# หรือ
brew install railway
```

### ปัญหา: Login ไม่ได้

**วิธีแก้:**
```bash
# Logout แล้ว login ใหม่
railway logout
railway login
```

### ปัญหา: Deploy ล้มเหลว

**วิธีแก้:**
```bash
# ดู logs
railway logs

# ตรวจสอบ package.json มี start script
cat package.json | grep "start"

# ตรวจสอบ environment variables
railway variables
```

---

## 📱 Update Flutter App

หลัง deploy เสร็จ ให้แก้ไข `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://localhost:3000/api/v1';
    case Environment.staging:
      return 'https://earthquake-backend-production.up.railway.app/api/v1';
    case Environment.production:
      return 'https://earthquake-backend-production.up.railway.app/api/v1';
  }
}
```

---

## 🎉 เสร็จแล้ว!

ตอนนี้คุณมี:
- ✅ Production server บน Railway
- ✅ HTTPS อัตโนมัติ
- ✅ Public URL
- ✅ MQTT เชื่อมต่อ
- ✅ Deploy ด้วย CLI

---

## 💡 Tips

### 1. Auto-deploy จาก Git

```bash
# Link กับ GitHub repo
railway link

# ทุกครั้งที่ push code จะ auto-deploy
git push origin main
```

### 2. ใช้ .env file

```bash
# สร้าง .env.railway
cat > .env.railway << 'EOF'
NODE_ENV=production
PORT=3000
# ... variables อื่นๆ
EOF

# Import variables
railway variables set < .env.railway
```

### 3. Multiple Environments

```bash
# สร้าง staging environment
railway environment create staging

# Switch environment
railway environment staging

# Deploy to staging
railway up
```

---

## 🔄 Update Code

```bash
# 1. แก้ไข code
# 2. Commit
git add .
git commit -m "Update feature"

# 3. Deploy
railway up

# หรือถ้า link กับ GitHub แล้ว
git push origin main  # จะ auto-deploy
```

---

## 📊 Monitor

```bash
# ดู logs real-time
railway logs -f

# ดู metrics
railway open  # เปิด dashboard

# ดู deployments
railway deployments
```

---

**Last Updated**: November 21, 2025
**Status**: ✅ Ready to Use
