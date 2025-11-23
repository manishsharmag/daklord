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

yt-dlp is the only native library needed for this app:

- `libytdlp_bridge.so` - yt-dlp downloader engine (required for functionality)

Note: FFmpeg is now provided by the `ffmpeg_kit_flutter_new` package and does not need manual setup.

## Runtime Loading

The app automatically loads the native library from the jniLibs directory:

1. Android extracts native libraries to `/data/app/{package}/lib/{arch}/` during app installation
2. The app accesses it directly via `context.applicationInfo.nativeLibraryDir`
3. No manual extraction or chmod is required

## Setting up yt-dlp

To use this app with yt-dlp functionality:

1. Obtain a compiled yt-dlp binary for Android
2. Place it in the appropriate architecture directories as `libytdlp_bridge.so`
3. Rebuild the APK - the binary will be included automatically

Example:
```bash
cp yt-dlp-android-arm64 android/app/src/main/jniLibs/arm64-v8a/libytdlp_bridge.so
cp yt-dlp-android-armv7 android/app/src/main/jniLibs/armeabi-v7a/libytdlp_bridge.so
cp yt-dlp-android-x86_64 android/app/src/main/jniLibs/x86_64/libytdlp_bridge.so
```

## Production Deployment

For production builds with yt-dlp:

1. Obtain or build the actual `yt-dlp` binary for Android
2. Rename to `libytdlp_bridge.so`
3. Place in the appropriate architecture directories
4. Build the APK - it will be included automatically

## Size Guidelines

- **yt-dlp**: Typically 10-50 MB depending on compilation options
- **FFmpeg**: No longer needed as it's provided by ffmpeg_kit_flutter_new package

## Git Tracking

The `.so` files are not tracked in git (see `.gitignore`) as they contain large binary executables.
