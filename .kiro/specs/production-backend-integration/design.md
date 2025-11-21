# Design Document - Production Backend Integration

## Overview

การออกแบบระบบแจ้งเตือนแผ่นดินไหวแบบ Production-ready ที่ประกอบด้วย Backend Server, Database, Cloud Services และ Mobile Application ที่พร้อมสำหรับการใช้งานจริงและการขึ้น App Store

## Architecture

### System Architecture Diagram

```
┌─────────────────┐    HTTPS/WSS   ┌──────────────────┐    Database    ┌─────────────────┐
│   Mobile App    │ ──────────────► │  Backend Server  │ ──────────────► │   PostgreSQL    │
│   (Flutter)     │                │   (Node.js/Go)   │                │   (Primary DB)  │
└─────────────────┘                └──────────────────┘                └─────────────────┘
         │                                   │                                   │
         │ FCM Push                          │ MQTT Subscribe                    │ Backup
         ▼                                   ▼                                   ▼
┌─────────────────┐                ┌──────────────────┐                ┌─────────────────┐
│ Firebase Cloud  │                │   MQTT Broker    │                │   MongoDB       │
│   Messaging     │                │ (mqtt.uiot.cloud)│                │ (Logs & Cache)  │
└─────────────────┘                └──────────────────┘                └─────────────────┘
         │                                   ▲
         │                                   │ Sensor Data
         │                          ┌──────────────────┐
         └─────────────────────────► │   IoT Devices    │
                                    │   (Sensors)      │
                                    └──────────────────┘
```

### Technology Stack

#### Backend Server
- **Runtime**: Node.js 18+ หรือ Go 1.21+
- **Framework**: Express.js (Node.js) หรือ Gin (Go)
- **Authentication**: JWT with RS256 signing
- **API Documentation**: OpenAPI 3.0 (Swagger)
- **Environment**: Docker containers on AWS ECS/EKS

#### Database Layer
- **Primary Database**: PostgreSQL 15+ (User data, Device registry, System config)
- **Time-series Database**: MongoDB 6+ (Earthquake logs, Sensor data)
- **Cache Layer**: Redis 7+ (Session cache, API rate limiting)
- **File Storage**: AWS S3 (QR codes, User avatars, Logs backup)

#### Cloud Infrastructure
- **Hosting**: AWS (Primary) หรือ Google Cloud Platform
- **CDN**: CloudFlare (Global content delivery)
- **Monitoring**: AWS CloudWatch + Datadog
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Domain & SSL**: Custom domain with Let's Encrypt SSL

#### Mobile Application
- **Framework**: Flutter 3.16+
- **State Management**: Provider pattern
- **Local Storage**: SQLite + Secure Storage
- **Network**: HTTP/2 with certificate pinning
- **Build**: Automated CI/CD with GitHub Actions

## Components and Interfaces

### 1. Authentication Service

#### JWT Token Structure
```json
{
  "sub": "user_uuid",
  "email": "user@example.com",
  "role": "user|admin",
  "device_limit": 10,
  "iat": 1699000000,
  "exp": 1701592000
}
```

#### API Endpoints
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET  /api/v1/auth/profile
PUT  /api/v1/auth/profile
```

### 2. Device Management Service

#### Device Registration Flow
```
Mobile App → POST /api/v1/devices/register → Backend Server
                                          ↓
                                    Validate QR Data
                                          ↓
                                    Store in PostgreSQL
                                          ↓
                                    Return Device UUID
```

#### API Endpoints
```
POST   /api/v1/devices/register
GET    /api/v1/devices/user/{userId}
PUT    /api/v1/devices/{deviceId}
DELETE /api/v1/devices/{deviceId}
GET    /api/v1/devices/{deviceId}/status
```

### 3. MQTT Data Processing Service

#### Real-time Data Pipeline
```
IoT Device → MQTT Broker → Backend Subscriber → Data Validation
                                             ↓
                                        Store in MongoDB
                                             ↓
                                        Check Alert Rules
                                             ↓
                                        Trigger FCM Notifications
```

#### MQTT Topics Structure
```
earthquake/data/{deviceId}     - Raw sensor data
earthquake/alert/{deviceId}    - Critical alerts
earthquake/status/{deviceId}   - Device health status
earthquake/config/{deviceId}   - Configuration updates
```

### 4. Push Notification Service

#### FCM Integration
```javascript
// Server-side FCM payload
{
  "to": "user_fcm_token",
  "notification": {
    "title": "🚨 Earthquake Alert",
    "body": "Magnitude 4.2 detected near your location",
    "icon": "earthquake_icon",
    "sound": "emergency_alert.wav"
  },
  "data": {
    "type": "earthquake",
    "deviceId": "EQC-001",
    "magnitude": "4.2",
    "location": "Bangkok, Thailand",
    "timestamp": "2024-11-02T14:30:00Z"
  }
}
```

## Data Models

### User Model (PostgreSQL)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    fcm_token VARCHAR(255),
    device_limit INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Device Model (PostgreSQL)
```sql
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- earthquake, tsunami, tilt
    location_name VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, maintenance
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Earthquake Event Model (MongoDB)
```javascript
{
  _id: ObjectId,
  deviceId: "EQC-001",
  userId: "user_uuid",
  magnitude: 4.2,
  location: {
    name: "Bangkok, Thailand",
    coordinates: [100.5018, 13.7563] // [longitude, latitude]
  },
  type: "earthquake", // earthquake, tsunami, tilt
  severity: "moderate", // low, moderate, high, critical
  processed: true,
  notificationSent: true,
  timestamp: ISODate("2024-11-02T14:30:00Z"),
  createdAt: ISODate("2024-11-02T14:30:01Z")
}
```

## Error Handling

### API Error Response Format
```json
{
  "error": {
    "code": "DEVICE_NOT_FOUND",
    "message": "Device with ID EQC-001 not found",
    "details": {
      "deviceId": "EQC-001",
      "userId": "user_uuid"
    },
    "timestamp": "2024-11-02T14:30:00Z",
    "requestId": "req_123456789"
  }
}
```

### Error Codes
- `AUTH_INVALID_TOKEN` - JWT token invalid or expired
- `AUTH_INSUFFICIENT_PERMISSIONS` - User lacks required permissions
- `DEVICE_NOT_FOUND` - Device not found or not owned by user
- `DEVICE_LIMIT_EXCEEDED` - User has reached device registration limit
- `VALIDATION_ERROR` - Request data validation failed
- `MQTT_CONNECTION_FAILED` - MQTT broker connection error
- `DATABASE_ERROR` - Database operation failed
- `EXTERNAL_SERVICE_ERROR` - Third-party service error

## Testing Strategy

### Unit Testing
- **Backend**: Jest (Node.js) หรือ Go testing framework
- **Mobile**: Flutter test framework
- **Coverage Target**: 80%+ code coverage

### Integration Testing
- **API Testing**: Postman/Newman automated tests
- **Database Testing**: Test containers with real database instances
- **MQTT Testing**: Mock MQTT broker for reliable testing

### End-to-End Testing
- **Mobile E2E**: Flutter integration tests
- **API E2E**: Full workflow testing from registration to notification
- **Performance Testing**: Load testing with Artillery.js

### Production Monitoring
- **Health Checks**: `/health` endpoint with database connectivity check
- **Metrics**: Prometheus + Grafana dashboards
- **Logging**: Structured JSON logs with correlation IDs
- **Alerting**: PagerDuty integration for critical errors

## Security Considerations

### Authentication & Authorization
- JWT tokens with 30-day expiration
- Refresh token rotation
- Rate limiting: 100 requests/minute per user
- API key authentication for admin endpoints

### Data Protection
- Password hashing with bcrypt (cost factor 12)
- Database encryption at rest
- TLS 1.3 for all communications
- Input validation and sanitization

### Infrastructure Security
- VPC with private subnets for databases
- WAF (Web Application Firewall) protection
- Regular security updates and patches
- Backup encryption with separate keys

## Deployment Strategy

### Environment Setup
```
Development → Staging → Production
     ↓           ↓         ↓
   Local DB → Test DB → Prod DB
   Mock FCM → Test FCM → Prod FCM
```

### CI/CD Pipeline
1. **Code Commit** → GitHub repository
2. **Automated Tests** → Unit + Integration tests
3. **Build & Package** → Docker images + Flutter APK
4. **Deploy to Staging** → Automated deployment
5. **E2E Testing** → Automated smoke tests
6. **Deploy to Production** → Blue-green deployment
7. **Health Check** → Verify all services

### Monitoring & Alerting
- **Uptime Monitoring**: 99.9% SLA target
- **Response Time**: < 200ms for API calls
- **Error Rate**: < 0.1% for critical operations
- **Database Performance**: Query optimization monitoring