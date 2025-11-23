# FFmpeg Binary Deployment Checklist

## Problem
App fails with exit code 127 because FFmpeg binaries are only 4 KB stubs.

## Solution Checklist

### [ ] Step 1: Understand the Issue
- [ ] Read: `EXIT_CODE_127_EXPLAINED.md` (explains why it's failing)
- [ ] Understand: Exit code 127 = "command not found"
- [ ] Know: Stubs are 4 KB, real FFmpeg is 25-40 MB per architecture

### [ ] Step 2: Download Real FFmpeg
- [ ] Go to: https://github.com/BtbN/FFmpeg-Builds/releases
- [ ] Download: `ffmpeg-latest-android-gpl-arm64.zip`
- [ ] (Optional) Download: `ffmpeg-latest-android-gpl-armv7a.zip` for 32-bit devices
- [ ] (Optional) Download: `ffmpeg-latest-android-gpl-x86_64.zip` for emulators

### [ ] Step 3: Extract Archives
- [ ] Extract arm64 zip → contains executable (usually in `bin/ffmpeg`)
- [ ] Verify file size: Should be **25-40 MB**, NOT 4 KB
- [ ] Test readability: `file extracted/ffmpeg` should show "ELF 64-bit LSB executable"

### [ ] Step 4: Replace Placeholder Files
```bash
# Copy real binary over placeholder for arm64 (main target)
cp /path/to/extracted-ffmpeg-arm64/ffmpeg \
   android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
```

- [ ] Verify replacement:
  ```bash
  ls -lh android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
  # Should show: ~30M (or similar), NOT 4.0K
  ```

### [ ] Step 5: (Optional) Add Other Architectures
If you want to support older phones (32-bit) or emulators:

```bash
# ARMv7a for older 32-bit devices
cp /path/to/extracted-ffmpeg-armv7a/ffmpeg \
   android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so

# x86_64 for Android emulators
cp /path/to/extracted-ffmpeg-x86_64/ffmpeg \
   android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so
```

- [ ] Verify all architectures have real binaries:
  ```bash
  ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so
  # All should be ~25-40MB, NONE should be 4.0K
  ```

### [ ] Step 6: Rebuild APK
```bash
cd /path/to/project
flutter clean
flutter build apk --debug
```

- [ ] Build completes without errors
- [ ] Output: `build/app/outputs/flutter-apk/app-debug.apk`
- [ ] APK size: Should be ~100-150 MB (larger due to real FFmpeg binary)

### [ ] Step 7: Install on Device/Emulator
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] Installation completes without errors
- [ ] App launches successfully
- [ ] No crashes on startup

### [ ] Step 8: Test FFmpeg Execution
1. [ ] Open app
2. [ ] Enter any Instagram reel URL (or use test URL)
3. [ ] Tap "Download"
4. [ ] Watch for errors:
   - ✓ If you see progress and then "Saved!" → **Success!** ✅
   - ✗ If you still see "exit code 127" → Check troubleshooting below
   - ✗ If you see different error → Check error message in app

### [ ] Step 9: Verify Success
- [ ] No exit code 127 error
- [ ] Video file appears in Downloads
- [ ] File is playable
- [ ] App shows completion message

---

## Troubleshooting

### Problem: Files still showing 4 KB after copying

**Check:**
```bash
ls -lh android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
```

**If showing 4 KB:**
1. You didn't copy the right file
2. The zip might have ffmpeg in different location
3. Copy went wrong

**Solution:**
```bash
# Check what's in extracted folder
cd extracted-ffmpeg-arm64
ls -lh
file ffmpeg

# If ffmpeg shows "ELF 64-bit LSB executable" and is 25+ MB:
cp ffmpeg /path/to/jniLibs/arm64-v8a/libffmpeg_bridge.so

# Verify
ls -lh /path/to/jniLibs/arm64-v8a/libffmpeg_bridge.so
```

### Problem: Build failed after copying

**Check:**
```bash
flutter clean
rm -rf build android/.gradle android/app/build
flutter build apk --debug
```

This forces a clean rebuild with new binaries.

### Problem: Still exit code 127 after rebuild and reinstall

**Check 1:** File size (must be real binary):
```bash
ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so
```
Should ALL be 25+ MB, none 4 KB.

**Check 2:** Device architecture:
```bash
adb shell getprop ro.product.cpu.abi
```

If shows `arm64-v8a`: You need arm64 binary ✓
If shows `armeabi-v7a`: You need armv7a binary (not arm64)
If shows `x86_64`: You need x86_64 binary

**Check 3:** Did you reinstall the APK?
```bash
adb uninstall com.example.insta_reel_downloader
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Old APK with stubs might still be cached.

**Check 4:** Read the app logs:
```bash
adb logcat | grep -E "DownloadPipeline|BinaryBootstrapper|FFmpeg"
```

Look for specific error messages beyond exit code 127.

### Problem: Very large APK (150+ MB)

**Expected:** APK with all 3 architectures is ~150 MB

**If too large for testing:**
Option 1: Remove unused architectures
```bash
# Keep only arm64
rm android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so
rm android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so
flutter clean && flutter build apk --debug
```

Option 2: Build APK splits (for production):
```bash
flutter build apk --split-per-abi
# Creates: app-armeabi-v7a-debug.apk, app-arm64-v8a-debug.apk, app-x86_64-debug.apk
# Each ~50-70 MB instead of 150 MB
```

---

## What If You Can't Get Binaries?

If you can't download or build FFmpeg:

**Option 1:** Use Mobile FFmpeg
- GitHub: https://github.com/tanersener/mobile-ffmpeg
- May have pre-built options

**Option 2:** Build Yourself
- Requires Android NDK (you already have it)
- See: `FFMPEG_BINARY_SETUP.md` → Option 2
- Takes 30-60 minutes

**Option 3:** Contact Developer
- Ask if they can provide pre-built binaries
- Some projects distribute them separately

---

## Success Indicators

✅ **You'll know it worked when:**
1. APK installs without error
2. App launches without crash
3. Entering a URL and tapping Download works
4. FFmpeg encoding completes (no exit code 127)
5. Final video appears in Downloads folder
6. Video is playable

❌ **You'll know it's still broken if:**
1. File sizes still 4 KB after copying
2. Still seeing exit code 127 after rebuild
3. Different error from before

---

## Time Estimate

- Reading guide: 5 min
- Downloading: 5-15 min (depending on internet)
- Extracting & copying: 2 min
- Rebuilding APK: 3-5 min
- Testing: 2-5 min

**Total: 20-35 minutes**

---

## Support Resources

- **Quick reference:** `FFMPEG_QUICK_SETUP.md`
- **Full guide:** `FFMPEG_BINARY_SETUP.md`
- **Root cause:** `EXIT_CODE_127_EXPLAINED.md`
- **Current status:** `STATUS_REPORT.md` (this document)

---

## Final Check

Before starting:
- [ ] You have about 30-50 MB free disk space
- [ ] You have internet connection to download FFmpeg
- [ ] You have Android device or emulator ready for testing
- [ ] You have adb installed and working
- [ ] You have Flutter working (already have, since you built once)

**Ready? Start with Step 1 above!**
