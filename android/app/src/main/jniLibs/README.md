# Native Libraries Directory

This directory contains native `.so` libraries for different Android architectures.

## Structure

```
jniLibs/
├── armeabi-v7a/     # 32-bit ARM (older devices)
├── arm64-v8a/       # 64-bit ARM (modern devices)
└── x86_64/          # 64-bit x86 (emulators)
```

## Libraries

Each architecture directory should contain:

- `libytdlp_bridge.so` - yt-dlp downloader engine
- `libffmpeg_bridge.so` - FFmpeg for video processing

## Automatic Setup

These libraries are automatically created as placeholders by:

1. The setup script: `bash scripts/setup-android-env.sh`
2. The Gradle build task: `validateNativeLibs` (runs before compilation)

## Runtime Loading

The `BinaryBootstrapper` class handles runtime extraction and execution:

1. First, it tries to load from `jniLibs/` (compiled into APK)
2. If not found, it falls back to `assets/downloader/` stubs
3. Extracts to app's private directory and makes executable

## Git Tracking

The `.so` files are not tracked in git (see `.gitignore`). They are regenerated:

- By the setup script on first setup
- By Gradle before each build if missing or corrupted

## Manual Creation

If you need to manually create the directories:

```bash
cd android/app/src/main/jniLibs
mkdir -p armeabi-v7a arm64-v8a x86_64

# Create placeholder files (will be replaced during build)
for arch in armeabi-v7a arm64-v8a x86_64; do
    echo -ne '\x7fELF' > $arch/libytdlp_bridge.so
    echo -ne '\x7fELF' > $arch/libffmpeg_bridge.so
done
```

## Validation

To check if libraries are valid:

```bash
cd android
./gradlew validateNativeLibs
```

This will report any missing or corrupted libraries and fix them automatically.

## Size Guidelines

- **Placeholder/Stub**: ~4 KB (auto-generated)
- **Real yt-dlp**: 10-50 MB (if you have the actual binary)
- **Real FFmpeg**: 20-80 MB (if you have the actual binary)

Libraries smaller than 1 KB are considered corrupted and will be auto-replaced.

## Production Deployment

For production builds with real native binaries:

1. Obtain or build the actual `yt-dlp` and `ffmpeg` binaries for Android
2. Rename them to `libytdlp_bridge.so` and `libffmpeg_bridge.so`
3. Place in the appropriate architecture directories
4. Build the APK - they will be included automatically

## Troubleshooting

**Problem**: Build fails with "native library not found"

**Solution**: Run `./gradlew validateNativeLibs` or re-run the setup script.

**Problem**: Libraries are 120 bytes and corrupt

**Solution**: Delete them and run `./gradlew validateNativeLibs` to regenerate.

**Problem**: APK size is very large

**Solution**: This is expected if using real native binaries. Consider using APK splits by ABI to reduce per-device download size.
