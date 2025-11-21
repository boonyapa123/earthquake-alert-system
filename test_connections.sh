#!/bin/bash

# 🧪 Test All Connections
# ทดสอบการเชื่อมต่อทั้งหมดในระบบ

set -e

# สี
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🧪 Testing eQNode System Connections"
echo "====================================="
echo ""

# Test 1: PostgreSQL
echo -e "${BLUE}📦 Test 1: PostgreSQL Database${NC}"
if docker ps | grep -q postgres; then
    echo -e "${GREEN}✅ PostgreSQL is running${NC}"
    
    # Test connection
    if docker exec -it $(docker ps -qf "name=postgres") pg_isready -U postgres > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL connection OK${NC}"
    else
        echo -e "${RED}❌ PostgreSQL connection failed${NC}"
    fi
else
    echo -e "${RED}❌ PostgreSQL is not running${NC}"
    echo "   Run: cd backend && docker-compose up -d postgres"
fi
echo ""

# Test 2: Backend API
echo -e "${BLUE}🖥️  Test 2: Backend API${NC}"
if curl -s http://10.134.94.222:3000/api/v1/health > /dev/null 2>&1; then
    response=$(curl -s http://10.134.94.222:3000/api/v1/health)
    echo -e "${GREEN}✅ Backend API is running${NC}"
    echo "   Response: $response"
else
    echo -e "${RED}❌ Backend API is not responding${NC}"
    echo "   Run: cd backend && npm run dev"
fi
echo ""

# Test 3: MQTT Broker
echo -e "${BLUE}📡 Test 3: MQTT Broker (mqtt.uiot.cloud)${NC}"
if command -v mosquitto_sub &> /dev/null; then
    if timeout 3 mosquitto_sub -h mqtt.uiot.cloud -p 1883 \
        -u ethernet -P ei8jZz87wx \
        -t "test" -C 1 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MQTT connection successful${NC}"
        echo "   Host: mqtt.uiot.cloud:1883"
        echo "   User: ethernet"
    else
        echo -e "${YELLOW}⚠️  MQTT connection timeout (may be normal)${NC}"
        echo "   Host: mqtt.uiot.cloud:1883"
    fi
else
    echo -e "${YELLOW}⚠️  mosquitto_sub not installed${NC}"
    echo "   Install: brew install mosquitto (macOS)"
fi
echo ""

# Test 4: Flutter
echo -e "${BLUE}📱 Test 4: Flutter SDK${NC}"
if command -v flutter &> /dev/null; then
    flutter_version=$(flutter --version | head -1)
    echo -e "${GREEN}✅ Flutter is installed${NC}"
    echo "   $flutter_version"
    
    # Check for devices
    device_count=$(flutter devices 2>/dev/null | grep -c "•" || echo "0")
    if [ "$device_count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $device_count device(s)${NC}"
    else
        echo -e "${YELLOW}⚠️  No devices found${NC}"
        echo "   Start an emulator or connect a device"
    fi
else
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "   Install from: https://flutter.dev"
fi
echo ""

# Test 5: Node.js & npm
echo -e "${BLUE}📦 Test 5: Node.js & npm${NC}"
if command -v node &> /dev/null; then
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo -e "${GREEN}✅ Node.js $node_version${NC}"
    echo -e "${GREEN}✅ npm $npm_version${NC}"
else
    echo -e "${RED}❌ Node.js is not installed${NC}"
fi
echo ""

# Test 6: Docker
echo -e "${BLUE}🐳 Test 6: Docker${NC}"
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    echo -e "${GREEN}✅ $docker_version${NC}"
    
    # Check running containers
    container_count=$(docker ps | wc -l)
    if [ "$container_count" -gt 1 ]; then
        echo -e "${GREEN}✅ $((container_count-1)) container(s) running${NC}"
    else
        echo -e "${YELLOW}⚠️  No containers running${NC}"
    fi
else
    echo -e "${RED}❌ Docker is not installed${NC}"
fi
echo ""

# Summary
echo "======================================"
echo -e "${BLUE}📊 Summary${NC}"
echo "======================================"

all_ok=true

# Check each component
if docker ps | grep -q postgres; then
    echo -e "${GREEN}✅ PostgreSQL${NC}"
else
    echo -e "${RED}❌ PostgreSQL${NC}"
    all_ok=false
fi

if curl -s http://10.134.94.222:3000/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend API${NC}"
else
    echo -e "${RED}❌ Backend API${NC}"
    all_ok=false
fi

if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter SDK${NC}"
else
    echo -e "${RED}❌ Flutter SDK${NC}"
    all_ok=false
fi

echo ""

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}🎉 All systems ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./start_system.sh"
    echo "2. Or manually: cd backend && npm run dev"
    echo "3. Then: flutter run"
else
    echo -e "${YELLOW}⚠️  Some components need attention${NC}"
    echo ""
    echo "Fix the issues above and try again"
fi

echo ""
