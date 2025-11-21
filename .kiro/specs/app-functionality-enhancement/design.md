# Design Document - App Functionality Enhancement

## Overview

การออกแบบระบบเพื่อปรับปรุงแอพพลิเคชัน Earthquake Monitoring ให้ทำงานได้จริงทุกหน้า โดยเชื่อมต่อกับข้อมูลจริงจาก Backend API และ MQTT Broker แทนการใช้ข้อมูล mockup รวมถึงเพิ่มฟีเจอร์ใหม่ๆ ตามความต้องการของผู้ใช้

### Design Goals

1. **Real Data Integration**: เชื่อมต่อกับ Backend API และ MQTT เพื่อแสดงข้อมูลจริง
2. **Functional Settings**: ทำให้การตั้งค่าทุกอย่างทำงานได้จริงและมีผลต่อพฤติกรรมของแอพ
3. **Enhanced Notifications**: ปรับปรุงระบบแจ้งเตือนให้ทำงานบน lock screen และแสดง badge counter
4. **QR Code Registration**: ทำให้การสแกน QR code ลงทะเบียน device ทำงานได้จริง
5. **Global Events View**: เพิ่มหน้าแสดงข้อมูลแผ่นดินไหวจากทั่วโลก
6. **Custom Branding**: เปลี่ยน app icon และ logo ตามที่ผู้ใช้ต้องการ

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Services   │  │    Models    │      │
│  │              │  │              │  │              │      │
│  │ - Home       │  │ - API        │  │ - User       │      │
│  │ - Alerts     │  │ - MQTT       │  │ - Device     │      │
│  │ - Settings   │  │ - Notif.     │  │ - Event      │      │
│  │ - Global     │  │ - Storage    │  │ - Settings   │      │
│  │ - QR Scan    │  │ - Firebase   │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ├─── HTTP/REST API
                            │
                            ├─── MQTT Protocol
                            │
                            └─── FCM Push Notifications
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Backend Server (Node.js)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Routes     │  │   Models     │  │   Services   │      │
│  │              │  │              │  │              │      │
│  │ - Auth       │  │ - User       │  │ - MQTT       │      │
│  │ - Devices    │  │ - Device     │  │ - FCM        │      │
│  │ - Events     │  │ - Event      │  │ - Calc       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ├─── PostgreSQL Database
                            │
                            └─── MQTT Broker (mqtt.uiot.cloud)


```

### Data Flow

1. **User Authentication Flow**
   - User logs in → API validates credentials → Returns JWT token
   - Token stored in secure storage → Used for all subsequent API calls

2. **Device Registration Flow**
   - User scans QR code → Extracts device ID → Sends to API with user token
   - Backend validates ownership → Registers device → Returns success

3. **Real-time Data Flow**
   - IoT Device → MQTT Broker → Backend subscribes → Processes data
   - Backend → Stores in DB → Publishes to MQTT topic
   - Mobile App subscribes → Receives real-time updates → Updates UI

4. **Notification Flow**
   - Event detected → Backend evaluates severity → Sends FCM notification
   - Mobile App receives → Shows local notification → Updates badge counter
   - User opens notification → App navigates to event details

## Components and Interfaces

### 1. Home Screen Component

**Purpose**: แสดงรายการ devices ที่ผู้ใช้ลงทะเบียนไว้ และข้อมูล MQTT real-time

**Key Features**:
- แสดงเฉพาะ devices ของผู้ใช้ที่ login อยู่
- แยกหมวดหมู่ตามประเภท device (earthquake, tsunami, tilt)
- แท็บแสดงข้อมูล MQTT devices เพื่อตรวจสอบการเชื่อมต่อ
- Pull-to-refresh สำหรับอัพเดทข้อมูล

**Data Sources**:
- `GET /devices/user` - ดึงรายการ devices ของผู้ใช้
- MQTT subscription - รับข้อมูล real-time จาก broker
- Local state management - UserState provider

**UI Components**:
```dart
HomeScreen
├── AppBar (with logo)
├── MQTT Status Banner
├── TabBar
│   ├── My Devices Tab
│   │   └── GridView of Device Cards
│   └── MQTT Devices Tab
│       └── ListView of Real-time Data
└── Recent Events Section
    └── Event History Cards
```

### 2. Alerts Screen Component

**Purpose**: แสดงการแจ้งเตือนจากข้อมูลจริง พร้อมปุ่มเปิด/ปิดการแจ้งเตือน

**Key Features**:
- แสดงเฉพาะ alerts จาก devices ของผู้ใช้
- Toggle switch เปิด/ปิดการแจ้งเตือน (persist ใน settings)
- กรองแสดงเฉพาะ events ที่ magnitude >= threshold
- แสดงจำนวน unread alerts

**Data Sources**:
- `GET /events/earthquake?userId={userId}` - ดึง events ของผู้ใช้
- MQTT real-time alerts
- Local settings storage

**State Management**:
```dart
AlertsState {
  bool notificationsEnabled
  List<Event> alerts
  int unreadCount
  double alertThreshold
}
```

### 3. Settings Screen Component

**Purpose**: ให้ผู้ใช้ตั้งค่าต่างๆ ที่มีผลต่อการทำงานของแอพจริง

**Key Settings**:


1. **Notification Settings**
   - Enable/Disable notifications (affects FCM subscription)
   - Alert threshold (magnitude level)
   - Sound enabled/disabled
   - Vibration enabled/disabled
   - Max notification count per event

2. **Display Settings**
   - Language preference
   - Theme (light/dark)
   - Map style

3. **Account Settings**
   - Profile information
   - Change password
   - Device limit

**Storage Strategy**:
- Use `flutter_secure_storage` for sensitive data
- Use `shared_preferences` for UI preferences
- Sync critical settings to backend via `PUT /users/settings`

### 4. QR Scanner Component

**Purpose**: สแกน QR code เพื่อลงทะเบียน device ใหม่

**QR Code Format**:
```json
{
  "deviceId": "EQC-001",
  "type": "earthquake",
  "secretKey": "encrypted_key"
}
```

**Registration Flow**:
1. User taps "Add Device" button
2. Camera permission requested
3. QR scanner opens
4. QR code detected → Parse JSON
5. Validate format → Extract deviceId
6. Call `POST /devices/register` with deviceId and user token
7. Backend validates ownership and secret key
8. Success → Add to user's device list
9. Failure → Show error message

**Error Handling**:
- Invalid QR format → "รูปแบบ QR code ไม่ถูกต้อง"
- Device already registered → "อุปกรณ์นี้ถูกลงทะเบียนแล้ว"
- Network error → "ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่"

### 5. Global Events Screen Component

**Purpose**: แสดงข้อมูลแผ่นดินไหวจากทั่วโลก

**Data Sources**:
- `GET /events/global` - ดึงข้อมูลจาก backend
- Optional: USGS API integration for real-world data

**Features**:
- World map with event markers
- List view with filters (magnitude, date, region)
- Event details on tap
- Color-coded by severity

**Map Integration**:
```dart
GoogleMap(
  markers: events.map((e) => Marker(
    position: LatLng(e.latitude, e.longitude),
    icon: getMarkerIcon(e.magnitude),
    infoWindow: InfoWindow(title: e.location),
  )).toSet(),
)
```

### 6. Notification Service Component

**Purpose**: จัดการการแจ้งเตือนทั้งหมด

**Notification Types**:

1. **Local Notifications** (flutter_local_notifications)
   - Foreground alerts
   - Background alerts
   - Scheduled notifications

2. **Lock Screen Notifications**
   - Full-screen intent for critical alerts
   - High priority channel
   - Custom sound and vibration

3. **Badge Counter**
   - Update app icon badge
   - Increment on new alert
   - Reset when user views alerts

**Implementation**:
```dart
class NotificationService {
  // Show lock screen alert
  static Future<void> showLockScreenAlert(Event event) async {
    final androidDetails = AndroidNotificationDetails(
      'critical_alerts',
      'Critical Alerts',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    
    await plugin.show(id, title, body, details);
  }
  
  // Update badge counter
  static Future<void> updateBadge(int count) async {
    await FlutterAppBadger.updateBadgeCount(count);
  }
}
```

## Data Models

### User Model
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  
  // Settings
  UserSettings settings;
}

class UserSettings {
  bool notificationsEnabled;
  double alertThreshold;
  bool soundEnabled;
  bool vibrationEnabled;
  int maxNotificationCount;
  String language;
  String theme;
}
```

### Device Model
```dart
class Device {
  final int id;
  final String deviceId;
  final String name;
  final String type; // earthquake, tsunami, tilt
  final String location;
  final double latitude;
  final double longitude;
  final int ownerId;
  final String status; // active, inactive, maintenance
  final DateTime? lastSeen;
  final DateTime createdAt;
}
```

### Event Model
```dart
class EarthquakeEvent {
  final int id;
  final String deviceId;
  final double magnitude;
  final String location;
  final double? latitude;
  final double? longitude;
  final String type;
  final String severity; // low, moderate, high, critical
  final Map<String, dynamic>? rawData;
  final DateTime timestamp;
  final bool processed;
  final bool notificationSent;
  final bool falsePositive;
}
```

### Alert Model
```dart
class Alert {
  final String id;
  final EarthquakeEvent event;
  final Device device;
  final bool isRead;
  final DateTime receivedAt;
  final int notificationCount;
}
```

## Error Handling

### API Error Handling


```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  
  ApiException(this.statusCode, this.message, [this.errorCode]);
  
  static ApiException fromResponse(http.Response response) {
    final body = jsonDecode(response.body);
    return ApiException(
      response.statusCode,
      body['message'] ?? 'Unknown error',
      body['errorCode'],
    );
  }
}

// Usage in API calls
try {
  final response = await http.get(url, headers: headers);
  if (response.statusCode != 200) {
    throw ApiException.fromResponse(response);
  }
  return jsonDecode(response.body);
} on ApiException catch (e) {
  // Handle specific API errors
  if (e.statusCode == 401) {
    // Token expired, refresh or logout
  } else if (e.statusCode == 404) {
    // Resource not found
  }
  rethrow;
} catch (e) {
  // Handle network errors
  throw ApiException(0, 'Network error: $e');
}
```

### MQTT Error Handling

```dart
class MqttManager {
  void _onConnectionFailed() {
    // Fallback to mock data in development
    if (AppConfig.isDevelopment) {
      _startMockDataGenerator();
    }
    
    // Show connection error to user
    _showConnectionError();
    
    // Retry connection with exponential backoff
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    final delay = Duration(seconds: _retryCount * 2);
    Timer(delay, () {
      _retryCount++;
      _connect();
    });
  }
}
```

### Notification Error Handling

```dart
class NotificationService {
  static Future<void> showNotification(Alert alert) async {
    try {
      // Check permission
      if (!await areNotificationsEnabled()) {
        throw NotificationException('Notifications not enabled');
      }
      
      // Show notification
      await _showLocalNotification(alert);
      
      // Update badge
      await updateBadge(await getUnreadCount());
      
    } on NotificationException catch (e) {
      // Log error but don't crash
      debugPrint('Notification error: ${e.message}');
    }
  }
}
```

## Testing Strategy

### Unit Tests

1. **Model Tests**
   - User model serialization/deserialization
   - Device model validation
   - Event model calculations

2. **Service Tests**
   - API service mock responses
   - MQTT manager connection handling
   - Notification service permission checks

3. **Utility Tests**
   - Date formatting
   - Magnitude calculations
   - QR code parsing

### Integration Tests

1. **API Integration**
   - Login flow
   - Device registration
   - Event fetching

2. **MQTT Integration**
   - Connection establishment
   - Message receiving
   - Subscription management

3. **Notification Integration**
   - Local notification display
   - FCM token registration
   - Badge counter updates

### Widget Tests

1. **Screen Tests**
   - Home screen rendering
   - Alerts screen filtering
   - Settings screen state changes

2. **Component Tests**
   - Device card display
   - Event list rendering
   - QR scanner functionality

### End-to-End Tests

1. **User Flows**
   - Complete registration and login
   - Add device via QR code
   - Receive and view alert
   - Change settings and verify behavior

2. **Critical Paths**
   - Emergency alert notification
   - Lock screen alert display
   - Badge counter accuracy

## Security Considerations

### Authentication & Authorization

1. **JWT Token Management**
   - Store tokens in secure storage
   - Implement token refresh mechanism
   - Clear tokens on logout

2. **API Security**
   - All requests include Authorization header
   - Validate token on backend
   - Implement rate limiting

### Data Protection

1. **Sensitive Data Storage**
   - Use flutter_secure_storage for tokens
   - Encrypt user credentials
   - Never log sensitive information

2. **Network Security**
   - Use HTTPS for all API calls
   - Validate SSL certificates
   - Implement certificate pinning for production

### MQTT Security

1. **Connection Security**
   - Use TLS/SSL for MQTT connections
   - Authenticate with username/password
   - Validate broker certificates

2. **Topic Security**
   - Subscribe only to authorized topics
   - Validate message sources
   - Sanitize incoming data

## Performance Optimization

### Mobile App

1. **State Management**
   - Use Provider for efficient rebuilds
   - Implement selective widget rebuilding
   - Cache frequently accessed data

2. **Network Optimization**
   - Implement request caching
   - Use pagination for large lists
   - Compress images and assets

3. **MQTT Optimization**
   - Limit message frequency
   - Use QoS appropriately
   - Implement message batching

### Backend

1. **Database Optimization**
   - Use indexes on frequently queried fields
   - Implement connection pooling
   - Cache common queries

2. **API Optimization**
   - Implement response caching
   - Use compression for responses
   - Optimize query performance

## Deployment Strategy

### Mobile App Deployment

1. **App Icon Generation**
   - Use flutter_launcher_icons package
   - Generate all required sizes for iOS and Android
   - Update app icon configuration

2. **Build Configuration**
   - Separate dev, staging, and production builds
   - Use environment-specific configurations
   - Implement code obfuscation for production

3. **Release Process**
   - Version bump
   - Generate release builds
   - Test on physical devices
   - Submit to app stores

### Backend Deployment

1. **Environment Setup**
   - Configure production database
   - Set up MQTT broker
   - Configure FCM credentials

2. **Deployment Process**
   - Run database migrations
   - Deploy backend server
   - Configure reverse proxy
   - Set up monitoring

## Monitoring and Analytics

### App Monitoring

1. **Crash Reporting**
   - Integrate Firebase Crashlytics
   - Log critical errors
   - Track error rates

2. **Performance Monitoring**
   - Track app startup time
   - Monitor API response times
   - Measure MQTT latency

3. **User Analytics**
   - Track feature usage
   - Monitor user engagement
   - Analyze notification effectiveness

### Backend Monitoring

1. **Server Monitoring**
   - CPU and memory usage
   - API response times
   - Error rates

2. **Database Monitoring**
   - Query performance
   - Connection pool status
   - Storage usage

3. **MQTT Monitoring**
   - Connection status
   - Message throughput
   - Topic subscription counts
