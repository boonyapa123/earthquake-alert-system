# แก้ไข TimeoutException ใน APK Build

## ปัญหา
เมื่อบิ้ว APK และติดตั้งบนเครื่องจริง หน้า Login และ Register จะขึ้น TimeoutException

## สาเหตุ
1. **baseUrl ใช้ `10.0.2.2`** - IP นี้ใช้ได้เฉพาะ Android Emulator เท่านั้น ไม่สามารถใช้บนเครื่องจริงได้
2. **Network Security Config** - ไม่ได้อนุญาตให้เชื่อมต่อกับ IP ของ production server (152.42.248.201)

## การแก้ไข

### 1. อัปเดต baseUrl ใน `lib/config/app_config.dart`
```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://152.42.248.201:3000/api/v1'; // ใช้ production server
    case Environment.staging:
      return 'http://152.42.248.201:3000/api/v1';
    case Environment.production:
      return 'http://152.42.248.201:3000/api/v1';
  }
}
```

### 2. เพิ่ม timeout ใน `lib/config/app_config.dart`
```dart
static Duration get apiTimeout {
  switch (_environment) {
    case Environment.development:
      return const Duration(seconds: 60); // เพิ่ม timeout
    case Environment.staging:
      return const Duration(seconds: 30);
    case Environment.production:
      return const Duration(seconds: 30);
  }
}
```

### 3. อัปเดต Network Security Config
เพิ่ม IP ของ production server ใน `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<domain includeSubdomains="true">152.42.248.201</domain>
```

## วิธีบิ้ว APK ใหม่
```bash
flutter clean
flutter build apk --release
```

## ผลลัพธ์
- APK ถูกบิ้วที่: `build/app/outputs/flutter-apk/app-release.apk`
- ขนาด: 66.5MB
- สามารถเชื่อมต่อกับ backend server ได้แล้ว

## ทดสอบ
1. ติดตั้ง APK บนเครื่องจริง
2. เปิดแอป
3. ลองสมัครสมาชิกหรือเข้าสู่ระบบ
4. ควรเชื่อมต่อกับ backend ได้โดยไม่มี TimeoutException

## หมายเหตุ
- Backend server ต้องทำงานอยู่ที่ `http://152.42.248.201:3000`
- ตรวจสอบว่า backend ทำงานด้วย: `curl http://152.42.248.201:3000/api/v1/auth/login`
