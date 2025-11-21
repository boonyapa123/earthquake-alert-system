#!/bin/bash

# 🚀 eQNode System Starter
# สคริปต์สำหรับเริ่มระบบทั้งหมด (Backend + Flutter App)

set -e

echo "🚀 eQNode System Starter"
echo "========================"
echo ""

# สี
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ฟังก์ชันตรวจสอบ command
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ Error: $1 ไม่ได้ติดตั้ง${NC}"
        echo "   กรุณาติดตั้ง $1 ก่อน"
        exit 1
    fi
}

# ตรวจสอบ dependencies
echo "🔍 ตรวจสอบ dependencies..."
check_command "node"
check_command "npm"
check_command "docker"
check_command "flutter"
check_command "mosquitto_sub"
echo -e "${GREEN}✅ Dependencies ครบถ้วน${NC}"
echo ""

# ขั้นตอนที่ 1: เริ่ม PostgreSQL
echo "📦 ขั้นตอนที่ 1: เริ่ม PostgreSQL..."
cd backend

if docker ps | grep -q postgres; then
    echo -e "${GREEN}✅ PostgreSQL ทำงานอยู่แล้ว${NC}"
else
    echo "   กำลังเริ่ม PostgreSQL..."
    docker-compose up -d postgres
    echo "   รอ PostgreSQL พร้อม (10 วินาที)..."
    sleep 10
    echo -e "${GREEN}✅ PostgreSQL พร้อมแล้ว${NC}"
fi
echo ""

# ขั้นตอนที่ 2: Setup Database
echo "🗄️  ขั้นตอนที่ 2: Setup Database..."
if [ ! -f ".db_initialized" ]; then
    echo "   กำลังสร้าง database และ tables..."
    npm run db:setup
    touch .db_initialized
    echo -e "${GREEN}✅ Database setup เสร็จสิ้น${NC}"
else
    echo -e "${GREEN}✅ Database setup แล้ว (ข้าม)${NC}"
fi
echo ""

# ขั้นตอนที่ 3: ติดตั้ง Backend Dependencies
echo "📚 ขั้นตอนที่ 3: ติดตั้ง Backend Dependencies..."
if [ ! -d "node_modules" ]; then
    echo "   กำลังติดตั้ง npm packages..."
    npm install
    echo -e "${GREEN}✅ Dependencies ติดตั้งเสร็จสิ้น${NC}"
else
    echo -e "${GREEN}✅ Dependencies ติดตั้งแล้ว (ข้าม)${NC}"
fi
echo ""

# ขั้นตอนที่ 4: เริ่ม Backend Server
echo "🖥️  ขั้นตอนที่ 4: เริ่ม Backend Server..."
echo "   Backend จะทำงานที่: http://10.134.94.222:3000"
echo ""

# เปิด terminal ใหม่สำหรับ Backend
osascript -e 'tell application "Terminal"
    do script "cd '"$(pwd)"' && echo \"🖥️  Backend Server\" && echo \"==================\" && echo \"\" && npm run dev"
end tell' &

sleep 3
echo -e "${GREEN}✅ Backend Server เริ่มทำงานแล้ว${NC}"
echo ""

# ขั้นตอนที่ 5: ทดสอบ Backend
echo "🧪 ขั้นตอนที่ 5: ทดสอบ Backend..."
echo "   รอ Backend พร้อม (5 วินาที)..."
sleep 5

if curl -s http://10.134.94.222:3000/api/v1/health > /dev/null; then
    echo -e "${GREEN}✅ Backend ทำงานปกติ${NC}"
else
    echo -e "${YELLOW}⚠️  Backend อาจยังไม่พร้อม กรุณาตรวจสอบ terminal${NC}"
fi
echo ""

# ขั้นตอนที่ 6: ทดสอบ MQTT Connection
echo "📡 ขั้นตอนที่ 6: ทดสอบ MQTT Connection..."
echo "   กำลังทดสอบการเชื่อมต่อ mqtt.uiot.cloud..."

timeout 3 mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
    -u ethernet -P ei8jZz87wx \
    -t "eqnode.tarita/hub/#" -C 1 > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ MQTT เชื่อมต่อสำเร็จ${NC}" || \
    echo -e "${YELLOW}⚠️  MQTT อาจมีปัญหา กรุณาตรวจสอบ credentials${NC}"
echo ""

# ขั้นตอนที่ 7: เปิด MQTT Monitor
echo "📊 ขั้นตอนที่ 7: เปิด MQTT Monitor..."
osascript -e 'tell application "Terminal"
    do script "echo \"📊 MQTT Monitor\" && echo \"===============\" && echo \"\" && echo \"Listening to: eqnode.tarita/hub/#\" && echo \"\" && mosquitto_sub -h mqtt.uiot.cloud -p 1883 -u ethernet -P ei8jZz87wx -t \"eqnode.tarita/hub/#\" -v"
end tell' &

sleep 2
echo -e "${GREEN}✅ MQTT Monitor เปิดแล้ว${NC}"
echo ""

# กลับไปที่ root directory
cd ..

# ขั้นตอนที่ 8: เริ่ม Flutter App
echo "📱 ขั้นตอนที่ 8: เริ่ม Flutter App..."
echo ""
echo "เลือก device ที่ต้องการรัน:"
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
        echo -e "${RED}❌ ตัวเลือกไม่ถูกต้อง${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ ระบบทำงานครบถ้วนแล้ว!${NC}"
echo ""
echo "📝 หมายเหตุ:"
echo "   - Backend: http://10.134.94.222:3000"
echo "   - MQTT: mqtt.uiot.cloud:1883"
echo "   - Logs: ดูใน terminal ที่เปิดขึ้นมา"
echo ""
echo "🛑 หยุดระบบ:"
echo "   - กด Ctrl+C ใน terminal นี้"
echo "   - รัน: docker-compose down (ใน backend/)"
echo ""
