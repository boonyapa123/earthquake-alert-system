# 🚀 Deploy Backend บน DigitalOcean (ไม่ต้องมี Domain)

## ✅ ข้อดี: ใช้ IP Address โดยตรง

- ✅ ไม่ต้องซื้อ domain
- ✅ ไม่ต้องตั้งค่า DNS
- ✅ ประหยัดค่าใช้จ่าย
- ✅ Deploy ได้เร็ว
- ⚠️ ข้อเสีย: ไม่มี HTTPS (แต่ทดสอบได้)

---

## 📋 สิ่งที่ต้องมี

1. ✅ บัญชี DigitalOcean (คุณมีแล้ว)
2. ✅ โค้ด Backend (มีแล้ว)
3. ⏱️ เวลา 15-20 นาที

---

## 🎯 ขั้นตอนการ Deploy

### ขั้นตอนที่ 1: สร้าง Droplet

1. เข้า https://cloud.digitalocean.com
2. คลิก **"Create"** → **"Droplets"**
3. เลือก:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic
   - **CPU:** Regular (2 GB RAM / 1 CPU) - $12/month ⭐ แนะนำ
     - หรือ 1 GB RAM - $6/month (ถ้าประหยัด)
   - **Datacenter:** Singapore (ใกล้ไทยที่สุด)
   - **Authentication:** SSH Key (แนะนำ) หรือ Password
   - **Hostname:** `eqnode-backend`

4. คลิก **"Create Droplet"**
5. รอ 1-2 นาที จะได้ **IP Address** เช่น `159.89.XXX.XXX`

---

### ขั้นตอนที่ 2: เชื่อมต่อ Droplet

#### macOS/Linux:
```bash
ssh root@159.89.XXX.XXX
# เปลี่ยน IP เป็นของคุณ
```

#### Windows (ใช้ PowerShell):
```bash
ssh root@159.89.XXX.XXX
```

หรือใช้ **PuTTY** ก็ได้

---

### ขั้นตอนที่ 3: ติดตั้ง Docker บน Droplet

```bash
# 1. Update system
apt update && apt upgrade -y

# 2. ติดตั้ง Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. ติดตั้ง Docker Compose
apt install docker-compose -y

# 4. ตรวจสอบ
docker --version
docker-compose --version
```

---

### ขั้นตอนที่ 4: Upload โค้ดขึ้น Droplet

#### วิธีที่ 1: ใช้ Git (แนะนำ) ⭐

```bash
# บน Droplet
cd /root
git clone https://github.com/your-username/your-repo.git
cd your-repo/backend
```

#### วิธีที่ 2: ใช้ SCP Upload จากเครื่องคุณ

```bash
# บนเครื่องคุณ (ไม่ใช่ Droplet)
cd /path/to/your/project
scp -r backend root@159.89.XXX.XXX:/root/
```

---

### ขั้นตอนที่ 5: ตั้งค่า Environment Variables

```bash
# บน Droplet
cd /root/backend  # หรือ path ที่คุณ upload

# สร้างไฟล์ .env
nano .env
```

**วาง config นี้:**
```env
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=eqnode_prod
DB_USER=postgres
DB_PASSWORD=YourSecurePassword123!

# MongoDB Configuration
MONGODB_URI=mongodb://mongodb:27017/eqnode_logs

# JWT Configuration (สร้าง random string)
JWT_SECRET=your_super_secret_random_string_change_this_12345

# MQTT Configuration
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_prod

# Security
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS - ใส่ IP ของ Droplet
ALLOWED_ORIGINS=http://159.89.XXX.XXX:3000,http://localhost:3000

# Max devices per user
MAX_DEVICES_PER_USER=10
```

**กด:**
- `Ctrl + O` (Save)
- `Enter` (Confirm)
- `Ctrl + X` (Exit)

---

### ขั้นตอนที่ 6: แก้ไข docker-compose.yml สำหรับ Production

```bash
nano docker-compose.yml
```

**แก้เป็น:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: eqnode-postgres
    environment:
      POSTGRES_DB: eqnode_prod
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: YourSecurePassword123!
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  mongodb:
    image: mongo:7
    container_name: eqnode-mongodb
    environment:
      MONGO_INITDB_DATABASE: eqnode_logs
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    restart: always

  api:
    build: .
    container_name: eqnode-api
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - mongodb
    restart: always

volumes:
  postgres_data:
  mongodb_data:
```

---

### ขั้นตอนที่ 7: เริ่มต้น Services

```bash
# 1. Build และเริ่ม services
docker-compose up -d --build

# 2. รอ 1-2 นาที แล้วตรวจสอบ
docker-compose ps

# 3. ดู logs
docker-compose logs -f api
```

คุณจะเห็น:
```
✅ PostgreSQL connected
✅ MongoDB connected
✅ MQTT Connected
🚀 eQNode Backend Server Started
```

กด `Ctrl + C` เพื่อออกจาก logs

---

### ขั้นตอนที่ 8: รัน Database Migration

```bash
docker-compose exec api npm run migrate
```

คุณจะเห็น:
```
✅ Database schema created successfully
✅ Test user created/updated: user@eqnode.com
```

---

### ขั้นตอนที่ 9: เปิด Firewall

```bash
# เปิด port 3000 สำหรับ API
ufw allow 3000/tcp

# เปิด port 22 สำหรับ SSH (ถ้ายังไม่เปิด)
ufw allow 22/tcp

# เปิด firewall
ufw enable

# ตรวจสอบ
ufw status
```

---

### ขั้นตอนที่ 10: ทดสอบ API

```bash
# ทดสอบจาก Droplet
curl http://localhost:3000/health

# ทดสอบจากเครื่องคุณ
curl http://159.89.XXX.XXX:3000/health
```

**ถ้าเห็น JSON response = สำเร็จ!** ✅

```json
{
  "success": true,
  "status": "healthy",
  "mqtt": "connected"
}
```

---

## 📱 เชื่อมต่อ Flutter App กับ DigitalOcean

### 1. แก้ไข Flutter Config

เปิดไฟล์ `lib/config/app_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      // ใช้ IP ของ DigitalOcean Droplet
      return 'http://159.89.XXX.XXX:3000/api/v1'; // ⬅️ เปลี่ยนเป็น IP ของคุณ
    case Environment.staging:
      return 'http://159.89.XXX.XXX:3000/api/v1'; // เหมือนกัน
    case Environment.production:
      return 'http://159.89.XXX.XXX:3000/api/v1'; // เหมือนกัน
  }
}
```

### 2. แก้ไข MQTT Config (ถ้าต้องการ)

```dart
static String get mqttHost {
  switch (_environment) {
    case Environment.development:
      return 'mqtt.uiot.cloud'; // ใช้ของเดิม
    case Environment.staging:
      return 'mqtt.uiot.cloud'; // ใช้ของเดิม
    case Environment.production:
      return 'mqtt.uiot.cloud'; // ใช้ของเดิม
  }
}
```

### 3. Build และทดสอบ

```bash
# รัน Flutter
flutter run

# หรือ Build APK
flutter build apk --release
```

### 4. ทดสอบ Login

- Email: `user@eqnode.com`
- Password: `password123`

---

## 🔍 ตรวจสอบและ Debug

### ดู Logs

```bash
# ดู logs ทั้งหมด
docker-compose logs -f

# ดูเฉพาะ API
docker-compose logs -f api

# ดูเฉพาะ Database
docker-compose logs -f postgres
```

### Restart Services

```bash
# Restart ทั้งหมด
docker-compose restart

# Restart เฉพาะ API
docker-compose restart api
```

### เข้าดู Database

```bash
docker-compose exec postgres psql -U postgres -d eqnode_prod

# ดูข้อมูล users
SELECT * FROM users;

# ดูข้อมูล devices
SELECT * FROM devices;

# ออกจาก psql
\q
```

---

## 📊 ตรวจสอบ Resource Usage

```bash
# ดู CPU, RAM usage
docker stats

# ดู disk usage
df -h

# ดู running processes
docker-compose ps
```

---

## 🔒 Security Best Practices

### 1. เปลี่ยน Root Password

```bash
passwd
```

### 2. สร้าง User ใหม่ (แทน root)

```bash
adduser eqnode
usermod -aG sudo eqnode
usermod -aG docker eqnode
```

### 3. ปิด Root Login

```bash
nano /etc/ssh/sshd_config
# เปลี่ยน: PermitRootLogin no
systemctl restart sshd
```

### 4. ตั้งค่า Fail2Ban (ป้องกัน brute force)

```bash
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

---

## 💰 ค่าใช้จ่าย

### Droplet
- **1 GB RAM:** $6/month (พอใช้ทดสอบ)
- **2 GB RAM:** $12/month ⭐ แนะนำ
- **4 GB RAM:** $24/month (สำหรับ production จริง)

### ไม่มีค่าใช้จ่ายเพิ่ม
- ✅ ไม่ต้องซื้อ domain
- ✅ ไม่ต้องจ่าย SSL
- ✅ Bandwidth 1-2 TB/month (ฟรี)

---

## 🎯 Checklist

- [ ] สร้าง Droplet บน DigitalOcean
- [ ] SSH เข้า Droplet
- [ ] ติดตั้ง Docker + Docker Compose
- [ ] Upload โค้ด (Git หรือ SCP)
- [ ] สร้างไฟล์ .env
- [ ] แก้ไข docker-compose.yml
- [ ] รัน `docker-compose up -d --build`
- [ ] รัน `docker-compose exec api npm run migrate`
- [ ] เปิด Firewall port 3000
- [ ] ทดสอบ `curl http://IP:3000/health`
- [ ] แก้ไข Flutter config ใส่ IP
- [ ] Build Flutter app
- [ ] ทดสอบ Login จากแอพ
- [ ] ทดสอบลงทะเบียนอุปกรณ์
- [ ] ตรวจสอบ MQTT Real-time

---

## 🆘 แก้ไขปัญหา

### ปัญหา: ไม่สามารถเข้า API จากภายนอก

```bash
# ตรวจสอบ firewall
ufw status

# เปิด port 3000
ufw allow 3000/tcp

# ตรวจสอบว่า API รันอยู่
docker-compose ps
curl http://localhost:3000/health
```

### ปัญหา: Database connection error

```bash
# Restart database
docker-compose restart postgres

# ดู logs
docker-compose logs postgres

# ลบและสร้างใหม่
docker-compose down -v
docker-compose up -d
docker-compose exec api npm run migrate
```

### ปัญหา: Out of memory

```bash
# ดู memory usage
free -h

# Upgrade Droplet ไปแผนที่ใหญ่กว่า
# DigitalOcean → Droplet → Resize
```

---

## 🚀 ขั้นตอนถัดไป (Optional)

### ถ้าต้องการ Domain + HTTPS ในอนาคต:

1. ซื้อ domain (Namecheap, GoDaddy, etc.)
2. ตั้งค่า DNS A Record ชี้ไปที่ IP ของ Droplet
3. ติดตั้ง Nginx
4. ติดตั้ง SSL Certificate (Let's Encrypt - ฟรี)
5. แก้ไข Flutter config ใช้ `https://api.yourdomain.com`

---

## 📝 สรุป

**ตอนนี้คุณมี:**
- ✅ Backend API รันบน DigitalOcean
- ✅ Database พร้อมใช้งาน
- ✅ MQTT เชื่อมต่อแล้ว
- ✅ เข้าถึงได้จาก Internet ผ่าน IP
- ✅ Flutter App เชื่อมต่อได้

**ไม่ต้องมี Domain ก็ใช้งานได้แล้ว!** 🎉

---

## 💡 Tips

1. **Backup:** ใช้ DigitalOcean Snapshots (ฟรี)
2. **Monitoring:** ใช้ DigitalOcean Monitoring (ฟรี)
3. **Logs:** เก็บ logs ไว้ดู: `docker-compose logs > logs.txt`
4. **Update:** อัพเดทโค้ดด้วย `git pull` แล้ว `docker-compose up -d --build`

---

## 📞 ต้องการความช่วยเหลือ?

ถ้ามีปัญหาตรงไหน บอกได้เลยครับ! 😊
