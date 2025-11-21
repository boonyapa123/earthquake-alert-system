#!/bin/bash

# 🎮 eQNode Simulation Runner
# สคริปต์สำหรับรันแอพในโหมด Simulation

echo "🎮 eQNode Simulation Mode"
echo "=========================="
echo ""

# ตรวจสอบว่ามี Flutter หรือไม่
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter ไม่ได้ติดตั้ง"
    echo "   กรุณาติดตั้ง Flutter จาก https://flutter.dev"
    exit 1
fi

echo "✅ Flutter version:"
flutter --version | head -1
echo ""

# แสดงรายการ devices
echo "📱 Available Devices:"
flutter devices
echo ""

# ถามผู้ใช้ว่าต้องการรันบน device ไหน
echo "🎯 เลือก device ที่ต้องการรัน:"
echo "1) iOS Simulator"
echo "2) Android Emulator"
echo "3) Chrome (Web)"
echo "4) ดูรายการทั้งหมด"
echo ""
read -p "เลือก (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🍎 กำลังรันบน iOS Simulator..."
        flutter run -d "iPhone 15 Pro"
        ;;
    2)
        echo ""
        echo "🤖 กำลังรันบน Android Emulator..."
        flutter run
        ;;
    3)
        echo ""
        echo "🌐 กำลังรันบน Chrome..."
        flutter run -d chrome
        ;;
    4)
        echo ""
        echo "📋 รายการ devices ทั้งหมด:"
        flutter devices
        echo ""
        read -p "ใส่ device ID: " device_id
        flutter run -d "$device_id"
        ;;
    *)
        echo "❌ ตัวเลือกไม่ถูกต้อง"
        exit 1
        ;;
esac
