#!/bin/bash

# Build script for Development environment

echo "Building eQNode for Development..."

# Set environment variables
export ENVIRONMENT=development

# Build debug APK
flutter build apk --debug \
  --dart-define=ENVIRONMENT=development \
  --dart-define=BUILD_NUMBER=$(date +%s)

echo "Development build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-debug.apk"