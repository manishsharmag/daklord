# Quick FFmpeg Binary Download

## TL;DR - The Fastest Way

1. **Download:** Go to https://github.com/BtbN/FFmpeg-Builds/releases
2. **Search for Android builds** - Look for files containing `android` in the name:
   - `ffmpeg-latest-android-gpl-arm64.zip` (64-bit ARM - most common)
   - `ffmpeg-latest-android-gpl-armv7a.zip` (32-bit ARM - older phones)
   - `ffmpeg-latest-android-gpl-x86_64.zip` (x86_64 - emulators)

   > ⚠️ **Note:** If you only see Linux/Windows builds, see [`ANDROID_FFMPEG_DOWNLOAD.md`](ANDROID_FFMPEG_DOWNLOAD.md) for alternative sources

3. **Extract and rename:**
   ```bash
   # Extract each zip, find the ffmpeg executable, and rename it
   unzip ffmpeg-latest-android-gpl-arm64.zip
   cp bin/ffmpeg libffmpeg_bridge.so  # or just 'ffmpeg' depending on what's in the zip
   ```

4. **Place in project:**
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/libffmpeg_bridge.so      ← from arm64 build
   ├── armeabi-v7a/libffmpeg_bridge.so    ← from armv7a build
   └── x86_64/libffmpeg_bridge.so         ← from x86_64 build
   ```

5. **Rebuild:**
   ```bash
   flutter clean
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

## Expected File Sizes After Download

After replacing the placeholder files, you should see:

```
android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so       25-40 MB ✓
android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so     20-35 MB ✓
android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so          30-45 MB ✓
```

NOT:
```
libffmpeg_bridge.so    4 KB   ✗ (this is just a placeholder)
```

## Verify Before Building

```bash
# Check file sizes
ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so

# You should see ~25-40MB each, not 4KB
```

## Common Issues

### Files are still 4 KB after copying
- Make sure you're copying the actual `ffmpeg` executable from the extracted zip
- The zip might have it in `bin/ffmpeg`, `ffmpeg/bin/ffmpeg`, or root as just `ffmpeg`
- Check the zip contents before copying

### "File already exists" error
```bash
# Force overwrite
cp -f /path/to/ffmpeg android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so
```

### APK still fails with exit code 127
- Double-check file sizes are NOT 4 KB
- Verify you got the correct architecture (arm64 for arm64-v8a, etc.)
- Try the next section: "Why It's Still Not Working"

## Advanced: If Downloads Fail

If the BtbN builds don't work on your device, try:

### Option A: Can't Find Android Builds on BtbN?
See: [`ANDROID_FFMPEG_DOWNLOAD.md`](ANDROID_FFMPEG_DOWNLOAD.md)
- Lists alternative sources for Android FFmpeg
- Includes Mobile FFmpeg (recommended alternative)
- Docker build instructions

### Option B: Mobile FFmpeg Pre-built
Less common but sometimes more compatible:
https://github.com/tanersener/mobile-ffmpeg

Look for pre-built binaries for Android.

### Option C: Build Yourself (Docker)
```bash
docker run -it -v $(pwd):/workspace ubuntu:20.04 bash
# Inside container:
apt-get update && apt-get install -y wget git build-essential
wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjf ffmpeg-snapshot.tar.bz2
cd ffmpeg-*
./configure --enable-cross-compile --cross-prefix=aarch64-linux-android- --arch=arm64 --target-os=android --disable-doc --disable-programs
make -j$(nproc)
# Copy ffmpeg executable to jniLibs
```

## Still Stuck?

See the full guide: [`FFMPEG_BINARY_SETUP.md`](FFMPEG_BINARY_SETUP.md)
