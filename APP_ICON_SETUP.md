# App Icon และ Logo Setup Guide

## ขั้นตอนการเปลี่ยน App Icon

### 1. เตรียม Logo Image

1. บันทึกรูป logo ที่ต้องการเป็นไฟล์ PNG
2. ขนาดแนะนำ: 1024x1024 pixels (สำหรับ iOS) และ 512x512 pixels (สำหรับ Android)
3. ตั้งชื่อไฟล์เป็น `app_icon.png`
4. วางไฟล์ไว้ที่ root ของโปรเจค

### 2. ติดตั้ง flutter_launcher_icons Package

เพิ่มใน `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "app_icon.png"
  adaptive_icon_background: "#FFFFFF"  # สีพื้นหลังสำหรับ Android adaptive icon
  adaptive_icon_foreground: "app_icon.png"
```

### 3. Generate Icons

รันคำสั่ง:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 4. Verify Icons

- **iOS**: ตรวจสอบที่ `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Android**: ตรวจสอบที่ `android/app/src/main/res/mipmap-*/`

### 5. Update Splash Screen (Optional)

เพิ่มใน `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.3.5

flutter_native_splash:
  color: "#FFFFFF"
  image: app_icon.png
  android: true
  ios: true
```

รันคำสั่ง:

```bash
flutter pub run flutter_native_splash:create
```

## ขนาด Icons ที่ต้องการ

### iOS
- 20x20 (1x, 2x, 3x)
- 29x29 (1x, 2x, 3x)
- 40x40 (1x, 2x, 3x)
- 60x60 (2x, 3x)
- 76x76 (1x, 2x)
- 83.5x83.5 (2x)
- 1024x1024 (1x)

### Android
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192

## การใช้ Logo ในแอพ

### แสดง Logo ใน AppBar

```dart
AppBar(
  title: Row(
    children: [
      Image.asset('assets/images/logo.png', height: 32),
      const SizedBox(width: 8),
      const Text('eQNode'),
    ],
  ),
)
```

### แสดง Logo ใน Splash Screen

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset('assets/images/logo.png', width: 150),
      const SizedBox(height: 16),
      const Text('eQNode', style: TextStyle(fontSize: 24)),
    ],
  ),
)
```

## Troubleshooting

### Icons ไม่เปลี่ยน
1. Clean build: `flutter clean`
2. Rebuild: `flutter pub get && flutter run`
3. ลบแอพออกจากเครื่องแล้วติดตั้งใหม่

### Android Adaptive Icon ไม่ถูกต้อง
- ตรวจสอบว่า `adaptive_icon_background` และ `adaptive_icon_foreground` ถูกต้อง
- ใช้สีพื้นหลังที่เหมาะสม

### iOS Icon มีขอบดำ
- ตรวจสอบว่า PNG มี alpha channel
- ใช้พื้นหลังสีขาวหรือโปร่งใส
