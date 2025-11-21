# 🏗️ System Architecture - eQNode

## 📊 System Architecture Diagram

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐         ┌──────────────┐
│   Mobile App    │◄───────►│ Backend Server   │◄───────►│  MQTT Broker    │◄───────►│ IoT Devices  │
│   (Flutter)     │         │  (Node.js/Go)    │         │(mqtt.uiot.cloud)│         │  (Sensors)   │
│  Primary DB     │         │                  │         │                 │         │              │
└────────┬────────┘         └────────┬─────────┘         └─────────────────┘         └──────────────┘
         │                           │                                                        │
         │ FCM Push                  │ Backup                                          Sensor Data
         │ Subscribe                 │                                                        │
         ▼                           ▼                                                        ▼
┌─────────────────┐         ┌──────────────────┐                                    ┌──────────────┐
│ Firebase Cloud  │         │   PostgreSQL     │                                    │   Sensors    │
│   Messaging     │         │    Database      │                                    │   Hardware   │
│ (Logs & Cache)  │         │                  │                                    │              │
└─────────────────┘         └──────────────────┘                                    └──────────────┘
```

## 🔄 Data Flow

### 1. Sensor → Cloud → App (Real-time Data)

```
IoT Sensor → MQTT Broker → Backend Server → Mobile App
                ↓              ↓                ↓
           mqtt.uiot.cloud  PostgreSQL    Local Storage
                              (Backup)     + Firebase
```

### 2. App → Cloud → Sensor (Commands)

```
Mobile App → Backend Server → MQTT Broker → IoT Sensor
    ↓             ↓               ↓
Firebase      PostgreSQL    mqtt.uiot.cloud
```

### 3. Notifications

```
Backend Server → Firebase Cloud Messaging → Mobile App
      ↓                                          ↓
  PostgreSQL                              Local Notification
  (Log Events)                            + Sound/Vibration
```

---

## 🎯 Components

### 1. Mobile App (Flutter)
**Location**: `/lib`

**Responsibilities**:
- 📱 User Interface (UI/UX)
- 🔐 User Authentication
- 📊 Data Visualization (Charts, Maps)
- 🔔 Push Notifications (FCM)
- 💾 Local Data Storage (SQLite)
- 📡 Real-time MQTT Connection
- 🔄 Data Synchronization

**Key Files**:
- `lib/main.dart` - Entry point
- `lib/services/mqtt_manager.dart` - MQTT client
- `lib/services/api_service.dart` - Backend API client
- `lib/services/notification_service.dart` - FCM handler
- `lib/config/app_config.dart` - Configuration

**Technologies**:
- Flutter SDK
- Dart
- MQTT Client
- Firebase Cloud Messaging
- SQLite (sqflite)
- Provider (State Management)

---

### 2. Backend Server (Node.js)
**Location**: `/backend`

**Responsibilities**:
- 🔐 Authentication & Authorization (JWT)
- 📊 Data Processing & Validation
- 💾 Database Management (PostgreSQL)
- 📡 MQTT Bridge (Subscribe & Publish)
- 🔔 Push Notification Sender (FCM)
- 📈 Analytics & Statistics
- 🔄 Data Backup & Recovery
- 🔒 Security & Rate Limiting

**Key Files**:
- `backend/src/server.js` - Main server
- `backend/src/config/mqtt.js` - MQTT configuration
- `backend/src/routes/` - API endpoints
- `backend/src/models/` - Database models
- `backend/src/middleware/auth.js` - Authentication

**Technologies**:
- Node.js + Express
- PostgreSQL
- MQTT Client
- JWT (jsonwebtoken)
- Firebase Admin SDK

**API Endpoints**:
```
POST   /api/v1/auth/register      - Register user
POST   /api/v1/auth/login         - Login
GET    /api/v1/devices            - Get user devices
POST   /api/v1/devices/register   - Register device
GET    /api/v1/events/earthquake  - Get earthquake events
POST   /api/v1/events/report      - Report false positive
```

---

### 3. MQTT Broker (mqtt.uiot.cloud)
**External Service**

**Responsibilities**:
- 📡 Message Routing (Pub/Sub)
- 🔄 Real-time Data Streaming
- 📊 Topic Management
- 🔐 Authentication
- 💾 Message Persistence (QoS)

**Configuration**:
```
Host: mqtt.uiot.cloud
Port: 1883 (TCP) / 8083 (WebSocket)
Username: ethernet
Password: ei8jZz87wx
```

**Topics**:
```
eqnode.tarita/hub/data     - Sensor data (publish)
eqnode.tarita/hub/alert    - Alert messages (publish)
eqnode.tarita/hub/#        - Subscribe all (wildcard)
```

**Message Format**:
```json
{
  "deviceId": "EQC-001",
  "magnitude": 4.5,
  "location": "Bangkok, Thailand",
  "latitude": 13.7563,
  "longitude": 100.5018,
  "timestamp": "2025-01-20T10:00:00Z",
  "type": "earthquake",
  "ownerId": "user@example.com"
}
```

---

### 4. PostgreSQL Database
**Location**: Docker Container

**Responsibilities**:
- 💾 Persistent Data Storage
- 📊 User Management
- 🔐 Device Registry
- 📈 Event History
- 🔄 Backup & Recovery

**Tables**:
```sql
users              - User accounts
devices            - Registered devices
earthquake_events  - Earthquake data
notifications      - Notification logs
device_status      - Device health status
```

**Schema**: See `backend/src/database/schema.sql`

---

### 5. Firebase Cloud Messaging (FCM)
**External Service**

**Responsibilities**:
- 🔔 Push Notifications
- 📊 Notification Analytics
- 💾 Message Caching
- 🔄 Delivery Tracking

**Integration**:
- Backend sends via Firebase Admin SDK
- Mobile app receives via FlutterFire
- Logs stored in Firebase Console

---

### 6. IoT Devices (Sensors)
**Hardware**: Earthquake Sensors

**Responsibilities**:
- 📊 Seismic Data Collection
- 📡 MQTT Publishing
- 🔋 Power Management
- 🔐 Device Authentication

**Data Published**:
- Magnitude (Richter scale)
- Location (GPS coordinates)
- Timestamp
- Device ID
- Sensor status

---

## 🔐 Security

### Authentication Flow

```
1. User Login
   Mobile App → Backend → PostgreSQL
   ↓
   JWT Token Generated
   ↓
   Token Stored in Secure Storage

2. API Requests
   Mobile App (with JWT) → Backend → Verify Token → Process Request

3. MQTT Connection
   Backend → MQTT Broker (with credentials)
   Mobile App → MQTT Broker (with credentials)
```

### Security Measures

- ✅ JWT Authentication
- ✅ Password Hashing (bcrypt)
- ✅ HTTPS/TLS (Production)
- ✅ Rate Limiting
- ✅ Input Validation
- ✅ SQL Injection Prevention
- ✅ XSS Protection
- ✅ CORS Configuration

---

## 📊 Data Flow Examples

### Example 1: Earthquake Detection

```
1. Sensor detects earthquake (magnitude 4.5)
   ↓
2. Sensor publishes to MQTT
   Topic: eqnode.tarita/hub/data
   ↓
3. Backend subscribes and receives data
   ↓
4. Backend processes data:
   - Validates data
   - Stores in PostgreSQL
   - Checks if magnitude >= 3.0
   ↓
5. If magnitude >= 3.0:
   - Send FCM notification to users
   - Publish alert to MQTT
   ↓
6. Mobile App receives:
   - MQTT message (real-time)
   - FCM notification (push)
   ↓
7. Mobile App displays:
   - Dashboard update
   - Notification banner
   - Sound/Vibration alert
```

### Example 2: User Registers Device

```
1. User scans QR code
   ↓
2. Mobile App sends registration request
   POST /api/v1/devices/register
   ↓
3. Backend validates and stores in PostgreSQL
   ↓
4. Backend subscribes to device's MQTT topic
   ↓
5. Device starts publishing data
   ↓
6. Mobile App receives real-time updates
```

---

## 🚀 Deployment

### Development Environment

```
Mobile App: Flutter run (Simulator/Emulator)
Backend: npm run dev (localhost:3000)
Database: Docker (PostgreSQL)
MQTT: mqtt.uiot.cloud (Cloud)
```

### Production Environment

```
Mobile App: App Store / Google Play
Backend: Cloud Server (AWS/GCP/Azure)
Database: Managed PostgreSQL (RDS/Cloud SQL)
MQTT: mqtt.uiot.cloud (Cloud)
FCM: Firebase Console
```

---

## 📈 Scalability

### Current Capacity
- Users: ~1,000
- Devices: ~100 per user
- Events: ~10,000 per day
- MQTT Messages: ~1,000 per minute

### Scaling Strategy
1. **Horizontal Scaling**: Add more backend servers
2. **Database Sharding**: Split data by region
3. **Caching**: Redis for frequently accessed data
4. **CDN**: Static assets delivery
5. **Load Balancer**: Distribute traffic

---

## 🔧 Configuration

### Environment Variables

**Backend** (`.env`):
```env
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/eqnode
JWT_SECRET=your-secret-key
MQTT_HOST=mqtt.uiot.cloud
MQTT_PORT=1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
FIREBASE_PROJECT_ID=eqnode-prod
```

**Mobile App** (`app_config.dart`):
```dart
baseUrl: 'http://10.134.94.222:3000/api/v1'
mqttHost: 'mqtt.uiot.cloud'
mqttPort: 1883
enableMockData: false
```

---

## 📝 Technology Stack

### Frontend (Mobile App)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **MQTT**: mqtt_client
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **HTTP**: http package

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 15+
- **MQTT**: mqtt.js
- **Authentication**: JWT (jsonwebtoken)
- **Validation**: express-validator
- **Security**: helmet, cors

### Infrastructure
- **Database**: PostgreSQL (Docker)
- **MQTT Broker**: mqtt.uiot.cloud
- **Push Notifications**: Firebase Cloud Messaging
- **Version Control**: Git
- **CI/CD**: GitHub Actions (future)

---

## 🎯 Next Steps

1. ✅ Complete Backend API implementation
2. ✅ Integrate MQTT with Backend
3. ✅ Implement FCM notifications
4. ⏳ Add real sensor integration
5. ⏳ Deploy to production
6. ⏳ Add monitoring & analytics
7. ⏳ Implement data backup strategy

---

**Last Updated**: January 20, 2025
