# FFmpeg for Android - Quick Reference Card

## The Problem
App fails with **exit code 127** = FFmpeg placeholder stubs (4 KB) instead of real binary (25-40 MB)

## The Solution in 30 Seconds

1. Download real FFmpeg for Android ARM64
2. Extract the `ffmpeg` executable (~30 MB)
3. Copy to: `android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so`
4. Rebuild: `flutter clean && flutter build apk --debug`
5. Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

## Where to Get FFmpeg

| Source | Speed | Difficulty | Link | Files |
|--------|-------|-----------|------|-------|
| FFmpeg-Kit (BEST) | 🟢 Fast | Easy | https://github.com/arthenica/ffmpeg-kit/releases | Android `.aar` |
| Mobile-FFmpeg | 🟢 Fast | Easy | https://github.com/tanersener/mobile-ffmpeg/releases | Android `.aar` |
| BtbN Builds | 🟢 Fast | Easy | https://github.com/BtbN/FFmpeg-Builds/releases | Android `.zip` (if available) |
| Build Yourself | 🟡 Slow | Hard | Docker + `./configure && make` | Any |

**Fastest:** Use FFmpeg-Kit v6.0.LTS - see [`FFMPEG_FROM_SUGGESTED_SOURCES.md`](FFMPEG_FROM_SUGGESTED_SOURCES.md)

## File Sizes You Should See

| File | Size | Status |
|------|------|--------|
| `libffmpeg_bridge.so` (placeholder) | 4 KB | ❌ Wrong |
| `libffmpeg_bridge.so` (real binary) | 25-40 MB | ✅ Correct |
| Extracted zip (compressed) | 40-100 MB | ✅ Normal |

## Verification Steps

```bash
# 1. Check file size (must be 25-40 MB, NOT 4 KB)
ls -lh android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so

# 2. Check file type (must be ELF executable)
file android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so

# 3. Verify device architecture matches
adb shell getprop ro.product.cpu.abi
# Expected: arm64-v8a (most common)
```

## Command Checklist

```bash
# After downloading and extracting FFmpeg:

# Copy to project (replace placeholder)
cp /path/to/extracted-ffmpeg/ffmpeg \
   android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so

# Verify size (must be 25+ MB, NOT 4 KB)
ls -lh android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so

# Rebuild
cd /path/to/project
flutter clean
flutter build apk --debug

# Reinstall
adb uninstall com.example.insta_reel_downloader
adb install build/app/outputs/flutter-apk/app-debug.apk

# Test (should NOT show exit code 127)
```

## Common Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Download Linux/Windows build | Won't work | Get Android-specific build |
| File still 4 KB after copying | Still fails | Make sure you copied the right file |
| Didn't rebuild APK | Old stubs used | `flutter clean && flutter build apk --debug` |
| Wrong architecture | Fails on that device | Check device with `adb shell getprop ro.product.cpu.abi` |
| Didn't reinstall APK | Old version runs | `adb uninstall && adb install` |

## Documents for More Help

| Need | Document | Read Time |
|------|----------|-----------|
| Can't find Android FFmpeg | [`ANDROID_FFMPEG_DOWNLOAD.md`](ANDROID_FFMPEG_DOWNLOAD.md) | 3 min |
| Direct download links | [`FFMPEG_BINARY_SOURCES.md`](FFMPEG_BINARY_SOURCES.md) | 2 min |
| Step-by-step deployment | [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md) | 5 min |
| Why exit code 127 happens | [`EXIT_CODE_127_EXPLAINED.md`](EXIT_CODE_127_EXPLAINED.md) | 5 min |
| Quick 5-min setup | [`FFMPEG_QUICK_SETUP.md`](FFMPEG_QUICK_SETUP.md) | 5 min |

## Estimated Time

- Reading this card: 2 min
- Downloading FFmpeg: 5-10 min (depending on internet)
- Extracting & copying: 2 min
- Rebuilding APK: 3-5 min
- Testing: 2-5 min

**Total: 15-25 minutes**

## Success Check ✓

You'll know it worked when:
- ✅ APK installs without error
- ✅ App launches without crash
- ✅ Entering URL and downloading works
- ✅ NO exit code 127 error
- ✅ Video file appears in Downloads

## Stuck?

1. Check file sizes: `ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so`
2. Check device architecture: `adb shell getprop ro.product.cpu.abi`
3. Verify device has correct binary for that architecture
4. Try `adb uninstall && adb install` to force clean install
5. Read troubleshooting in the detailed documents above

---

**Start here:** [`ANDROID_FFMPEG_DOWNLOAD.md`](ANDROID_FFMPEG_DOWNLOAD.md) → [`FFMPEG_QUICK_SETUP.md`](FFMPEG_QUICK_SETUP.md) → Test
