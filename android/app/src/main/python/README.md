# Python Source for Chaquopy

This directory contains Python modules that are embedded in the Android app via Chaquopy.

## Overview

Chaquopy allows running Python code natively within Android applications. This eliminates the need for prebuilt native binaries and provides better integration with Python packages.

## Modules

### ytdlp_wrapper.py

Wrapper module for yt-dlp functionality. Provides:

- `extract_metadata(url: str)` - Extracts video metadata from Instagram URLs using yt-dlp
- `download_video(url: str, output_path: str, progress_callback)` - Downloads videos using yt-dlp

## Dependencies

Python dependencies are managed in `android/app/build.gradle.kts` via Chaquopy's pip configuration:

- yt-dlp
- requests  
- mutagen
- brotli
- certifi
- websockets
- pycryptodomex

## Integration

The Kotlin code in `DownloaderBridge.kt` calls these Python functions via Chaquopy's Python API:

```kotlin
val python = Python.getInstance()
val module = python.getModule("ytdlp_wrapper")
val result = module.callAttr("extract_metadata", url)
```

## Build

Chaquopy automatically:
1. Installs pinned pip dependencies during build
2. Packages Python modules into the APK
3. Includes the Python runtime (CPython 3.11) for each ABI (armeabi-v7a, arm64-v8a, x86_64)

No manual setup of Python binaries is required.
