# Exit Code 127 Root Cause Analysis & Resolution

## Error Summary

**Error Message:**
```
FFmpeg encoding failed (exit code: 127)
FFmpeg binary not found or not executable at: /data/app/.../lib/arm64-v8a/libffmpeg_bridge.so
Binary exists: true, canExecute: true
```

## Root Cause

**Exit code 127 = "command not found"**

The error occurs because the binary at `/data/app/{package}/lib/arm64-v8a/libffmpeg_bridge.so` is a **4 KB placeholder stub file**, not a real FFmpeg executable.

### Why This Happens

1. The project's `android/app/src/main/jniLibs/` directory contains only stub files:
   ```
   libffmpeg_bridge.so      4 KB (placeholder)
   libytdlp_bridge.so       4 KB (placeholder)
   ```

2. During APK build, Android packages these stubs into the APK

3. During installation, Android extracts them to `/data/app/{package}/lib/{arch}/`

4. When the app tries to execute the stub file:
   ```kotlin
   ProcessBuilder(binary.absolutePath, "-y", "-i", input.mp4, ...).start()
   ```
   The system can't execute it because it's not a real ELF executable → exit code 127

## Solution

Replace the 4 KB placeholder files with **real, compiled FFmpeg binaries**.

### Step 1: Download Real FFmpeg Binaries

Go to: **https://github.com/BtbN/FFmpeg-Builds/releases**

Download these files:
- `ffmpeg-latest-android-gpl-arm64.zip` (~50-100 MB)
- `ffmpeg-latest-android-gpl-armv7a.zip` (optional, for older phones)
- `ffmpeg-latest-android-gpl-x86_64.zip` (optional, for emulators)

### Step 2: Extract and Locate Executable

Each zip contains an FFmpeg executable. Location varies but usually:
- `bin/ffmpeg`
- `ffmpeg/bin/ffmpeg`
- Just `ffmpeg` in the root

Example:
```bash
unzip ffmpeg-latest-android-gpl-arm64.zip
ls -lh
# You should see an ffmpeg executable, typically 30-40 MB
```

### Step 3: Replace Placeholders

Copy the extracted executable to the jniLibs directory:

```bash
# For ARM64 (most common, target for 90% of devices)
cp /path/to/ffmpeg-arm64/bin/ffmpeg android/app/src/main/jniLibs/arm64-v8a/libffmpeg_bridge.so

# For ARM32 (optional, older phones)
cp /path/to/ffmpeg-armv7a/bin/ffmpeg android/app/src/main/jniLibs/armeabi-v7a/libffmpeg_bridge.so

# For x86_64 (optional, Android emulators)
cp /path/to/ffmpeg-x86_64/bin/ffmpeg android/app/src/main/jniLibs/x86_64/libffmpeg_bridge.so
```

### Step 4: Verify Replacement

Check file sizes - they should be 25-40 MB each, NOT 4 KB:

```bash
ls -lh android/app/src/main/jniLibs/*/libffmpeg_bridge.so

# Expected output:
# -rw-r--r--  arm64-v8a/libffmpeg_bridge.so       32M
# -rw-r--r--  armeabi-v7a/libffmpeg_bridge.so     28M
# -rw-r--r--  x86_64/libffmpeg_bridge.so          36M
```

If files are still 4 KB, you copied the wrong file!

### Step 5: Rebuild & Test

```bash
cd /path/to/project
flutter clean
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Then test the app:
1. Download an Instagram reel
2. It should encode without exit code 127 error

## Why the Project Uses Stubs

The project intentionally uses placeholder stubs in the repository because:

1. **Binary size:** Real FFmpeg binaries are 25-40 MB each - including all 3 architectures would make the repo ~100+ MB
2. **Licensing:** FFmpeg has GPL license requirements that require explicit handling
3. **Flexibility:** Different users may want different FFmpeg features/codecs

The setup is designed to work with:
- **Option A (Easy):** Users download pre-built binaries from BtbN and place them in jniLibs
- **Option B (Advanced):** Users build custom FFmpeg for their needs
- **Option C (Development):** Stubs work for testing the app architecture without actual encoding

## Troubleshooting

### Issue: Files copied but still 4 KB

**Cause:** Copied the wrong file from the zip

**Solution:**
```bash
# Check what's in the extracted archive
cd extracted-ffmpeg-dir
ls -lh
file ffmpeg          # Should show "ELF 64-bit LSB executable"

# Make sure you're copying the executable, not a script
cp ffmpeg /path/to/jniLibs/arm64-v8a/libffmpeg_bridge.so
ls -lh /path/to/jniLibs/arm64-v8a/libffmpeg_bridge.so  # Should be 30+ MB
```

### Issue: Still getting exit code 127 after copying real binaries

**Possible causes:**
1. Didn't rebuild APK after copying
2. File is for wrong architecture
3. Device is different architecture (check with: `adb shell getprop ro.product.cpu.abi`)
4. Binary requires additional dependencies

**Solution:**
```bash
# Force clean rebuild
flutter clean
rm -rf build android/.gradle android/app/build
flutter build apk --debug

# Reinstall
adb uninstall com.example.insta_reel_downloader
adb install build/app/outputs/flutter-apk/app-debug.apk

# Check device architecture
adb shell getprop ro.product.cpu.abi
# If "arm64-v8a", use arm64 binary
# If "armeabi-v7a", use armv7a binary
# If "x86_64", use x86_64 binary
```

### Issue: APK size exploded to 150+ MB

**Cause:** Included all 3 architecture binaries

**Solution (Optional):** Build APK splits by architecture:
```bash
flutter build apk --split-per-abi
# Creates separate APKs: app-armeabi-v7a-debug.apk, app-arm64-v8a-debug.apk, etc.
# Each is ~50-70 MB instead of 150+ MB
```

Most production apps do this.

## What's in These Guides

- **`FFMPEG_QUICK_SETUP.md`** - Fastest path (5 min, just download & copy)
- **`FFMPEG_BINARY_SETUP.md`** - Complete guide (build options, troubleshooting, resources)
- **`SETUP.md`** - Full project setup (environment, dependencies, etc.)

## Key Takeaways

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Exit code 127 | Stub binary (4 KB) | Download real FFmpeg (25-40 MB) |
| Binary exists but 127 | Stub file | Replace with real executable |
| Still 127 after copy | Didn't rebuild APK | `flutter clean && flutter build apk --debug` |
| Wrong architecture | arm64 binary used on armv7a device | Download correct architecture build |

## Next Steps

1. Follow [`FFMPEG_QUICK_SETUP.md`](FFMPEG_QUICK_SETUP.md) (5 minutes)
2. Or read [`FFMPEG_BINARY_SETUP.md`](FFMPEG_BINARY_SETUP.md) for more options
3. Rebuild and test on device

Once real binaries are in place, the app will work correctly. The architecture and permissions are already fixed - this is the final piece.
