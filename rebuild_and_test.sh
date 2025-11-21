#!/bin/bash

# Quick rebuild and test script

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              🚀 MQTT Fix - Rebuild & Test                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "📱 Step 1: Cleaning Flutter build..."
flutter clean

echo ""
echo "📦 Step 2: Getting dependencies..."
flutter pub get

echo ""
echo "🔨 Step 3: Building app..."
echo ""
echo "Choose build option:"
echo "1. Run on connected device/emulator (flutter run)"
echo "2. Build APK (flutter build apk)"
echo "3. Build iOS (flutter build ios)"
echo "4. Skip build (just clean and get deps)"
echo ""
read -p "Select option (1-4): " build_option

case $build_option in
  1)
    echo ""
    echo "🚀 Running app..."
    flutter run
    ;;
  2)
    echo ""
    echo "🔨 Building APK..."
    flutter build apk
    echo ""
    echo "✅ APK built: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  3)
    echo ""
    echo "🔨 Building iOS..."
    flutter build ios
    echo ""
    echo "✅ iOS build complete"
    ;;
  4)
    echo ""
    echo "✅ Clean and dependencies complete"
    echo ""
    echo "To run the app manually:"
    echo "  $ flutter run"
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ BUILD COMPLETE!                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Open the app and go to 'MQTT Real-time' tab"
echo "2. Verify it shows 'MQTT Status: CONNECTED'"
echo "3. Run test simulator:"
echo "   $ cd backend && node simulate-earthquake.js"
echo "4. Check that earthquake data appears in the app"
echo ""
echo "📚 Documentation:"
echo "   - QUICK_FIX.md (English)"
echo "   - แก้ไข_MQTT.md (Thai)"
echo "   - MQTT_TROUBLESHOOTING.md (Detailed guide)"
echo ""
echo "🧪 Testing Tools:"
echo "   - ./test_mqtt.sh (Interactive menu)"
echo "   - cd backend && node test-mqtt-connection.js (Listen)"
echo "   - cd backend && node simulate-earthquake.js (Send data)"
echo ""
