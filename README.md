# Insta Reel Downloader

A Flutter + Kotlin application that downloads Instagram reels on-device, stores them locally, and optionally upscales them with Real-ESRGAN using TensorFlow Lite and yt-dlp. FFmpeg is provided via [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new) for robust video processing. The app follows a clean `core/data/domain/presentation` architecture, uses Riverpod for state management, and exposes a Material 3 UI with Home, Downloads, and Settings tabs.

> ⚠️ **Important:** This app requires **an actual yt-dlp binary** to function. The repository contains only a placeholder stub file (4 KB). FFmpeg is now automatically provided via the FFmpeg Kit dependency. To use the app, you must obtain the real yt-dlp binary and place it in `android/app/src/main/jniLibs/`. 
>
> **👉 Quick Start:** See [`FFMPEG_DOCUMENTATION_INDEX.md`](FFMPEG_DOCUMENTATION_INDEX.md) for organized guides by reading preference

## Highlights
- **No backend services** – URL validation, metadata extraction, downloading, and upscaling all occur locally via platform channels.
- **FFmpeg Kit integration** – FFmpeg is automatically managed via [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new) dependency, no manual binary management required.
- **Lightweight yt-dlp bootstrapping** – Only yt-dlp binary is bootstrapped from `jniLibs`, keeping the Flutter layer lightweight.
- **On-device super-resolution** – UpscalerBridge loads a TFLite FP16 Real-ESRGAN model (GPU/NNAPI accelerated) and falls back to bicubic scaling if unavailable.
- **Download history & offline UX** – Movies are written to `Android/data/<appId>/files/Movies`, and upscaled copies are stored under the original directory.

## Quick Start

### First-Time Setup
Run the automated setup script to configure your build environment:
```bash
bash scripts/setup-android-env.sh
```

This will auto-detect Flutter/Android SDK paths, create necessary directories, and validate dependencies.

### Build and Run
```bash
flutter pub get
flutter run --debug
```
- Connect an Android device or start an emulator (API 24+).
- Paste any public Instagram reel URL on the Home tab to simulate downloads.
- Use the Downloads tab to trigger the Upscaler workflow.

For detailed setup instructions, troubleshooting, and environment validation, see [`SETUP.md`](SETUP.md).

For release builds, keystore handling, and Play Store packaging, see the comprehensive deployment guide linked below.

## Documentation Map
| Topic | Location |
| --- | --- |
| **⚠️ FFmpeg binary setup & troubleshooting** | [`FFMPEG_BINARY_SETUP.md`](FFMPEG_BINARY_SETUP.md) |
| **Finding Android FFmpeg binaries (if stuck)** | [`ANDROID_FFMPEG_DOWNLOAD.md`](ANDROID_FFMPEG_DOWNLOAD.md) |
| **Direct binary download links** | [`FFMPEG_BINARY_SOURCES.md`](FFMPEG_BINARY_SOURCES.md) |
| Quick FFmpeg setup guide | [`FFMPEG_QUICK_SETUP.md`](FFMPEG_QUICK_SETUP.md) |
| Deployment checklist | [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md) |
| Exit code 127 root cause | [`EXIT_CODE_127_EXPLAINED.md`](EXIT_CODE_127_EXPLAINED.md) |
| Current project status | [`STATUS_REPORT.md`](STATUS_REPORT.md) |
| **Android build setup & troubleshooting** | [`SETUP.md`](SETUP.md) |
| Deployment, signing & Play Store checklist | [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) |
| Upscaling architecture & model conversion | [`UPSCALING.md`](UPSCALING.md) |
| Hands-on upscaling walkthrough | [`QUICKSTART_UPSCALING.md`](QUICKSTART_UPSCALING.md) |
| Native downloader & upscaler implementation summary | [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) |
| Share intent & download history details | [`SHARE_INTENT_HISTORY_IMPLEMENTATION.md`](SHARE_INTENT_HISTORY_IMPLEMENTATION.md) |

## Project Structure
```
lib/
  core/            # Constants, routing, DI helpers
  data/            # Platform channel datasources & repositories
  domain/          # Entities, use cases, Riverpod providers
  presentation/    # Home, Downloads, Settings views & controllers
android/
  app/src/main/kotlin/  # DownloaderBridge, UpscalerBridge, native helpers
  app/src/main/assets/  # yt-dlp/FFmpeg stubs, upscaler model placeholder
  app/src/main/jniLibs/ # ABI-specific native binaries
```

## Native Requirements
- Place production-ready **yt-dlp binary** under `android/app/src/main/jniLibs/<abi>/libytdlp_bridge.so` (FFmpeg is now provided by FFmpeg Kit dependency).
- Provide a converted Real-ESRGAN TFLite FP16 model at `android/app/src/main/assets/upscaler/esrgan_fp16.tflite` for hardware-accelerated upscaling.

Refer to [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for detailed setup, environment variables, Gradle commands, and verification steps.
