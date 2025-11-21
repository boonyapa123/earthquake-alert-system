# 🚀 Production Server Deployment Guide

## 📋 สถานะปัจจุบัน

### ✅ Backend พร้อมใช้งาน
- ✅ Server รันที่ `http://localhost:3000`
- ✅ MQTT เชื่อมต่อ `mqtt.uiot.cloud:1883`
- ✅ API endpoints พร้อมใช้งาน
- ✅ Database schema พร้อม

### 🎯 เป้าหมาย
สร้าง production server ที่:
1. เข้าถึงได้จากภายนอก (public IP/domain)
2. ปลอดภัย (HTTPS, authentication)
3. มีประสิทธิภาพ (caching, load balancing)
4. พร้อม scale (Docker, cloud deployment)

---

## 🏗️ Option 1: Deploy บน VPS (แนะนำ)

### ขั้นตอนที่ 1: เลือก VPS Provider

**แนะนำ:**
- **DigitalOcean** - $6/month (1GB RAM, 25GB SSD)
- **Linode** - $5/month (1GB RAM, 25GB SSD)
- **AWS Lightsail** - $5/month (512MB RAM, 20GB SSD)
- **Vultr** - $6/month (1GB RAM, 25GB SSD)

**Specs แนะนำ:**
- RAM: 1-2GB
- CPU: 1-2 cores
- Storage: 25-50GB SSD
- OS: Ubuntu 22.04 LTS

### ขั้นตอนที่ 2: Setup Server

```bash
# 1. SSH เข้า server
ssh root@your-server-ip

# 2. Update system
apt update && apt upgrade -y

# 3. ติดตั้ง Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 4. ติดตั้ง Docker Compose
apt install docker-compose -y

# 5. ติดตั้ง Git
apt install git -y

# 6. สร้าง user สำหรับ deploy
adduser eqnode
usermod -aG docker eqnode
usermod -aG sudo eqnode

# 7. Switch to eqnode user
su - eqnode
```

### ขั้นตอนที่ 3: Deploy Backend

```bash
# 1. Clone repository
cd ~
git clone https://github.com/your-username/earthquake_app_new2.git
cd earthquake_app_new2/backend

# 2. สร้าง .env สำหรับ production
cat > .env << 'EOF'
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database (MongoDB)
MONGODB_URI=mongodb://mongodb:27017/eqnode_prod

# JWT Secret (เปลี่ยนเป็นค่าที่ปลอดภัย)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# MQTT Configuration
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_prod

# CORS
ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Firebase (optional)
FIREBASE_PROJECT_ID=your-firebase-project-id
EOF

# 3. Build และรัน Docker
docker-compose up -d

# 4. ตรวจสอบ logs
docker-compose logs -f api
```

### ขั้นตอนที่ 4: Setup Nginx (Reverse Proxy)

```bash
# 1. ติดตั้ง Nginx
sudo apt install nginx -y

# 2. สร้าง config
sudo nano /etc/nginx/sites-available/eqnode

# เพิ่มเนื้อหา:
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 3. Enable site
sudo ln -s /etc/nginx/sites-available/eqnode /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### ขั้นตอนที่ 5: Setup SSL (HTTPS)

```bash
# 1. ติดตั้ง Certbot
sudo apt install certbot python3-certbot-nginx -y

# 2. ขอ SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 3. Auto-renewal
sudo certbot renew --dry-run
```

### ขั้นตอนที่ 6: Setup Firewall

```bash
# 1. Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# 2. ตรวจสอบ status
sudo ufw status
```

---

## 🏗️ Option 2: Deploy บน Railway (ง่ายที่สุด)

### ขั้นตอน:

1. **สมัคร Railway**: https://railway.app
2. **Connect GitHub**: เชื่อมต่อ repository
3. **Deploy Backend**:
   - New Project → Deploy from GitHub
   - เลือก repository
   - เลือก `backend` folder
   - Railway จะ auto-detect และ deploy

4. **ตั้งค่า Environment Variables**:
   ```
   NODE_ENV=production
   MONGODB_URI=<railway-mongodb-url>
   JWT_SECRET=<your-secret>
   MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
   MQTT_USERNAME=ethernet
   MQTT_PASSWORD=ei8jZz87wx
   ```

5. **ได้ URL**: `https://your-app.railway.app`

**ข้อดี:**
- ✅ ฟรี $5/month credit
- ✅ Auto-deploy จาก GitHub
- ✅ HTTPS ให้อัตโนมัติ
- ✅ ไม่ต้องจัดการ server

**ข้อเสีย:**
- ⚠️ จำกัด resources
- ⚠️ Cold start (ถ้าไม่มีคนใช้)

---

## 🏗️ Option 3: Deploy บน Heroku

### ขั้นตอน:

```bash
# 1. ติดตั้ง Heroku CLI
brew install heroku/brew/heroku

# 2. Login
heroku login

# 3. สร้าง app
cd backend
heroku create eqnode-api

# 4. Add MongoDB
heroku addons:create mongolab:sandbox

# 5. ตั้งค่า environment variables
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=your-secret-key
heroku config:set MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
heroku config:set MQTT_USERNAME=ethernet
heroku config:set MQTT_PASSWORD=ei8jZz87wx

# 6. Deploy
git push heroku main

# 7. ตรวจสอบ
heroku logs --tail
heroku open
```

---

## 🏗️ Option 4: Deploy บน AWS (Professional)

### ขั้นตอนสรุป:

1. **EC2 Instance**: Ubuntu 22.04, t2.micro (free tier)
2. **RDS**: MongoDB Atlas (free tier)
3. **Elastic IP**: Static IP address
4. **Route 53**: Domain management
5. **CloudFront**: CDN (optional)
6. **S3**: Static files (optional)

**ค่าใช้จ่าย:** ~$10-20/month

---

## 📱 Update Flutter App Config

หลังจาก deploy server แล้ว ให้แก้ไข `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://localhost:3000/api/v1';
    case Environment.staging:
      return 'https://staging-api.your-domain.com/api/v1';
    case Environment.production:
      return 'https://api.your-domain.com/api/v1'; // ⬅️ เปลี่ยนตรงนี้
  }
}
```

---

## 🧪 ทดสอบ Production Server

### 1. ทดสอบ Health Check

```bash
curl https://api.your-domain.com/health
```

**ผลลัพธ์ที่คาดหวัง:**
```json
{
  "success": true,
  "status": "healthy",
  "mqtt": "connected",
  "version": "v1"
}
```

### 2. ทดสอบ Login

```bash
curl -X POST https://api.your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@eqnode.com",
    "password": "password123"
  }'
```

### 3. ทดสอบ MQTT

```bash
# ใน backend server
node test-mqtt-connection.js
```

---

## 🔒 Security Checklist

### ก่อน Deploy Production:

- [ ] เปลี่ยน JWT_SECRET เป็นค่าที่ปลอดภัย
- [ ] ตั้งค่า CORS ให้ถูกต้อง
- [ ] Enable HTTPS (SSL certificate)
- [ ] ตั้งค่า Rate Limiting
- [ ] ตั้งค่า Firewall
- [ ] Backup database
- [ ] ตั้งค่า monitoring (optional)
- [ ] ตั้งค่า logging (optional)

---

## 📊 Monitoring & Maintenance

### 1. ตรวจสอบ Server Status

```bash
# CPU & Memory
htop

# Disk usage
df -h

# Docker containers
docker ps
docker stats

# Logs
docker-compose logs -f api
```

### 2. Backup Database

```bash
# MongoDB backup
docker-compose exec mongodb mongodump --out /backup

# Copy to local
docker cp mongodb:/backup ./backup-$(date +%Y%m%d)
```

### 3. Update Code

```bash
# Pull latest code
git pull origin main

# Rebuild
docker-compose down
docker-compose up -d --build

# Check logs
docker-compose logs -f api
```

---

## 💰 ค่าใช้จ่ายประมาณ

| Option | ค่าใช้จ่าย/เดือน | ความยาก | แนะนำสำหรับ |
|--------|-----------------|---------|-------------|
| **Railway** | $0-5 | ⭐ | ทดสอบ, MVP |
| **Heroku** | $7 | ⭐⭐ | Startup |
| **DigitalOcean** | $6 | ⭐⭐⭐ | Production |
| **AWS** | $10-20 | ⭐⭐⭐⭐ | Enterprise |

---

## 🎯 แนะนำสำหรับคุณ

### สำหรับการทดสอบ (ตอนนี้):
**→ Railway** หรือ **Heroku**
- ✅ Setup ง่าย (10-15 นาที)
- ✅ ฟรีหรือราคาถูก
- ✅ HTTPS อัตโนมัติ
- ✅ ไม่ต้องจัดการ server

### สำหรับ Production จริง:
**→ DigitalOcean** หรือ **Linode**
- ✅ ราคาคุ้มค่า ($6/month)
- ✅ Performance ดี
- ✅ Control เต็มรูปแบบ
- ✅ Scale ได้ง่าย

---

## 🚀 Quick Start (Railway - แนะนำ)

### 5 นาทีได้ Production Server:

1. **สมัคร Railway**: https://railway.app (ใช้ GitHub login)

2. **New Project** → **Deploy from GitHub**

3. **เลือก repository** → `earthquake_app_new2`

4. **Add Environment Variables**:
   ```
   NODE_ENV=production
   JWT_SECRET=your-random-secret-key-here
   MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
   MQTT_USERNAME=ethernet
   MQTT_PASSWORD=ei8jZz87wx
   PORT=3000
   ```

5. **Deploy** → รอ 2-3 นาที

6. **ได้ URL**: `https://earthquake-app-production.up.railway.app`

7. **Update Flutter**:
   ```dart
   return 'https://earthquake-app-production.up.railway.app/api/v1';
   ```

8. **Done!** 🎉

---

## 📝 Next Steps

หลังจาก deploy แล้ว:

1. ✅ ทดสอบ API endpoints
2. ✅ ทดสอบ MQTT connection
3. ✅ ทดสอบ Flutter app กับ production server
4. ✅ ส่งข้อมูลทดสอบ (test-sensor-types.js)
5. ✅ ตรวจสอบการแยกกลุ่มเซ็นเซอร์
6. ✅ ทดสอบการแจ้งเตือน

---

**คุณต้องการให้ผมช่วย deploy แบบไหนครับ?**

1. **Railway** (ง่ายที่สุด, 5-10 นาที)
2. **DigitalOcean** (production-ready, 30-60 นาที)
3. **Heroku** (กลางๆ, 15-20 นาที)

---

**Last Updated**: November 21, 2025
**Status**: ✅ Ready to Deploy
