#!/bin/bash

# Build script for Staging environment

echo "Building eQNode for Staging..."

# Set environment variables
export ENVIRONMENT=staging

# Build release APK for staging
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=BUILD_NUMBER=$(date +%s) \
  --target-platform android-arm,android-arm64,android-x64

echo "Staging build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"