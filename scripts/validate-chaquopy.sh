#!/bin/bash
set -e

# Chaquopy Configuration Validation Script
# Verifies that Chaquopy is properly configured in the Android project

echo "========================================="
echo "Chaquopy Configuration Validator"
echo "========================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check settings.gradle.kts
echo "Checking settings.gradle.kts..."
if grep -q "chaquo.com/maven" "$PROJECT_ROOT/android/settings.gradle.kts"; then
    success "Chaquopy Maven repository found in settings.gradle.kts"
else
    error "Chaquopy Maven repository missing in settings.gradle.kts"
fi

if grep -q 'id("com.chaquo.python")' "$PROJECT_ROOT/android/settings.gradle.kts"; then
    success "Chaquopy plugin registered in settings.gradle.kts"
else
    error "Chaquopy plugin not registered in settings.gradle.kts"
fi
echo ""

# Check build.gradle.kts
echo "Checking build.gradle.kts..."
if grep -q "chaquo.com/maven" "$PROJECT_ROOT/android/build.gradle.kts"; then
    success "Chaquopy Maven repository found in build.gradle.kts"
else
    error "Chaquopy Maven repository missing in build.gradle.kts"
fi
echo ""

# Check app/build.gradle.kts
echo "Checking app/build.gradle.kts..."
if grep -q 'id("com.chaquo.python")' "$PROJECT_ROOT/android/app/build.gradle.kts"; then
    success "Chaquopy plugin applied in app/build.gradle.kts"
else
    error "Chaquopy plugin not applied in app/build.gradle.kts"
fi

if grep -q 'python {' "$PROJECT_ROOT/android/app/build.gradle.kts"; then
    success "Chaquopy python configuration block found"
else
    error "Chaquopy python configuration block missing"
fi

if grep -q 'version = "3.11"' "$PROJECT_ROOT/android/app/build.gradle.kts"; then
    success "Python version 3.11 configured"
else
    warning "Python version may not be set to 3.11"
fi

if grep -q 'install("yt-dlp' "$PROJECT_ROOT/android/app/build.gradle.kts"; then
    success "yt-dlp pip package configured"
else
    error "yt-dlp pip package not configured"
fi
echo ""

# Check Python source directory
echo "Checking Python source directory..."
if [ -d "$PROJECT_ROOT/android/app/src/main/python" ]; then
    success "Python source directory exists"
else
    error "Python source directory missing: android/app/src/main/python"
fi

if [ -f "$PROJECT_ROOT/android/app/src/main/python/ytdlp_wrapper.py" ]; then
    success "ytdlp_wrapper.py found"
else
    error "ytdlp_wrapper.py missing"
fi
echo ""

# Check Kotlin code
echo "Checking Kotlin code..."
if grep -q 'import com.chaquo.python' "$PROJECT_ROOT/android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt"; then
    success "Chaquopy imports found in DownloaderBridge.kt"
else
    error "Chaquopy imports missing in DownloaderBridge.kt"
fi

if grep -q 'AndroidPlatform.start' "$PROJECT_ROOT/android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt"; then
    success "Python initialization code found"
else
    error "Python initialization code missing"
fi

if grep -q 'getModule("ytdlp_wrapper")' "$PROJECT_ROOT/android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt"; then
    success "Python module calls found"
else
    error "Python module calls missing"
fi

# Check that old native binary references are removed
if grep -q 'libytdlp_bridge.so' "$PROJECT_ROOT/android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt"; then
    error "Old libytdlp_bridge.so references still present"
else
    success "Old native binary references removed"
fi
echo ""

# Check .gitignore
echo "Checking .gitignore..."
if grep -q '__pycache__/' "$PROJECT_ROOT/.gitignore"; then
    success "Python cache patterns in .gitignore"
else
    warning "Python cache patterns missing from .gitignore"
fi

if grep -q '.chaquopy' "$PROJECT_ROOT/.gitignore"; then
    success "Chaquopy intermediates in .gitignore"
else
    warning "Chaquopy intermediate patterns missing from .gitignore"
fi
echo ""

# Check documentation
echo "Checking documentation..."
if [ -f "$PROJECT_ROOT/CHAQUOPY_MIGRATION.md" ]; then
    success "CHAQUOPY_MIGRATION.md found"
else
    warning "CHAQUOPY_MIGRATION.md missing"
fi

if [ -f "$PROJECT_ROOT/android/app/src/main/python/README.md" ]; then
    success "Python directory README.md found"
else
    warning "Python directory README.md missing"
fi
echo ""

# Summary
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Chaquopy is properly configured."
    echo ""
    echo "Next steps:"
    echo "  1. Run './gradlew app:assembleDebug' to build"
    echo "  2. First build will download Python runtime and pip packages"
    echo "  3. Test on device/emulator"
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    echo "Please fix the errors above before building."
    exit 1
fi
