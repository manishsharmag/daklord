# Quick Python Pipeline Reference

## Quick Start for Kotlin Developers

### Import and Initialize

```kotlin
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

if (!Python.isStarted()) {
    AndroidPlatform.start(context)
}
val python = Python.getInstance()
val pipeline = python.getModule("insta_dl.chaquopy_pipeline")
```

### Extract Metadata

```kotlin
val url = "https://instagram.com/reel/ABC123/"
val metadata = pipeline.callAttr("extract_metadata", url)

val title = metadata.get("title").toString()
val author = metadata.get("author").toString()
val duration = metadata.get("duration").toInt()
val thumbnail = metadata.get("thumbnail_url")
val streamUrl = metadata.get("best_stream_url")
```

### Download Reel

```kotlin
val outputPath = "/path/to/file.mp4"
val result = pipeline.callAttr("download_reel", url, outputPath)

val success = result.get("success").toBoolean()
val error = result.get("error")        // null if successful
val filePath = result.get("file_path") // null if failed
```

## Module Files

| File | Purpose |
|------|---------|
| `android/app/src/main/python/insta_dl/chaquopy_pipeline.py` | Main pipeline module |
| `android/app/src/main/python/insta_dl/tests.py` | Test suite (11 tests) |
| `android/app/src/main/python/insta_dl/__init__.py` | Package marker |
| `android/app/src/main/python/ytdlp_wrapper.py` | Legacy wrapper (backward compatible) |

## API Reference

### `extract_metadata(url: str) -> Dict[str, Any]`

Extracts video metadata from Instagram URLs.

**Returns:**
```python
{
    "title": str,
    "author": str,              # e.g., "@username"
    "duration": int,            # seconds
    "width": int or None,
    "height": int or None,
    "thumbnail_url": str or None,
    "best_stream_url": str or None,
    "raw_info": dict            # raw yt-dlp output
}
```

**Error handling:** Returns fallback metadata with sensible defaults if extraction fails

### `download_reel(url: str, output_path: str, progress_token: Optional[str]) -> Dict[str, Any]`

Downloads a reel to the specified absolute path.

**Returns:**
```python
{
    "success": bool,
    "error": str or None,       # Readable error message if failed
    "file_path": str or None,   # Absolute path if successful
    "final_status": dict or None  # Last progress status
}
```

**Features:**
- Automatic retries (3 attempts with 2s delay)
- Creates output directory if needed
- Normalizes all exceptions to readable messages
- Supports progress tracking via callbacks

### `download_video(url: str, output_path: str, progress_callback) -> Dict[str, Any]`

Backward-compatible version that accepts a progress callback.

**Progress callback receives:**
```python
{
    "status": "downloading" or "finished",
    "downloaded_bytes": int,
    "total_bytes": int or None,
    "eta": int  # seconds
}
```

## Common Error Messages

| Error | Likely Cause | Solution |
|-------|--------------|----------|
| "Download error: ..." | URL not accessible or format not available | Verify URL, check internet |
| "Extractor error: ..." | Instagram changed API or URL is invalid | Use valid Instagram reel URL |
| "Network error: ..." | Network connectivity issue | Check internet connection, retry |
| "Permission error: ..." | App lacks file write permission | Request MANAGE_EXTERNAL_STORAGE |
| "Network timeout: ..." | Network too slow | Retry or check connection |

## Testing

### Run All Tests
```bash
cd android/app/src/main/python
python3 insta_dl/tests.py
```

### Expected Output
```
Results: 11/11 tests passed
```

### Test List
1. Module imports successfully
2. MetadataExtractor initializes
3. ReelDownloader initializes
4. Fallback metadata returns valid structure
5. Title derivation works
6. Author derivation works
7. Metadata normalization works
8. Download response has correct structure
9. Exception normalization works
10. Logger works correctly
11. Output directory creation works

## Logging

The pipeline logs to stderr with prefixes:

```
[MetadataExtractor:DEBUG] Extracting metadata for URL: ...
[ReelDownloader:INFO] Retrying download (attempt 1/3): ...
[ReelDownloader:ERROR] Download attempt failed: ...
```

Captured via Logcat on Android or stderr in tests.

## Performance

| Operation | Typical Time |
|-----------|--------------|
| Metadata extraction (first) | 2-5 seconds |
| Metadata extraction (cached) | < 1 second |
| Fallback metadata | < 100ms |
| Download (typical 10MB reel) | 5-30 seconds |
| Retry delay between attempts | 2 seconds |

## Backward Compatibility

The legacy `ytdlp_wrapper` module still works:

```kotlin
// Old way (still works)
val module = python.getModule("ytdlp_wrapper")
val result = module.callAttr("extract_metadata", url)  // Returns JSON string

// New way (recommended)
val pipeline = python.getModule("insta_dl.chaquopy_pipeline")
val result = pipeline.callAttr("extract_metadata", url)  // Returns dict
```

Both can coexist during transition.

## Troubleshooting

### Module not found
```kotlin
// Ensure Python is initialized first
if (!Python.isStarted()) {
    AndroidPlatform.start(context)
}
```

### Download creates empty file
- Check if URL is valid (use `extract_metadata` first)
- Verify internet connection
- Check file system permissions

### Progress callback not called
- Ensure callback is implemented as `PyObject` with `call()` method
- Post UI updates to main thread inside callback
- Return `python.builtins.callAttr("None")`

## Related Files

- **PYTHON_PIPELINE_GUIDE.md** - Comprehensive integration guide
- **PIPELINE_IMPLEMENTATION.md** - Implementation details
- **android/app/src/main/python/README.md** - Python module documentation

## Build Integration

No additional configuration needed! Chaquopy automatically:
1. Includes Python 3.11 runtime in APK
2. Packages all `.py` files from `android/app/src/main/python/`
3. Installs pip dependencies (already configured in build.gradle.kts)

First build is slower (downloads Python runtime), subsequent builds are fast.
