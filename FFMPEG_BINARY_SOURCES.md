# Direct Links for Android FFmpeg Binaries

## Confirmed Working Sources

### 1. Mobile FFmpeg (Recommended - Most Reliable)
**GitHub:** https://github.com/tanersener/mobile-ffmpeg/releases

**Why:** Purpose-built for Android, includes pre-compiled binaries

**How to find:**
1. Go to releases page
2. Look for `.zip` files with Android architecture
3. Example: `mobile-ffmpeg-gpl-release-X.X.X.zip`
4. Extract and find the `ffmpeg` binary inside

---

### 2. BtbN FFmpeg Builds (If Available)
**GitHub:** https://github.com/BtbN/FFmpeg-Builds/releases

**What to look for:**
```
ffmpeg-*-android-gpl-*.zip
```

**Specific filenames to search:**
- `ffmpeg-latest-android-gpl-arm64.zip`
- `ffmpeg-latest-android-gpl-armv7a.zip`
- `ffmpeg-latest-android-gpl-x86_64.zip`

**Note:** Newer BtbN releases may focus on Linux/Windows. If you don't see Android files, use Mobile FFmpeg instead.

---

### 3. FFmpeg Android Build (Alternative)
**GitHub:** https://github.com/brainsoftwaretrade/FFmpeg-Android/releases

**What to expect:**
- Standalone executables for Android
- Different architectures available separately

---

## For Reference: What You're Looking For

File characteristics:
```
Filename: ffmpeg-[VERSION]-android-gpl-arm64.zip
Size: 40-100 MB (compressed)
Inside: ffmpeg executable (25-40 MB when extracted)
ELF Type: 64-bit LSB executable, ARM aarch64
```

---

## Quick Test: Is This the Right File?

After downloading and extracting, check:

```bash
# 1. File should exist and be large
ls -lh ffmpeg
# Should show: ~25-40 MB (NOT 4 KB, NOT 100+ MB)

# 2. Should be executable ELF format
file ffmpeg
# Should show: "ELF 64-bit LSB executable, ARM aarch64"

# If both pass, you have the right file! ✓
```

---

## If Still Can't Find Android Builds

**Fallback: Build Your Own (30-60 minutes)**

```bash
# Using Docker (easiest way)
docker run -it -v $(pwd):/work ubuntu:20.04 bash

# Inside container:
cd /work
apt-get update
apt-get install -y build-essential git wget ndk-build

# Get NDK
wget https://dl.google.com/android/repository/android-ndk-r28.2-linux.zip
unzip android-ndk-r28.2-linux.zip
export NDK_HOME=$(pwd)/android-ndk-r28.2

# Get FFmpeg
git clone https://git.ffmpeg.org/ffmpeg.git
cd ffmpeg

# Build for ARM64
./configure \
  --enable-cross-compile \
  --cross-prefix=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android- \
  --cc=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android30-clang \
  --cxx=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android30-clang++ \
  --arch=arm64 \
  --target-os=android \
  --disable-doc \
  --disable-programs \
  --disable-shared

make -j$(nproc)

# Binary is at: ffmpeg (in current directory)
# Copy it to your project
```

---

## Verification Checklist

Once you have the binary:

- [ ] File size is 25-40 MB (not 4 KB)
- [ ] File type is ELF executable (not text/script)
- [ ] Architecture matches your target (arm64-v8a for most)
- [ ] Binary is readable: `file ffmpeg`
- [ ] Ready to copy to jniLibs

---

## Next Step

Once you have the FFmpeg binary:
1. Follow [`FFMPEG_QUICK_SETUP.md`](FFMPEG_QUICK_SETUP.md) from **Step 3**
2. Or [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md) from **Step 2**

---

## If All Else Fails

Contact: Provide the specific error or filename you're seeing, and exact search location on GitHub where you're stuck.

The most reliable fallback is always:
1. **Mobile FFmpeg GitHub releases** - Guaranteed to have Android builds
2. **Docker + build from source** - 100% guaranteed to work but takes time
