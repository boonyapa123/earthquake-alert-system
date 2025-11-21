# 🔥 Firebase Setup Guide

## 📋 ภาพรวม

คู่มือนี้จะแนะนำวิธีการตั้งค่า Firebase Cloud Messaging (FCM) สำหรับระบบแจ้งเตือนแผ่นดินไหว

---

## 🎯 Firebase Project

**Project Name**: `earthquake-api-server`
**Project ID**: `earthquake-api-server`
**Console**: https://console.firebase.google.com/project/earthquake-api-server

---

## 🔧 Backend Setup (Node.js)

### ขั้นตอนที่ 1: ติดตั้ง Firebase Admin SDK

```bash
cd backend
npm install firebase-admin
```

### ขั้นตอนที่ 2: ดาวน์โหลด Service Account Key

1. ไปที่ Firebase Console: https://console.firebase.google.com/project/earthquake-api-server
2. คลิก **⚙️ Project Settings**
3. ไปที่แท็บ **Service accounts**
4. คลิก **Generate new private key**
5. บันทึกไฟล์ JSON ที่ได้

### ขั้นตอนที่ 3: วาง Service Account Key

```bash
# วางไฟล์ที่ดาวน์โหลดมาที่
backend/serviceAccountKey.json

# ตรวจสอบว่าไฟล์อยู่ที่ถูกต้อง
ls -la backend/serviceAccountKey.json
```

**⚠️ สำคัญ**: ไฟล์นี้มี credentials ที่ sensitive ห้าม commit ลง Git!

### ขั้นตอนที่ 4: ตรวจสอบ .env

```bash
# backend/.env
FIREBASE_PROJECT_ID=earthquake-api-server
```

### ขั้นตอนที่ 5: Restart Backend

```bash
cd backend
npm run dev
```

**ตรวจสอบ logs:**
```
✅ Firebase Admin SDK initialized successfully
   Project: earthquake-api-server
```

---

## 📱 Mobile App Setup (Flutter)

### ขั้นตอนที่ 1: เพิ่ม Firebase ใน Flutter Project

#### สำหรับ iOS:

1. ไปที่ Firebase Console → Project Settings → iOS apps
2. คลิก **Add app**
3. ใส่ Bundle ID: `com.example.earthquakeAppNew` (หรือตาม `ios/Runner.xcodeproj`)
4. ดาวน์โหลด `GoogleService-Info.plist`
5. วางไฟล์ที่ `ios/Runner/GoogleService-Info.plist`

#### สำหรับ Android:

1. ไปที่ Firebase Console → Project Settings → Android apps
2. คลิก **Add app**
3. ใส่ Package name: `com.example.earthquake_app_new` (ตาม `android/app/build.gradle`)
4. ดาวน์โหลด `google-services.json`
5. วางไฟล์ที่ `android/app/google-services.json`

### ขั้นตอนที่ 2: ติดตั้ง FlutterFire

```bash
# ติดตั้ง FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=earthquake-api-server
```

### ขั้นตอนที่ 3: เพิ่ม Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

```bash
flutter pub get
```

### ขั้นตอนที่ 4: Initialize Firebase ใน App

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### ขั้นตอนที่ 5: Setup FCM Token

```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');
      
      // Subscribe to topic
      await _messaging.subscribeToTopic('earthquake_alerts');
      print('✅ Subscribed to earthquake_alerts');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Foreground message: ${message.notification?.title}');
        // Show local notification
      });
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message: ${message.notification?.title}');
}
```

---

## 🧪 การทดสอบ

### ทดสอบจาก Backend

```bash
# ส่ง test notification
curl -X POST http://localhost:3000/api/v1/test/notification \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "This is a test message"
  }'
```

### ทดสอบจาก Firebase Console

1. ไปที่ Firebase Console → Cloud Messaging
2. คลิก **Send your first message**
3. ใส่:
   - **Notification title**: Test Alert
   - **Notification text**: Testing earthquake alert
   - **Target**: Topic → `earthquake_alerts`
4. คลิก **Send message**

### ทดสอบด้วย MQTT

```bash
# ส่งข้อมูลแผ่นดินไหวที่มี magnitude >= 3.0
mosquitto_pub -h mqtt.uiot.cloud -p 1883 \
  -u ethernet -P "ei8jZz87wx" \
  -t "eqnode.tarita/hub/data" \
  -m '{
    "did": "TEST-001",
    "pga": 0.15,
    "rms": 0.12,
    "lat": 13.7563,
    "lon": 100.5018,
    "ts": "'$(date -u +"%Y-%m-%d %H:%M:%S")'"
  }'
```

---

## 📊 Notification Flow

```
Sensor detects earthquake (magnitude >= 3.0)
    ↓
MQTT → Backend
    ↓
Backend calculates magnitude
    ↓
Backend creates notification
    ↓
Firebase Cloud Messaging
    ↓
Mobile App receives notification
    ↓
Shows alert with sound/vibration
```

---

## 🔐 Security Best Practices

### Backend:
- ✅ ไฟล์ `serviceAccountKey.json` อยู่ใน `.gitignore`
- ✅ ไม่ commit credentials ลง Git
- ✅ ใช้ environment variables
- ✅ Restrict API keys ใน Firebase Console

### Mobile App:
- ✅ `google-services.json` และ `GoogleService-Info.plist` ใน `.gitignore`
- ✅ ใช้ FlutterFire CLI สำหรับ configuration
- ✅ Validate notification data
- ✅ Handle permission properly

---

## 📝 Notification Message Format

### จาก Backend:

```json
{
  "notification": {
    "title": "⚠️ แผ่นดินไหวปานกลาง",
    "body": "ขนาด 4.06 ริกเตอร์ จากเซ็นเซอร์ EQC-28562faa0b60"
  },
  "data": {
    "type": "earthquake_alert",
    "magnitude": "4.06",
    "severity": "moderate",
    "deviceId": "EQC-28562faa0b60",
    "latitude": "13.903131",
    "longitude": "100.532959",
    "timestamp": "2025-11-20 16:07:01.560"
  },
  "android": {
    "priority": "high",
    "notification": {
      "sound": "default",
      "channelId": "earthquake_alerts"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

---

## 🐛 Troubleshooting

### Backend ไม่ส่ง notification

**ตรวจสอบ:**
```bash
# ดู logs
cd backend && npm run dev

# ควรเห็น:
✅ Firebase Admin SDK initialized successfully
```

**แก้ไข:**
- ตรวจสอบว่ามีไฟล์ `serviceAccountKey.json`
- ตรวจสอบ `FIREBASE_PROJECT_ID` ใน `.env`
- ลอง restart backend

### Mobile App ไม่ได้รับ notification

**ตรวจสอบ:**
```dart
// ดู FCM token
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

**แก้ไข:**
- ตรวจสอบ permission
- ตรวจสอบว่า subscribe topic แล้ว
- ทดสอบส่งจาก Firebase Console
- ตรวจสอบ `google-services.json` / `GoogleService-Info.plist`

### Notification ไม่มีเสียง

**Android:**
```dart
// สร้าง notification channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'earthquake_alerts',
  'Earthquake Alerts',
  description: 'Notifications for earthquake alerts',
  importance: Importance.high,
  playSound: true,
);
```

**iOS:**
- ตรวจสอบ permission
- ตรวจสอบ Do Not Disturb mode
- ตรวจสอบ notification settings

---

## 📚 Resources

- [Firebase Console](https://console.firebase.google.com/project/earthquake-api-server)
- [Firebase Admin SDK Docs](https://firebase.google.com/docs/admin/setup)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [FCM Docs](https://firebase.google.com/docs/cloud-messaging)

---

**Last Updated**: November 20, 2025
