#!/bin/bash

# Build Environment Diagnostic Script
# Run this to check if your environment is properly configured

echo "========================================"
echo "Build Environment Diagnostics"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check Flutter
echo "Checking Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -n 1)
    check_ok "Flutter installed: $FLUTTER_VERSION"
else
    check_fail "Flutter not found in PATH"
fi
echo ""

# Check Android SDK
echo "Checking Android SDK..."
if [ -n "$ANDROID_HOME" ]; then
    check_ok "ANDROID_HOME set: $ANDROID_HOME"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    check_ok "ANDROID_SDK_ROOT set: $ANDROID_SDK_ROOT"
elif [ -d "$HOME/Android/Sdk" ]; then
    check_warn "Android SDK found at ~/Android/Sdk but ANDROID_HOME not set"
    echo "  Set it with: export ANDROID_HOME=\$HOME/Android/Sdk"
else
    check_fail "Android SDK not found"
fi
echo ""

# Check NDK
echo "Checking Android NDK..."
if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME/ndk" ]; then
    NDK_VERSIONS=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | wc -l)
    if [ "$NDK_VERSIONS" -gt 0 ]; then
        LATEST_NDK=$(ls -1 "$ANDROID_HOME/ndk" | sort -V | tail -n 1)
        check_ok "NDK installed: version $LATEST_NDK"
    else
        check_warn "NDK directory exists but no versions installed"
    fi
elif [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
    NDK_VERSIONS=$(ls -1 "$ANDROID_SDK_ROOT/ndk" 2>/dev/null | wc -l)
    if [ "$NDK_VERSIONS" -gt 0 ]; then
        LATEST_NDK=$(ls -1 "$ANDROID_SDK_ROOT/ndk" | sort -V | tail -n 1)
        check_ok "NDK installed: version $LATEST_NDK"
    fi
else
    check_warn "NDK not found (will use Flutter's default)"
fi
echo ""

# Check local.properties
echo "Checking Android configuration..."
if [ -f "$PROJECT_ROOT/android/local.properties" ]; then
    check_ok "local.properties exists"
    if grep -q "sdk.dir" "$PROJECT_ROOT/android/local.properties"; then
        check_ok "  - sdk.dir configured"
    else
        check_warn "  - sdk.dir not configured"
    fi
else
    check_fail "local.properties missing (run setup script)"
fi
echo ""

# Check Gradle
echo "Checking Gradle..."
if [ -f "$PROJECT_ROOT/android/gradlew" ]; then
    check_ok "Gradle wrapper exists"
    if [ -x "$PROJECT_ROOT/android/gradlew" ]; then
        check_ok "Gradle wrapper is executable"
    else
        check_warn "Gradle wrapper not executable (fixing...)"
        chmod +x "$PROJECT_ROOT/android/gradlew"
    fi
else
    check_fail "Gradle wrapper missing"
fi
echo ""

# Check build.gradle.kts
echo "Checking build configuration..."
if [ -f "$PROJECT_ROOT/android/app/build.gradle.kts" ]; then
    check_ok "build.gradle.kts exists"
    if grep -q "tensorflow-lite" "$PROJECT_ROOT/android/app/build.gradle.kts"; then
        check_ok "  - TensorFlow Lite dependencies configured"
    else
        check_warn "  - TensorFlow Lite dependencies not found"
    fi
else
    check_fail "build.gradle.kts missing"
fi
echo ""

# Check disk space
echo "Checking disk space..."
if command -v df &> /dev/null; then
    AVAILABLE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    check_ok "Available disk space: $AVAILABLE"
fi
echo ""

# Check internet connectivity
echo "Checking internet connectivity..."
if command -v curl &> /dev/null; then
    if curl -s --head --request GET https://pub.dev > /dev/null; then
        check_ok "Internet connection available"
    else
        check_warn "Cannot reach pub.dev (needed for Flutter dependencies)"
    fi
elif command -v wget &> /dev/null; then
    if wget -q --spider https://pub.dev; then
        check_ok "Internet connection available"
    else
        check_warn "Cannot reach pub.dev (needed for Flutter dependencies)"
    fi
fi
echo ""

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
echo ""
echo "If any checks failed, run the setup script:"
echo "  bash scripts/setup-android-env.sh"
echo ""
echo "For detailed troubleshooting, see SETUP.md"
echo ""
