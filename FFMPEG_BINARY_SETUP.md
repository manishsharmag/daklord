# FFmpeg Binary Setup Guide

## Current Status

The app is currently failing with **exit code 127** ("command not found") because:

1. ✅ The binary path is correct (`/data/app/{package}/lib/{arch}/libffmpeg_bridge.so`)
2. ✅ The Android permissions are correct (MANAGE_EXTERNAL_STORAGE, READ_MEDIA_*)
3. ✅ The storage permissions are working (yt-dlp can execute successfully)
4. ❌ **The actual FFmpeg binary is missing** - only 4 KB stub files exist

## Problem Explanation

The `jniLibs/` directory currently contains only **placeholder stub files (4 KB each)**:

```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   ├── libffmpeg_bridge.so      ← 4 KB placeholder
│   └── libytdlp_bridge.so       ← yt-dlp binary (likely working)
├── armeabi-v7a/
│   ├── libffmpeg_bridge.so      ← 4 KB placeholder
│   └── libytdlp_bridge.so
└── x86_64/
    ├── libffmpeg_bridge.so      ← 4 KB placeholder
    └── libytdlp_bridge.so
```

When Android extracts these placeholders to `/data/app/{package}/lib/arm64-v8a/libffmpeg_bridge.so` and tries to execute them, the system can't find the actual executable code, resulting in exit code 127.

## Solution: Obtain Real FFmpeg Binaries

You need to replace the stub files with **actual compiled FFmpeg binaries for Android**. There are three approaches:

### Option 1: Use Pre-Built Binaries (Easiest)

Download pre-built FFmpeg binaries for Android from **BtbN's FFmpeg builds**:

**Website:** https://github.com/BtbN/FFmpeg-Builds/releases

**Steps:**
1. Go to the releases page
2. Download the Android ARM64 build: `ffmpeg-latest-android-gpl-arm64.zip` or `ffmpeg-latest-android-gpl-armv7a.zip`
3. Extract the zip file
4. Find the `ffmpeg` executable inside (usually in `bin/` or root folder)
5. Rename it to `libffmpeg_bridge.so`
6. Copy to the appropriate architecture directory:
   - `android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so` (for 64-bit ARM)
   - `android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so` (for 32-bit ARM)
   - `android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so` (for emulators)

**Expected File Sizes:**
- arm64-v8a: ~25-40 MB
- armeabi-v7a: ~20-35 MB
- x86_64: ~30-45 MB

### Option 2: Build FFmpeg Yourself

You can build FFmpeg for Android using the NDK:

**Prerequisites:**
- Android NDK r28.2.13676358 (already in your project)
- FFmpeg source code
- Basic C/C++ knowledge

**Steps:**
1. Clone FFmpeg: `git clone https://git.ffmpeg.org/ffmpeg.git`
2. Use FFmpeg's Android build guide: https://trac.ffmpeg.org/wiki/CompilationGuide/Android
3. Configure with minimal codecs to reduce size:
   ```bash
   ./configure \
     --enable-cross-compile \
     --cross-prefix=aarch64-linux-android- \
     --cc=clang \
     --cxx=clang++ \
     --arch=arm64 \
     --target-os=android \
     --disable-shared \
     --enable-static \
     --enable-small
   ```
4. Build and place the resulting `ffmpeg` executable in jniLibs directories

### Option 3: Use Docker (Recommended for Complex Builds)

Several Docker images exist for building FFmpeg for Android with all dependencies:

**Example:**
```bash
docker run -it -v $(pwd):/workspace ubuntu:20.04 bash
# Inside container:
cd /workspace
apt-get update && apt-get install -y build-essential ndk git
git clone https://git.ffmpeg.org/ffmpeg.git
cd ffmpeg
# Follow build steps from Option 2
```

## After Obtaining FFmpeg Binaries

1. **Replace placeholder files:**
   ```bash
   # Copy your built/downloaded ffmpeg binaries
   cp /path/to/ffmpeg-arm64 android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
   cp /path/to/ffmpeg-armv7a android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so
   cp /path/to/ffmpeg-x86_64 android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so
   ```

2. **Verify the binaries:**
   ```bash
   file android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
   ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so
   ```

3. **Rebuild the APK:**
   ```bash
   cd D:\insta\ reel\ downloader\daklord
   flutter clean
   flutter build apk --debug
   ```

4. **Test on device:**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

## Verification

After rebuilding and installing, FFmpeg should work. You can verify by:

1. Opening the app
2. Attempting to download an Instagram reel
3. Checking if encoding completes successfully instead of showing exit code 127

If you still see exit code 127 after using real binaries, check the logs for:
- Library dependency issues (use `readelf` to check library dependencies)
- Architecture mismatch (binary is for wrong CPU)
- Insufficient permissions on binary

## Size Considerations

**APK Size Impact:**
- Each FFmpeg binary: 25-40 MB per architecture
- If including all 3 architectures (arm64-v8a, armeabi-v7a, x86_64): ~100 MB total

**Optimization Options:**
1. **APK Splits by ABI:** Build separate APKs for each architecture (most users get only ~30-40 MB)
   - Flutter supports this automatically in release builds
2. **Selective Architectures:** Only include arm64-v8a if targeting modern devices (~90% of market)
3. **Compress:** FFmpeg binaries are already compressed by APK, but you can strip debug symbols

## yt-dlp Status

The `libytdlp_bridge.so` likely works because it's also a smaller binary or may be handled differently. If you have the actual yt-dlp binary, follow the same process above to replace it in jniLibs.

## Resources

- **FFmpeg Downloads:** https://github.com/BtbN/FFmpeg-Builds/releases
- **FFmpeg Android Guide:** https://trac.ffmpeg.org/wiki/CompilationGuide/Android
- **Mobile FFmpeg Project:** https://github.com/tanersener/mobile-ffmpeg (pre-built libraries)
- **Android NDK Guide:** https://developer.android.com/ndk/guides

## Next Steps

1. Choose an option above to obtain the FFmpeg binary
2. Place the binaries in the jniLibs directories
3. Rebuild the APK
4. Test on an Android device

Once you have the real binaries in place, the app should work correctly without any more exit code 127 errors.
