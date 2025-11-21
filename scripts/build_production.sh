#!/bin/bash

# Build script for Production environment

echo "Building eQNode for Production..."

# Verify we're not in debug mode
if [ "$1" != "--confirm-production" ]; then
    echo "ERROR: Production build requires confirmation"
    echo "Usage: $0 --confirm-production"
    exit 1
fi

# Set environment variables
export ENVIRONMENT=production

# Clean previous builds
flutter clean
flutter pub get

# Build production APK
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BUILD_NUMBER=$(date +%s) \
  --target-platform android-arm,android-arm64,android-x64 \
  --obfuscate \
  --split-debug-info=build/debug-info

# Build App Bundle for Play Store
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BUILD_NUMBER=$(date +%s) \
  --obfuscate \
  --split-debug-info=build/debug-info

echo "Production build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB location: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "⚠️  IMPORTANT: Upload debug symbols to Firebase Crashlytics"
echo "Debug info location: build/debug-info"