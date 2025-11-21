# Insta Reel Downloader

A Flutter + Kotlin application that downloads Instagram reels on-device, stores them locally, and optionally upscales them with Real-ESRGAN using TensorFlow Lite, FFmpeg, and yt-dlp binaries bundled per-ABI. The app follows a clean `core/data/domain/presentation` architecture, uses Riverpod for state management, and exposes a Material 3 UI with Home, Downloads, and Settings tabs.

## Highlights
- **No backend services** – URL validation, metadata extraction, downloading, and upscaling all occur locally via platform channels.
- **Native binary pipeline** – Kotlin bridges bootstrap yt-dlp and FFmpeg executables from `jniLibs`, keeping the Flutter layer lightweight.
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
- Place production-ready yt-dlp & FFmpeg binaries under `android/app/src/main/jniLibs/<abi>/` (matching names declared in `BinaryAsset`).
- Provide a converted Real-ESRGAN TFLite FP16 model at `android/app/src/main/assets/upscaler/esrgan_fp16.tflite` for hardware-accelerated upscaling.

Refer to [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for detailed setup, environment variables, Gradle commands, and verification steps.
