#!/bin/bash
set -e

# Quick Build Script for Android APK
# Validates environment and builds the APK

echo "========================================"
echo "Android APK Build"
echo "========================================"
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_TYPE="${1:-debug}"

# Validate build type
if [ "$BUILD_TYPE" != "debug" ] && [ "$BUILD_TYPE" != "release" ]; then
    echo "Usage: $0 [debug|release]"
    echo "  Default: debug"
    exit 1
fi

# Check if setup has been run
if [ ! -f "$PROJECT_ROOT/android/local.properties" ]; then
    echo "⚠️  local.properties not found!"
    echo "Running setup script first..."
    echo ""
    bash "$PROJECT_ROOT/scripts/setup-android-env.sh"
    echo ""
fi

# Validate native libraries
echo "Validating native libraries..."
cd "$PROJECT_ROOT/android"
if [ -x ./gradlew ]; then
    ./gradlew validateNativeLibs
else
    echo "⚠️  Gradle wrapper not executable, fixing..."
    chmod +x ./gradlew
    ./gradlew validateNativeLibs
fi
echo ""

# Build the APK
echo "Building $BUILD_TYPE APK..."
cd "$PROJECT_ROOT"

if command -v flutter &> /dev/null; then
    flutter build apk --$BUILD_TYPE
    
    echo ""
    echo "========================================"
    echo "✓ Build completed successfully!"
    echo "========================================"
    echo ""
    
    APK_PATH="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
    if [ -f "$PROJECT_ROOT/$APK_PATH" ]; then
        APK_SIZE=$(du -h "$PROJECT_ROOT/$APK_PATH" | cut -f1)
        echo "APK Location: $APK_PATH"
        echo "APK Size: $APK_SIZE"
        echo ""
        echo "To install on connected device:"
        echo "  flutter install"
        echo ""
        echo "Or manually:"
        echo "  adb install $APK_PATH"
    fi
else
    echo "❌ Flutter not found in PATH"
    echo "Please install Flutter or add it to PATH"
    exit 1
fi
