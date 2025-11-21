# Android Build Environment Setup

This guide will help you set up the Android build environment for the Insta Reel Downloader project in just one step.

## Prerequisites

Before running the setup script, ensure you have:

1. **Flutter SDK** (recommended version 3.x or later)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add to PATH: `export PATH="$PATH:$HOME/flutter/bin"` (Linux/macOS)

2. **Android SDK** (via Android Studio OR command-line tools)
   - Android Studio: https://developer.android.com/studio
   - OR Command-line tools: https://developer.android.com/studio#command-tools
   - Minimum SDK version: 24 (Android 7.0)
   - Recommended: SDK 33+ with build tools 33.0.0+

3. **Android NDK** (optional - will be auto-installed if missing)
   - The setup script will attempt to install it automatically
   - Recommended version: 26.x

## Quick Setup (One Command)

Run the automated setup script:

```bash
bash scripts/setup-android-env.sh
```

### What the Script Does

The setup script automatically:

1. ✅ **Detects Flutter SDK** - Finds your Flutter installation
2. ✅ **Detects Android SDK** - Locates Android SDK from common paths or environment variables
3. ✅ **Detects/Installs NDK** - Finds existing NDK or attempts installation via sdkmanager
4. ✅ **Creates local.properties** - Configures SDK paths for Gradle
5. ✅ **Updates gradle.properties** - Adds build optimization flags
6. ✅ **Sets up jniLibs** - Creates native library directory structure with placeholders
7. ✅ **Validates TensorFlow Lite** - Checks that TensorFlow Lite dependencies are available
8. ✅ **Cleans build artifacts** - Removes any corrupted cache or build files
9. ✅ **Refreshes Flutter dependencies** - Runs `flutter clean` and `flutter pub get`
10. ✅ **Validates setup** - Ensures all configurations are correct

## After Setup

Once the setup script completes successfully, you can build the project:

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release
```

### Alternative: Using Gradle Directly

```bash
cd android
./gradlew assembleDebug
# or
./gradlew assembleRelease
```

## Self-Healing Build System

The project includes self-healing Gradle tasks that automatically fix common issues:

### Auto-Validation on Every Build

The build system automatically validates native libraries before compilation. If any `.so` files are missing or corrupted (< 1KB), they are automatically recreated as placeholders.

### Manual Validation Tasks

```bash
cd android
./gradlew validateNativeLibs      # Check/fix native libraries
./gradlew validateTensorFlowLite  # Check TensorFlow Lite dependencies
./gradlew setupAndBuild           # Validate and build in one command
./gradlew fullCleanBuild          # Deep clean and rebuild
```

## Troubleshooting

### Problem: "Flutter SDK not found"

**Solution:**
```bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor

# Re-run setup
bash scripts/setup-android-env.sh
```

### Problem: "Android SDK not found"

**Solution:**
Set the `ANDROID_HOME` environment variable:
```bash
export ANDROID_HOME=$HOME/Android/Sdk  # Linux
# or
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS

# Re-run setup
bash scripts/setup-android-env.sh
```

### Problem: "NDK not found"

**Solution:**
The setup script will attempt to install it automatically. If that fails:
1. Open Android Studio
2. Go to: Tools → SDK Manager → SDK Tools
3. Check "NDK (Side by side)" and click Apply
4. Re-run the setup script

### Problem: TensorFlow Lite Compilation Errors

If you see errors like "Unresolved reference: Interpreter", run:

```bash
cd android
./gradlew clean build --refresh-dependencies
```

This forces Gradle to re-download all dependencies, including TensorFlow Lite.

### Problem: Corrupt Native Libraries

If `.so` files are corrupted (showing as 120 bytes), the build system will automatically detect and fix them. You can also manually trigger this:

```bash
cd android
./gradlew validateNativeLibs
```

### Problem: Gradle Cache Corruption

If you encounter persistent Gradle errors:

```bash
cd android
./gradlew cleanCorruptedCache
./gradlew build --refresh-dependencies
```

Or simply re-run the setup script:

```bash
bash scripts/setup-android-env.sh
```

## Native Libraries

The project uses the following native libraries:

- **libytdlp_bridge.so** - yt-dlp downloader engine
- **libffmpeg_bridge.so** - FFmpeg for video processing

These are loaded at runtime from:
- `android/app/src/main/jniLibs/` (compile-time placeholders)
- `android/app/src/main/assets/` (runtime stubs)

The `BinaryBootstrapper` class handles runtime extraction and execution.

## TensorFlow Lite Integration

The upscaling feature uses TensorFlow Lite with:
- **org.tensorflow:tensorflow-lite:2.13.0** - Core inference engine
- **org.tensorflow:tensorflow-lite-gpu:2.13.0** - GPU acceleration
- **org.tensorflow:tensorflow-lite-nnapi:2.13.0** - NNAPI acceleration
- **org.tensorflow:tensorflow-lite-support:0.4.4** - Helper utilities

The model file should be placed at:
```
android/app/src/main/assets/upscaler/esrgan_fp16.tflite
```

Currently, there's a stub file that serves as a placeholder. The app will fall back to bicubic scaling if the model is not available.

## Environment Variables

The setup script uses and configures these environment variables:

- `ANDROID_HOME` or `ANDROID_SDK_ROOT` - Android SDK path
- `FLUTTER_SDK` - Flutter SDK path (written to local.properties)
- `NDK_VERSION` - NDK version (auto-detected or installed)

## Build Optimization

The setup script configures these Gradle optimizations:

- **JVM Heap**: 8GB (-Xmx8G)
- **Metaspace**: 4GB
- **Code Cache**: 512MB
- **R8 Full Mode**: Enabled for better code shrinking
- **AndroidX**: Enabled
- **Jetifier**: Enabled for legacy library support

## CI/CD Integration

For continuous integration environments, ensure these are set:

```bash
export ANDROID_HOME=/path/to/android-sdk
export ANDROID_SDK_ROOT=/path/to/android-sdk
export PATH=$PATH:/path/to/flutter/bin

# Run setup
bash scripts/setup-android-env.sh

# Build
flutter build apk --release
```

## Support

If you encounter issues not covered here:

1. Check `flutter doctor` output for Flutter/Android setup issues
2. Review the setup script output for specific error messages
3. Try a clean rebuild: `bash scripts/setup-android-env.sh` followed by `flutter clean && flutter pub get`
4. Check that you have internet connectivity (for dependency downloads)

## Manual Setup (Advanced)

If the automatic setup doesn't work for your environment, you can manually:

1. Create `android/local.properties`:
   ```properties
   sdk.dir=/path/to/android-sdk
   ndk.dir=/path/to/android-sdk/ndk/26.1.10909125
   flutter.sdk=/path/to/flutter
   ```
   > **Windows Tip:** Use forward slashes (e.g., `C:/Users/...`) or escape backslashes (e.g., `C:\\Users\\...`) so Gradle can read the paths correctly.

2. Create jniLibs directories:

   mkdir -p android/app/src/main/jniLibs/{armeabi-v7a,arm64-v8a,x86_64}
   ```

3. Clean and build:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean build
   ```

## Success Indicators

After successful setup, you should see:

✅ `local.properties` exists with correct SDK paths  
✅ `jniLibs/` directory structure created  
✅ Gradle can resolve TensorFlow Lite dependencies  
✅ `flutter build apk --debug` completes without errors  
✅ APK is generated in `build/app/outputs/flutter-apk/`  

---

**Note**: The first build after setup may take 5-10 minutes as Gradle downloads dependencies and builds native libraries.
