# วิธีเปลี่ยน App Icon เป็นโลโก้ eQNode

## ขั้นตอนที่ 1: เตรียมรูป Icon

1. บันทึกรูปโลโก้ eQNode (สีแดง พื้นหลังแดง ตัวอักษรขาว) เป็นไฟล์ PNG
2. ขนาดแนะนำ: 1024x1024 pixels (สี่เหลี่ยมจัตุรัส)

## ขั้นตอนที่ 2: สร้าง App Icon ด้วย Online Tool

### วิธีที่ 1: ใช้ Android Asset Studio (แนะนำ)
1. ไปที่: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
2. อัปโหลดรูปโลโก้ eQNode
3. ตั้งค่า:
   - **Foreground**: อัปโหลดรูปโลโก้
   - **Background**: เลือกสีแดง (#D32F2F หรือ #C62828)
   - **Shape**: None (ใช้รูปเต็ม)
   - **Padding**: 0%
4. กด **Download** เพื่อดาวน์โหลดไฟล์ ZIP

### วิธีที่ 2: ใช้ flutter_launcher_icons (แนะนำสำหรับ Flutter)
1. เพิ่ม package ใน `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#D32F2F"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

2. วางรูปโลโก้ที่ `assets/icon/app_icon.png`

3. รันคำสั่ง:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## ขั้นตอนที่ 3: แทนที่ไฟล์ Icon

หลังจากได้ไฟล์ icon แล้ว ให้คัดลอกไปยังโฟลเดอร์เหล่านี้:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png       (48x48)
├── mipmap-hdpi/ic_launcher.png       (72x72)
├── mipmap-xhdpi/ic_launcher.png      (96x96)
├── mipmap-xxhdpi/ic_launcher.png     (144x144)
└── mipmap-xxxhdpi/ic_launcher.png    (192x192)
```

## ขั้นตอนที่ 4: บิ้ว APK ใหม่

```bash
flutter clean
flutter build apk --release
```

## ขนาด Icon ที่ต้องการ

| Density | Size | Folder |
|---------|------|--------|
| mdpi | 48x48 | mipmap-mdpi |
| hdpi | 72x72 | mipmap-hdpi |
| xhdpi | 96x96 | mipmap-xhdpi |
| xxhdpi | 144x144 | mipmap-xxhdpi |
| xxxhdpi | 192x192 | mipmap-xxxhdpi |

## หมายเหตุ

- ใช้รูปพื้นหลังสีแดง (#D32F2F) เหมือนโลโก้
- ตัวอักษร "eQNode" และ "Earthquake!" เป็นสีขาว
- ไม่ต้องมีขอบหรือ padding เพิ่มเติม
- รูปควรเป็นสี่เหลี่ยมจัตุรัส

## ตัวอย่างโค้ดสร้าง Icon ด้วย ImageMagick (ถ้ามี)

```bash
# สร้าง icon ขนาดต่างๆ จากรูปต้นฉบับ
convert app_icon_1024.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert app_icon_1024.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert app_icon_1024.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert app_icon_1024.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert app_icon_1024.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

## ผลลัพธ์

หลังจากบิ้ว APK ใหม่ แอปจะแสดงโลโก้ eQNode สีแดงเป็น app icon บนหน้าจอมือถือ
