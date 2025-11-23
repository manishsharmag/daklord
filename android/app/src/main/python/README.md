# Python Source for Chaquopy

This directory contains Python modules that are embedded in the Android app via Chaquopy.

## Overview

Chaquopy allows running Python code natively within Android applications. This eliminates the need for prebuilt native binaries and provides better integration with Python packages.

## Modules

### insta_dl/ (Package)

Structured pipeline for Instagram reel downloads with metadata extraction:

#### insta_dl/chaquopy_pipeline.py

Main module providing:

- **`extract_metadata(url: str) -> dict`** - Extracts normalized metadata from Instagram URLs
  - Returns: `{title, author, duration, width, height, thumbnail_url, best_stream_url, raw_info}`
  - Uses yt-dlp with comprehensive fallbacks for robustness
  
- **`download_reel(url: str, output_path: str, progress_token: Optional[str]) -> dict`** - Downloads with retries
  - Returns: `{success: bool, error: str|None, file_path: str|None, final_status: dict|None}`
  - Supports progress tracking via callbacks
  - Automatically retries on transient errors (up to 3 attempts)
  - Normalizes exceptions to readable error messages

- **`download_video(url: str, output_path: str, progress_callback) -> dict`** - Backward-compatible alias
  - Same as `download_reel()` but accepts direct progress callback

#### insta_dl/tests.py

Comprehensive test suite including:
- Import tests
- Metadata extraction tests
- Download response structure tests
- Exception normalization tests
- Mock-based tests (no network calls required)

See **[Testing](#testing)** section below for how to run tests.

### ytdlp_wrapper.py (Legacy)

Original wrapper module. Still available for backward compatibility:

- `extract_metadata(url: str)` - Returns JSON string of raw yt-dlp output
- `download_video(url: str, output_path: str, progress_callback)` - Returns dict with success/error/file_path

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

### Using the Structured Pipeline (insta_dl.chaquopy_pipeline)

The recommended Kotlin integration pattern:

```kotlin
import com.chaquo.python.Python

// Initialize Python if needed
if (!Python.isStarted()) {
    AndroidPlatform.start(context)
}

val python = Python.getInstance()
val pipelineModule = python.getModule("insta_dl.chaquopy_pipeline")

// Extract metadata
val metadataResult = pipelineModule.callAttr("extract_metadata", url)
val title = metadataResult.get("title").toString()
val author = metadataResult.get("author").toString()
val duration = metadataResult.get("duration").toInt()
val thumbnailUrl = metadataResult.get("thumbnail_url")

// Download with progress tracking
val downloadResult = pipelineModule.callAttr(
    "download_reel",
    url,
    "/path/to/output.mp4"
)
val success = downloadResult.get("success").toBoolean()
val error = downloadResult.get("error") // null if successful
val filePath = downloadResult.get("file_path") // absolute path to file
```

### Legacy Integration (ytdlp_wrapper)

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

## Testing

### Manual Test Steps (Local Development)

To test the pipeline locally before building the APK:

```bash
# Install test dependencies
pip install pytest yt-dlp

# Run tests from project root
python3 -m pytest android/app/src/main/python/insta_dl/tests.py -v

# Or run tests directly
python3 android/app/src/main/python/insta_dl/tests.py
```

Expected output:
```
============================================================
Running insta_dl.chaquopy_pipeline smoke tests
============================================================

✓ Module imports successfully
✓ MetadataExtractor initializes
✓ ReelDownloader initializes
✓ Fallback metadata returns valid structure
✓ Title derivation works
✓ Author derivation works
✓ Metadata normalization works
✓ Download response has correct structure
✓ Exception normalization works
✓ Logger works correctly
✓ Output directory creation works

============================================================
Results: 11/11 tests passed
============================================================
```

### Test Coverage

The test suite covers:

1. **Module Import** - Verifies module loads and exports required functions
2. **Class Initialization** - Tests MetadataExtractor and ReelDownloader
3. **Fallback Behavior** - Ensures graceful degradation when yt-dlp fails
4. **Metadata Extraction** - Tests normalization with mock yt-dlp output
5. **URL Parsing** - Verifies title and author derivation from URLs
6. **Response Structure** - Validates dict keys for download results
7. **Exception Handling** - Tests error message normalization
8. **Logging** - Verifies logger output format
9. **Directory Creation** - Tests output path handling

### JVM Testing (Optional via Chaquopy)

To enable pytest in the build:

```gradle
python {
    version = "3.11"
    pip.install("pytest==7.4.3")
}
```

Then tests can be run as part of the Gradle build and included in CI/CD pipelines.

### Testing Against Real URLs

For end-to-end testing with real Instagram URLs:

```python
from insta_dl.chaquopy_pipeline import extract_metadata, download_reel
import tempfile

# Test metadata extraction
url = "https://instagram.com/reel/YOUR_REEL_ID/"
metadata = extract_metadata(url)
print(f"Title: {metadata['title']}")
print(f"Author: {metadata['author']}")
print(f"Duration: {metadata['duration']}s")

# Test download
with tempfile.TemporaryDirectory() as tmpdir:
    output_path = f"{tmpdir}/reel.mp4"
    result = download_reel(url, output_path)
    
    if result['success']:
        print(f"Downloaded to: {result['file_path']}")
    else:
        print(f"Download failed: {result['error']}")
```

**Note:** Real downloads require active internet and may take time depending on file size.
