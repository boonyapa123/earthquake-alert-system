# 🌊 DigitalOcean Production Deployment Guide

## 📋 ภาพรวม

คู่มือนี้จะแนะนำการ deploy production server บน DigitalOcean แบบครบถ้วน พร้อมใช้งานจริง

---

## 💰 ค่าใช้จ่าย (ประมาณการ/เดือน)

| รายการ | ราคา | หมายเหตุ |
|--------|------|----------|
| **Droplet** (VPS) | $6 | 1GB RAM, 25GB SSD |
| **MongoDB Atlas** | $0 | Free tier (512MB) |
| **Firebase** | $0 | Free tier |
| **Domain** (optional) | $12/ปี | ถ้าต้องการ custom domain |
| **Backup** (optional) | $1.20 | 20% ของ droplet |
| **รวม** | **~$6-7/เดือน** | |

---

## 📦 สิ่งที่ต้องเตรียม

### 1. บัญชีและบริการ
- [ ] บัญชี DigitalOcean
- [ ] บัญชี MongoDB Atlas (ฟรี)
- [ ] บัญชี Firebase (ฟรี)
- [ ] บัตรเครดิต/เดบิต (สำหรับ DigitalOcean)
- [ ] Domain name (optional)

### 2. ข้อมูลที่ต้องมี
- [ ] GitHub repository URL
- [ ] MQTT credentials (มีแล้ว)
- [ ] SSH key (จะสร้างในขั้นตอน)

---

## 🚀 Part 1: เตรียม Services


### Step 1.1: MongoDB Atlas (Database)

**เวลา: 5-10 นาที**

1. **สมัคร MongoDB Atlas**:
   ```
   https://cloud.mongodb.com
   ```
   - Sign up ด้วย Google/GitHub
   - ฟรี ไม่ต้องใส่บัตร

2. **สร้าง Cluster**:
   - คลิก "Build a Database"
   - เลือก **FREE** (M0 Sandbox)
   - Provider: **AWS**
   - Region: **Singapore** (ap-southeast-1)
   - Cluster Name: `earthquake-cluster`
   - คลิก "Create"

3. **สร้าง Database User**:
   - Security → Database Access
   - คลิก "Add New Database User"
   - Username: `eqnode_admin`
   - Password: สร้างรหัสผ่านที่แข็งแรง (เก็บไว้!)
   - Database User Privileges: **Read and write to any database**
   - คลิก "Add User"

4. **ตั้งค่า Network Access**:
   - Security → Network Access
   - คลิก "Add IP Address"
   - เลือก "Allow Access from Anywhere" (0.0.0.0/0)
   - คลิก "Confirm"

5. **ได้ Connection String**:
   - Database → Connect
   - เลือก "Connect your application"
   - Driver: **Node.js**
   - Version: **5.5 or later**
   - Copy connection string:
   ```
   mongodb+srv://eqnode_admin:<password>@earthquake-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
   - แทนที่ `<password>` ด้วยรหัสผ่านจริง
   - เพิ่ม database name:
   ```
   mongodb+srv://eqnode_admin:YOUR_PASSWORD@earthquake-cluster.xxxxx.mongodb.net/eqnode_prod?retryWrites=true&w=majority
   ```

**เก็บ Connection String ไว้!** จะใช้ในขั้นตอนถัดไป


### Step 1.2: Firebase (Push Notifications)

**เวลา: 10-15 นาที**

1. **สร้าง Firebase Project**:
   ```
   https://console.firebase.google.com
   ```
   - คลิก "Add project"
   - Project name: `earthquake-alert-system`
   - Disable Google Analytics (ไม่จำเป็น)
   - คลิก "Create project"

2. **ดาวน์โหลด Service Account Key**:
   - Project Settings (⚙️) → Service accounts
   - คลิก "Generate new private key"
   - คลิก "Generate key"
   - ได้ไฟล์ JSON (เก็บไว้ในที่ปลอดภัย!)

3. **เตรียม Service Account สำหรับ Server**:
   ```bash
   # แปลง JSON เป็น base64 (เพื่อใส่ใน environment variable)
   cat serviceAccountKey.json | base64 > firebase-key-base64.txt
   
   # เก็บไฟล์ firebase-key-base64.txt ไว้
   ```

4. **Setup Flutter App** (ทำทีหลังหลัง deploy server):
   - Android: ดาวน์โหลด `google-services.json`
   - iOS: ดาวน์โหลด `GoogleService-Info.plist`

**เก็บไฟล์เหล่านี้ไว้:**
- `serviceAccountKey.json`
- `firebase-key-base64.txt`


### Step 1.3: Domain Name (Optional แต่แนะนำ)

**เวลา: 5 นาที + รอ propagation 24 ชม.**

1. **ซื้อ Domain**:
   - Namecheap: https://www.namecheap.com (~$10/ปี)
   - GoDaddy: https://www.godaddy.com
   - หรือซื้อผ่าน DigitalOcean เลย

2. **ตัวอย่าง Domain**:
   - `earthquake-alert.com`
   - `eqnode.app`
   - `your-name-earthquake.com`

3. **ตั้งค่า DNS** (ทำหลังสร้าง Droplet):
   - จะได้ IP address จาก DigitalOcean
   - ตั้งค่า A record ชี้ไปที่ IP นั้น

**ถ้าไม่มี Domain**: ใช้ IP address ตรงๆ ก็ได้ (เช่น `http://123.45.67.89`)

---

## 🚀 Part 2: สร้าง DigitalOcean Droplet

**เวลา: 10-15 นาที**


### Step 2.1: สมัคร DigitalOcean

1. **สมัครบัญชี**:
   ```
   https://www.digitalocean.com
   ```
   - Sign up ด้วย email
   - ใส่บัตรเครดิต/เดบิต
   - ได้ credit $200 (ใช้ได้ 60 วัน)

2. **Verify Email**: ตรวจสอบ email และ verify

### Step 2.2: สร้าง SSH Key

```bash
# สร้าง SSH key ใหม่
ssh-keygen -t ed25519 -C "your-email@example.com"

# กด Enter 3 ครั้ง (ใช้ค่า default)
# ได้ไฟล์:
# - ~/.ssh/id_ed25519 (private key - เก็บไว้)
# - ~/.ssh/id_ed25519.pub (public key - จะใช้ใน DigitalOcean)

# แสดง public key
cat ~/.ssh/id_ed25519.pub
```

Copy public key ที่ได้ (ขึ้นต้นด้วย `ssh-ed25519`)

### Step 2.3: สร้าง Droplet

1. **คลิก "Create" → "Droplets"**

2. **เลือก Image**:
   - Distribution: **Ubuntu**
   - Version: **22.04 (LTS) x64**

3. **เลือก Plan**:
   - Droplet Type: **Basic**
   - CPU options: **Regular**
   - Size: **$6/month** (1GB RAM, 1 CPU, 25GB SSD, 1TB transfer)

4. **เลือก Datacenter**:
   - Region: **Singapore** (SGP1)
   - หรือ **Bangkok** ถ้ามี

5. **Authentication**:
   - เลือก **SSH Key**
   - คลิก "New SSH Key"
   - Paste public key ที่ copy ไว้
   - ตั้งชื่อ: `my-macbook` หรืออะไรก็ได้
   - คลิก "Add SSH Key"

6. **Finalize Details**:
   - Hostname: `earthquake-api-server`
   - Tags: `production`, `api`
   - Backups: เลือก **Enable** ($1.20/month - แนะนำ)

7. **คลิก "Create Droplet"**

8. **รอ 1-2 นาที** จะได้ IP address

**เก็บ IP Address ไว้!** เช่น `123.45.67.89`


---

## 🚀 Part 3: Setup Server

**เวลา: 20-30 นาที**

### Step 3.1: เชื่อมต่อ Server

```bash
# SSH เข้า server (แทน IP ด้วย IP จริง)
ssh root@123.45.67.89

# ถ้าถาม "Are you sure you want to continue connecting?"
# พิมพ์ yes แล้ว Enter
```

### Step 3.2: Update System

```bash
# Update package list
apt update

# Upgrade packages
apt upgrade -y

# ใช้เวลา 5-10 นาที
```

### Step 3.3: ติดตั้ง Docker

```bash
# ติดตั้ง Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# ติดตั้ง Docker Compose
apt install docker-compose -y

# ตรวจสอบ
docker --version
docker-compose --version
```

### Step 3.4: ติดตั้ง Tools อื่นๆ

```bash
# Git
apt install git -y

# Nginx (reverse proxy)
apt install nginx -y

# Certbot (SSL certificate)
apt install certbot python3-certbot-nginx -y

# UFW (firewall)
apt install ufw -y
```


### Step 3.5: สร้าง User สำหรับ Deploy

```bash
# สร้าง user ใหม่
adduser eqnode

# ตั้งรหัสผ่าน (เก็บไว้!)
# กด Enter ข้าม Full Name, Room Number, etc.

# เพิ่ม sudo privileges
usermod -aG sudo eqnode

# เพิ่มเข้า docker group
usermod -aG docker eqnode

# Switch to eqnode user
su - eqnode
```

### Step 3.6: Setup SSH Key สำหรับ eqnode user

```bash
# สร้าง .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copy authorized_keys จาก root
sudo cp /root/.ssh/authorized_keys ~/.ssh/
sudo chown eqnode:eqnode ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# ทดสอบ SSH (เปิด terminal ใหม่)
# ssh eqnode@123.45.67.89
```

---

## 🚀 Part 4: Deploy Backend

**เวลา: 15-20 นาที**

### Step 4.1: Clone Repository

```bash
# SSH เข้า server เป็น eqnode user
ssh eqnode@123.45.67.89

# Clone repository
cd ~
git clone https://github.com/YOUR_USERNAME/earthquake_app_new2.git
cd earthquake_app_new2/backend
```


### Step 4.2: สร้าง Production Environment File

```bash
# สร้าง .env.production
cat > .env.production << 'EOF'
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database (MongoDB Atlas)
MONGODB_URI=mongodb+srv://eqnode_admin:YOUR_PASSWORD@earthquake-cluster.xxxxx.mongodb.net/eqnode_prod?retryWrites=true&w=majority

# JWT Secret (สร้างใหม่)
JWT_SECRET=CHANGE_THIS_TO_RANDOM_SECRET
JWT_EXPIRES_IN=7d

# MQTT Configuration
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_prod

# CORS (เปลี่ยนเป็น domain จริง)
ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Firebase
FIREBASE_PROJECT_ID=earthquake-alert-system
FIREBASE_SERVICE_ACCOUNT_BASE64=YOUR_BASE64_KEY_HERE
EOF

# แก้ไขค่าต่างๆ
nano .env.production
```

**แก้ไขค่าเหล่านี้:**
1. `MONGODB_URI`: ใส่ connection string จาก MongoDB Atlas
2. `JWT_SECRET`: สร้างใหม่ด้วย `openssl rand -base64 32`
3. `ALLOWED_ORIGINS`: ใส่ domain หรือ IP ของคุณ
4. `FIREBASE_SERVICE_ACCOUNT_BASE64`: ใส่ base64 key จาก Firebase

**บันทึก**: Ctrl+O, Enter, Ctrl+X


### Step 4.3: สร้าง Docker Compose สำหรับ Production

```bash
# สร้าง docker-compose.prod.yml
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  api:
    build: .
    container_name: eqnode-api-prod
    restart: unless-stopped
    env_file:
      - .env.production
    ports:
      - "3000:3000"
    networks:
      - eqnode-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  eqnode-network:
    driver: bridge
EOF
```

### Step 4.4: Build และ Run

```bash
# Build Docker image
docker-compose -f docker-compose.prod.yml build

# Run container
docker-compose -f docker-compose.prod.yml up -d

# ตรวจสอบ logs
docker-compose -f docker-compose.prod.yml logs -f

# ควรเห็น:
# ✅ Server running on port 3000
# ✅ MQTT Connected
# ✅ Firebase Admin SDK initialized
```

**กด Ctrl+C เพื่อออกจาก logs**

### Step 4.5: ทดสอบ API

```bash
# ทดสอบ health check
curl http://localhost:3000/health

# ควรได้:
# {"success":true,"status":"healthy","mqtt":"connected"}
```


---

## 🚀 Part 5: Setup Nginx (Reverse Proxy)

**เวลา: 10 นาที**

### Step 5.1: สร้าง Nginx Config

```bash
# สร้าง config file
sudo nano /etc/nginx/sites-available/earthquake-api
```

**ใส่เนื้อหา:**
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;  # เปลี่ยนเป็น domain จริง หรือ IP

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # API endpoint
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

**บันทึก**: Ctrl+O, Enter, Ctrl+X

### Step 5.2: Enable Site

```bash
# สร้าง symbolic link
sudo ln -s /etc/nginx/sites-available/earthquake-api /etc/nginx/sites-enabled/

# ลบ default site
sudo rm /etc/nginx/sites-enabled/default

# ทดสอบ config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 5.3: ทดสอบผ่าน Nginx

```bash
# ทดสอบจาก server
curl http://localhost/health

# ทดสอบจากเครื่องคุณ (เปิด terminal ใหม่)
curl http://123.45.67.89/health
```


---

## 🚀 Part 6: Setup SSL (HTTPS)

**เวลา: 5-10 นาที**

### ถ้ามี Domain:

```bash
# ขอ SSL certificate จาก Let's Encrypt
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# ตอบคำถาม:
# Email: your-email@example.com
# Terms of Service: Y
# Share email: N
# Redirect HTTP to HTTPS: 2 (Yes)

# ทดสอบ
curl https://your-domain.com/health
```

### ถ้าไม่มี Domain (ใช้ IP):

**ข้าม SSL ไปก่อน** หรือใช้ self-signed certificate:

```bash
# สร้าง self-signed certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt

# แก้ไข Nginx config
sudo nano /etc/nginx/sites-available/earthquake-api
```

**เพิ่ม:**
```nginx
server {
    listen 443 ssl;
    server_name 123.45.67.89;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    # ... rest of config
}
```

**หมายเหตุ**: Self-signed certificate จะมี warning ใน browser แต่ใช้งานได้


---

## 🚀 Part 7: Setup Firewall

**เวลา: 5 นาที**

```bash
# Allow SSH
sudo ufw allow OpenSSH

# Allow HTTP
sudo ufw allow 'Nginx HTTP'

# Allow HTTPS
sudo ufw allow 'Nginx HTTPS'

# Enable firewall
sudo ufw enable

# ตอบ: y

# ตรวจสอบ status
sudo ufw status

# ควรเห็น:
# Status: active
# To                         Action      From
# --                         ------      ----
# OpenSSH                    ALLOW       Anywhere
# Nginx HTTP                 ALLOW       Anywhere
# Nginx HTTPS                ALLOW       Anywhere
```

---

## 🚀 Part 8: Setup Auto-restart

**เวลา: 5 นาที**

### Step 8.1: สร้าง Systemd Service

```bash
# สร้าง service file
sudo nano /etc/systemd/system/earthquake-api.service
```

**ใส่เนื้อหา:**
```ini
[Unit]
Description=Earthquake API Server
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/eqnode/earthquake_app_new2/backend
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
User=eqnode
Group=eqnode

[Install]
WantedBy=multi-user.target
```

**บันทึก**: Ctrl+O, Enter, Ctrl+X

### Step 8.2: Enable Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable earthquake-api

# Start service
sudo systemctl start earthquake-api

# ตรวจสอบ status
sudo systemctl status earthquake-api
```

### Step 8.3: ทดสอบ Auto-restart

```bash
# Reboot server
sudo reboot

# รอ 1-2 นาที แล้ว SSH เข้าใหม่
ssh eqnode@123.45.67.89

# ตรวจสอบว่า container รันอยู่
docker ps

# ทดสอบ API
curl http://localhost/health
```


---

## 🚀 Part 9: Setup Monitoring & Logs

**เวลา: 10 นาที**

### Step 9.1: ดู Logs

```bash
# Docker logs
docker-compose -f docker-compose.prod.yml logs -f

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u earthquake-api -f
```

### Step 9.2: Setup Log Rotation

```bash
# สร้าง logrotate config
sudo nano /etc/logrotate.d/earthquake-api
```

**ใส่เนื้อหา:**
```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

### Step 9.3: Setup Monitoring Script

```bash
# สร้าง monitoring script
nano ~/monitor.sh
```

**ใส่เนื้อหา:**
```bash
#!/bin/bash

echo "=== System Status ==="
echo "Date: $(date)"
echo ""

echo "=== CPU & Memory ==="
top -bn1 | head -5
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Docker Containers ==="
docker ps
echo ""

echo "=== API Health ==="
curl -s http://localhost/health | jq .
echo ""

echo "=== Recent Logs ==="
docker-compose -f ~/earthquake_app_new2/backend/docker-compose.prod.yml logs --tail=20
```

```bash
# ทำให้ executable
chmod +x ~/monitor.sh

# รัน
./monitor.sh
```


---

## 🚀 Part 10: Update Flutter App

**เวลา: 10 นาที**

### Step 10.1: แก้ไข API URL

```dart
// lib/config/app_config.dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://localhost:3000/api/v1';
    case Environment.staging:
      return 'http://123.45.67.89/api/v1';  // ใช้ IP หรือ domain
    case Environment.production:
      return 'https://your-domain.com/api/v1';  // ใช้ HTTPS ถ้ามี SSL
  }
}
```

### Step 10.2: Setup Firebase ใน Flutter

```bash
# ติดตั้ง FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=earthquake-alert-system
```

### Step 10.3: เพิ่ม Firebase Files

**Android:**
```bash
# วาง google-services.json ที่ดาวน์โหลดจาก Firebase
# ไปที่: android/app/google-services.json
```

**iOS:**
```bash
# วาง GoogleService-Info.plist
# ไปที่: ios/Runner/GoogleService-Info.plist
```

### Step 10.4: Rebuild App

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Build Android
flutter build apk --release

# หรือ Build iOS
flutter build ios --release

# Run
flutter run --release
```


---

## 🧪 Part 11: Testing

### Test 1: API Health Check

```bash
# จากเครื่องคุณ
curl https://your-domain.com/health

# ควรได้:
{
  "success": true,
  "status": "healthy",
  "mqtt": "connected",
  "version": "v1"
}
```

### Test 2: MQTT Connection

```bash
# SSH เข้า server
ssh eqnode@123.45.67.89

# ดู logs
docker-compose -f ~/earthquake_app_new2/backend/docker-compose.prod.yml logs | grep MQTT

# ควรเห็น:
# ✅ MQTT Connected to mqtt://mqtt.uiot.cloud:1883
```

### Test 3: Database Connection

```bash
# ทดสอบ query devices
curl https://your-domain.com/api/v1/devices

# ควรได้ array ของ devices
```

### Test 4: Push Notification

```bash
# ส่ง test notification
curl -X POST https://your-domain.com/api/v1/test/notification \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Alert",
    "body": "Testing push notification"
  }'
```

### Test 5: Earthquake Simulation

```bash
# SSH เข้า server
ssh eqnode@123.45.67.89

# ไปที่ backend folder
cd ~/earthquake_app_new2/backend

# รัน simulation
node simulate-earthquake.js

# ตรวจสอบว่า:
# 1. Backend ได้รับข้อมูล
# 2. คำนวณ magnitude
# 3. ส่ง notification
# 4. Flutter app ได้รับ notification
```


---

## 🔧 Part 12: Maintenance & Updates

### Update Code

```bash
# SSH เข้า server
ssh eqnode@123.45.67.89

# ไปที่ project folder
cd ~/earthquake_app_new2

# Pull latest code
git pull origin main

# Rebuild และ restart
cd backend
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# ตรวจสอบ logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Backup Database

```bash
# MongoDB Atlas มี automatic backup
# ไปที่: https://cloud.mongodb.com
# Clusters → Backups → Configure

# หรือ manual backup:
mongodump --uri="mongodb+srv://user:pass@cluster.mongodb.net/eqnode_prod" --out=backup-$(date +%Y%m%d)
```

### Monitor Resources

```bash
# CPU & Memory
htop

# Disk usage
df -h

# Docker stats
docker stats

# Network
sudo iftop
```

### Restart Services

```bash
# Restart API
docker-compose -f ~/earthquake_app_new2/backend/docker-compose.prod.yml restart

# Restart Nginx
sudo systemctl restart nginx

# Restart server
sudo reboot
```


---

## 🐛 Troubleshooting

### ปัญหา: ไม่สามารถ SSH เข้า server

```bash
# ตรวจสอบ SSH key
ssh -v root@123.45.67.89

# ถ้าไม่ได้: ใช้ Console ใน DigitalOcean dashboard
```

### ปัญหา: API ไม่ตอบ

```bash
# ตรวจสอบ container
docker ps

# ดู logs
docker-compose -f docker-compose.prod.yml logs

# Restart
docker-compose -f docker-compose.prod.yml restart
```

### ปัญหา: MQTT ไม่เชื่อมต่อ

```bash
# ตรวจสอบ environment variables
docker-compose -f docker-compose.prod.yml exec api env | grep MQTT

# ทดสอบ MQTT จาก server
mosquitto_sub -h mqtt.uiot.cloud -p 1883 -u ethernet -P "ei8jZz87wx" -t "#"
```

### ปัญหา: Database connection failed

```bash
# ตรวจสอบ MONGODB_URI
docker-compose -f docker-compose.prod.yml exec api env | grep MONGODB_URI

# ทดสอบ connection
mongosh "mongodb+srv://user:pass@cluster.mongodb.net/eqnode_prod"
```

### ปัญหา: SSL certificate error

```bash
# Renew certificate
sudo certbot renew

# ตรวจสอบ certificate
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run
```

### ปัญหา: Out of memory

```bash
# ตรวจสอบ memory
free -h

# ดู process ที่ใช้ memory มาก
ps aux --sort=-%mem | head

# Restart container
docker-compose -f docker-compose.prod.yml restart
```


---

## 📋 Checklist สรุป

### ก่อน Deploy:
- [ ] สมัคร DigitalOcean
- [ ] สมัคร MongoDB Atlas
- [ ] สมัคร Firebase
- [ ] ซื้อ Domain (optional)
- [ ] สร้าง SSH key
- [ ] เตรียม GitHub repository

### ขณะ Deploy:
- [ ] สร้าง Droplet
- [ ] Setup server (Docker, Nginx, etc.)
- [ ] Clone repository
- [ ] สร้าง .env.production
- [ ] Build และ run Docker
- [ ] Setup Nginx
- [ ] Setup SSL
- [ ] Setup Firewall
- [ ] Setup auto-restart

### หลัง Deploy:
- [ ] ทดสอบ API
- [ ] ทดสอบ MQTT
- [ ] ทดสอบ Database
- [ ] ทดสอบ Push Notification
- [ ] Update Flutter app
- [ ] ทดสอบ end-to-end
- [ ] Setup monitoring
- [ ] Setup backup

---

## 💰 สรุปค่าใช้จ่าย

| รายการ | ราคา/เดือน | ราคา/ปี |
|--------|------------|---------|
| DigitalOcean Droplet | $6 | $72 |
| MongoDB Atlas | $0 | $0 |
| Firebase | $0 | $0 |
| Domain (optional) | $1 | $12 |
| Backup (optional) | $1.20 | $14.40 |
| **รวม** | **$7-8** | **$84-98** |

---

## 🎯 Timeline

| ขั้นตอน | เวลา |
|---------|------|
| Setup MongoDB Atlas | 10 นาที |
| Setup Firebase | 15 นาที |
| สร้าง Droplet | 10 นาที |
| Setup Server | 30 นาที |
| Deploy Backend | 20 นาที |
| Setup Nginx + SSL | 15 นาที |
| Setup Firewall | 5 นาที |
| Testing | 15 นาที |
| Update Flutter App | 10 นาที |
| **รวม** | **~2 ชั่วโมง** |

---

## 📚 Resources

- [DigitalOcean Docs](https://docs.digitalocean.com)
- [MongoDB Atlas Docs](https://docs.atlas.mongodb.com)
- [Firebase Docs](https://firebase.google.com/docs)
- [Nginx Docs](https://nginx.org/en/docs/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
- [Docker Docs](https://docs.docker.com)

---

## 🎉 เสร็จแล้ว!

ตอนนี้คุณมี:
- ✅ Production server บน DigitalOcean
- ✅ MongoDB Atlas database
- ✅ Firebase push notifications
- ✅ HTTPS (SSL certificate)
- ✅ Firewall protection
- ✅ Auto-restart on reboot
- ✅ Monitoring & logging
- ✅ Flutter app เชื่อมต่อ production server

**ระบบพร้อมใช้งานจริง!** 🚀

---

**Last Updated**: November 21, 2025
**Author**: Kiro AI Assistant
**Status**: ✅ Production Ready
