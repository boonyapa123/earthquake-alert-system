# เปลี่ยน App Icon เป็นโลโก้ eQNode

## ขั้นตอนที่ 1: บันทึกรูปโลโก้

1. บันทึกรูปโลโก้ eQNode (สีแดง) ที่คุณส่งมาเป็นไฟล์ PNG
2. ตั้งชื่อไฟล์ว่า `app_icon.png`
3. วางไฟล์ที่ `assets/icon/app_icon.png`

## ขั้นตอนที่ 2: ติดตั้ง Dependencies

```bash
flutter pub get
```

## ขั้นตอนที่ 3: สร้าง App Icons

```bash
flutter pub run flutter_launcher_icons
```

คำสั่งนี้จะสร้าง icon ทุกขนาดโดยอัตโนมัติ:
- mipmap-mdpi (48x48)
- mipmap-hdpi (72x72)
- mipmap-xhdpi (96x96)
- mipmap-xxhdpi (144x144)
- mipmap-xxxhdpi (192x192)

## ขั้นตอนที่ 4: บิ้ว APK

```bash
flutter clean
flutter build apk --release
```

## ผลลัพธ์

APK ใหม่จะมีโลโก้ eQNode สีแดงเป็น app icon

## หมายเหตุ

- รูป `app_icon.png` ควรมีขนาดอย่างน้อย 512x512 pixels
- พื้นหลังสีแดง (#D32F2F) จะถูกใช้สำหรับ adaptive icon
- ถ้าต้องการเปลี่ยนสีพื้นหลัง แก้ไขใน `pubspec.yaml`:
  ```yaml
  flutter_launcher_icons:
    adaptive_icon_background: "#D32F2F"  # เปลี่ยนสีที่นี่
  ```

## ตัวอย่างโครงสร้างไฟล์

```
earthquake_app_new2/
├── assets/
│   └── icon/
│       └── app_icon.png  ← วางรูปโลโก้ที่นี่
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── res/
│                   ├── mipmap-mdpi/ic_launcher.png
│                   ├── mipmap-hdpi/ic_launcher.png
│                   ├── mipmap-xhdpi/ic_launcher.png
│                   ├── mipmap-xxhdpi/ic_launcher.png
│                   └── mipmap-xxxhdpi/ic_launcher.png
└── pubspec.yaml
```

## Troubleshooting

### ถ้า icon ไม่เปลี่ยน:
1. ลบแอปออกจากมือถือ
2. รัน `flutter clean`
3. บิ้ว APK ใหม่
4. ติดตั้ง APK ใหม่

### ถ้า icon มีพื้นหลังสีขาว:
- ตรวจสอบว่ารูป `app_icon.png` มีพื้นหลังสีแดงอยู่แล้ว
- หรือแก้ไข `adaptive_icon_background` ใน `pubspec.yaml`
