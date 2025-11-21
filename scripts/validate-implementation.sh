#!/bin/bash

# Implementation Validation Script
# Verifies all deliverables are in place

echo "========================================"
echo "Implementation Validation"
echo "========================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        return 1
    fi
}

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

PASS=0
FAIL=0

echo "Checking scripts..."
if check_file "scripts/setup-android-env.sh"; then ((PASS++)); else ((FAIL++)); fi
if check_file "scripts/check-build-env.sh"; then ((PASS++)); else ((FAIL++)); fi
if check_file "scripts/build-apk.sh"; then ((PASS++)); else ((FAIL++)); fi
echo ""

echo "Checking documentation..."
if check_file "SETUP.md"; then ((PASS++)); else ((FAIL++)); fi
if check_file "AUTO_SETUP_IMPLEMENTATION.md"; then ((PASS++)); else ((FAIL++)); fi
if check_file "DELIVERABLES_CHECKLIST.md"; then ((PASS++)); else ((FAIL++)); fi
if check_file "android/app/src/main/jniLibs/README.md"; then ((PASS++)); else ((FAIL++)); fi
echo ""

echo "Checking Kotlin files..."
if check_file "android/app/src/main/kotlin/com/example/insta_reel_downloader/BinaryBootstrapper.kt"; then ((PASS++)); else ((FAIL++)); fi
if check_file "android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt"; then ((PASS++)); else ((FAIL++)); fi
if check_file "android/app/src/main/kotlin/com/example/insta_reel_downloader/UpscalerBridge.kt"; then ((PASS++)); else ((FAIL++)); fi
echo ""

echo "Checking configuration..."
if check_file "android/app/build.gradle.kts"; then ((PASS++)); else ((FAIL++)); fi
if check_file "android/gradle.properties"; then ((PASS++)); else ((FAIL++)); fi
echo ""

echo "Checking directories..."
if check_dir "scripts"; then ((PASS++)); else ((FAIL++)); fi
if check_dir "android/app/src/main/jniLibs"; then ((PASS++)); else ((FAIL++)); fi
echo ""

echo "Validating script syntax..."
if bash -n scripts/setup-android-env.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} setup-android-env.sh syntax"
    ((PASS++))
else
    echo -e "${RED}✗${NC} setup-android-env.sh syntax error"
    ((FAIL++))
fi

if bash -n scripts/check-build-env.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} check-build-env.sh syntax"
    ((PASS++))
else
    echo -e "${RED}✗${NC} check-build-env.sh syntax error"
    ((FAIL++))
fi

if bash -n scripts/build-apk.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} build-apk.sh syntax"
    ((PASS++))
else
    echo -e "${RED}✗${NC} build-apk.sh syntax error"
    ((FAIL++))
fi
echo ""

echo "Checking build.gradle.kts tasks..."
if grep -q "validateNativeLibs" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} validateNativeLibs task present"
    ((PASS++))
else
    echo -e "${RED}✗${NC} validateNativeLibs task missing"
    ((FAIL++))
fi

if grep -q "validateTensorFlowLite" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} validateTensorFlowLite task present"
    ((PASS++))
else
    echo -e "${RED}✗${NC} validateTensorFlowLite task missing"
    ((FAIL++))
fi

if grep -q "cleanCorruptedCache" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} cleanCorruptedCache task present"
    ((PASS++))
else
    echo -e "${RED}✗${NC} cleanCorruptedCache task missing"
    ((FAIL++))
fi

if grep -q "setupAndBuild" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} setupAndBuild task present"
    ((PASS++))
else
    echo -e "${RED}✗${NC} setupAndBuild task missing"
    ((FAIL++))
fi

if grep -q "fullCleanBuild" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} fullCleanBuild task present"
    ((PASS++))
else
    echo -e "${RED}✗${NC} fullCleanBuild task missing"
    ((FAIL++))
fi
echo ""

echo "Checking BinaryBootstrapper extraction..."
if grep -q "class BinaryBootstrapper" android/app/src/main/kotlin/com/example/insta_reel_downloader/BinaryBootstrapper.kt; then
    echo -e "${GREEN}✓${NC} BinaryBootstrapper in separate file"
    ((PASS++))
else
    echo -e "${RED}✗${NC} BinaryBootstrapper not found in separate file"
    ((FAIL++))
fi

if ! grep -q "class BinaryBootstrapper" android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt; then
    echo -e "${GREEN}✓${NC} BinaryBootstrapper removed from DownloaderBridge"
    ((PASS++))
else
    echo -e "${RED}✗${NC} BinaryBootstrapper still in DownloaderBridge (duplicate)"
    ((FAIL++))
fi
echo ""

echo "========================================"
echo "Validation Summary"
echo "========================================"
echo ""
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Implementation is complete and ready."
    echo ""
    echo "Next steps:"
    echo "  1. Review the changes: git diff"
    echo "  2. Test setup script: bash scripts/setup-android-env.sh"
    echo "  3. Build the project: flutter build apk --debug"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please review the errors above and fix them."
    exit 1
fi
