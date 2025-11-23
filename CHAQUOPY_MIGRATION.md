# Chaquopy Migration Guide

## Overview

The Insta Reel Downloader Android app has been migrated from using prebuilt native binaries (`libytdlp_bridge.so`) to using **Chaquopy** for Python integration. This provides a more maintainable and reliable approach to running yt-dlp.

## What is Chaquopy?

[Chaquopy](https://chaquo.com/chaquopy/) is a plugin for Android Studio's Gradle-based build system that allows you to use Python libraries in Android applications. It:

- Embeds the CPython runtime in your APK
- Manages Python package dependencies via pip
- Provides a Java/Kotlin API to call Python code
- Supports all Android ABIs (armeabi-v7a, arm64-v8a, x86, x86_64)

## Migration Changes

### Build Configuration

#### settings.gradle.kts
- Added Chaquopy Maven repository: `https://chaquo.com/maven`
- Registered Chaquopy plugin: `id("com.chaquo.python") version "15.0.1"`

#### build.gradle.kts  
- Added Chaquopy Maven repository to project repositories

#### app/build.gradle.kts
- Applied Chaquopy plugin: `id("com.chaquo.python")`
- Configured Python version and pip dependencies:
  ```kotlin
  python {
      version = "3.11"
      pip {
          install("yt-dlp==2024.12.23")
          install("requests==2.32.3")
          install("mutagen==1.47.0")
          install("brotli==1.1.0")
          install("certifi==2024.8.30")
          install("websockets==13.1")
          install("pycryptodomex==3.20.0")
      }
  }
  ```

### Python Code

Created `android/app/src/main/python/ytdlp_wrapper.py` with:
- `extract_metadata(url)` - Extracts video metadata using yt-dlp
- `download_video(url, output_path, progress_callback)` - Downloads videos with progress tracking

### Kotlin Code Changes

#### DownloaderBridge.kt

**Removed:**
- Native binary loading with ProcessBuilder
- `findYtDlpBinary()` methods
- References to `libytdlp_bridge.so`

**Added:**
- Chaquopy Python initialization
- Python module calls via Chaquopy API

**Example:**
```kotlin
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

// Initialize Python
private val python: Python by lazy {
    if (!Python.isStarted()) {
        AndroidPlatform.start(activity.applicationContext)
    }
    Python.getInstance()
}

// Call Python function
val module = python.getModule("ytdlp_wrapper")
val result = module.callAttr("extract_metadata", url)
```

### Removed Components

- **BinaryBootstrapper.kt** - No longer needed
- **jniLibs setup** - Chaquopy handles native libraries
- **validateNativeLibs Gradle task** - Replaced by Chaquopy's built-in validation
- **Manual binary placement** - Pip packages installed automatically during build

### .gitignore Updates

Added Python and Chaquopy intermediates:
```
__pycache__/
*.py[cod]
*$py.class
.Python
/android/app/build/generated/python/
/android/app/build/intermediates/python/
/android/app/build/python/
/android/app/.chaquopy/
```

## Build Process

### Before (Native Binaries)
1. Manually download/compile yt-dlp as native binary
2. Place `libytdlp_bridge.so` in `jniLibs/<abi>/`
3. Gradle validates binary exists and is executable
4. App calls binary via ProcessBuilder at runtime

### After (Chaquopy)
1. Configure pip dependencies in `build.gradle.kts`
2. Run `./gradlew app:assembleDebug`
3. Chaquopy automatically:
   - Downloads and caches pip packages
   - Includes Python runtime in APK
   - Packages Python source files
4. App calls Python via Chaquopy API at runtime

## Benefits

### Maintainability
- ✅ No manual binary compilation or downloading
- ✅ Pip packages updated via version pins in build.gradle.kts
- ✅ Standard Python code instead of shell commands
- ✅ Easier debugging with Python stack traces

### Reliability
- ✅ Consistent Python environment across all devices
- ✅ No "binary not found" or "permission denied" errors
- ✅ No Android OS differences in native library loading
- ✅ Dependencies resolved automatically by pip

### Developer Experience
- ✅ Write Python code in standard .py files
- ✅ Use any Python package available on PyPI
- ✅ IDE support for Python code
- ✅ One-command build process

## Building the App

### Prerequisites
- Android SDK (API 26+)
- NDK (for compiling Python extensions)
- Java 17
- Flutter SDK (for Flutter-based builds)

### Build Commands

```bash
# Debug build
cd android
./gradlew app:assembleDebug

# Release build  
./gradlew app:assembleRelease

# Via Flutter
cd ..
flutter build apk --debug
flutter build apk --release
```

### First Build
The first build will take longer as Chaquopy:
1. Downloads Python runtime for each ABI (~10-15 MB per ABI)
2. Downloads and installs pip packages
3. Builds Python wheels for Android if needed

Subsequent builds use cached artifacts and are much faster.

## Troubleshooting

### Build Fails with "Python runtime not found"
- Ensure you have internet connectivity
- Chaquopy needs to download Python runtime on first build
- Check proxy settings if behind corporate firewall

### Pip Package Installation Fails
- Verify package name and version exist on PyPI
- Some packages with C extensions may not support Android
- Check Chaquopy documentation for package compatibility

### APK Size Increased
- Python runtime adds ~10-15 MB per ABI
- Consider filtering ABIs if size is critical:
  ```kotlin
  ndk {
      abiFilters.addAll(listOf("arm64-v8a"))  // 64-bit only
  }
  ```

### Runtime Errors "Module not found"
- Ensure Python modules are in `app/src/main/python/`
- Module names should match file names (without .py)
- Check that files are included in the build

## References

- [Chaquopy Documentation](https://chaquo.com/chaquopy/doc/current/)
- [Python on Android Guide](https://chaquo.com/chaquopy/doc/current/android.html)
- [yt-dlp Documentation](https://github.com/yt-dlp/yt-dlp)

## Migration Checklist

- [x] Added Chaquopy plugin to Gradle configuration
- [x] Configured Python 3.11 and pip dependencies
- [x] Created Python wrapper module (ytdlp_wrapper.py)
- [x] Updated Kotlin code to use Chaquopy API
- [x] Removed native binary references
- [x] Updated .gitignore for Python artifacts
- [x] Removed validateNativeLibs task
- [x] Updated build scripts
- [x] Documentation updated

## Next Steps

1. Test build on clean environment
2. Verify yt-dlp downloads work correctly
3. Test on multiple Android versions and devices
4. Monitor APK size and optimize if needed
5. Consider adding Python unit tests for ytdlp_wrapper.py
