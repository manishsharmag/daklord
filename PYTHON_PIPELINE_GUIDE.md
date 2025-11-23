# Python Pipeline Integration Guide

This guide explains how to use the structured Python pipeline (`insta_dl.chaquopy_pipeline`) from Kotlin/Chaquopy for metadata extraction and downloads.

## Overview

The `insta_dl.chaquopy_pipeline` module provides:

1. **`extract_metadata(url)`** - Extract normalized metadata with fallbacks
2. **`download_reel(url, output_path, progress_token)`** - Download with retries and progress tracking
3. **Structured responses** - Consistent dict format with success/error/results
4. **Graceful error handling** - All exceptions normalized to readable strings

## Architecture

### Module Structure

```
android/app/src/main/python/
├── insta_dl/
│   ├── __init__.py                    # Package marker
│   ├── chaquopy_pipeline.py           # Main module (you are here)
│   └── tests.py                       # Comprehensive test suite
├── ytdlp_wrapper.py                   # Legacy wrapper (backward compatible)
└── README.md                          # Documentation
```

### Core Classes

#### MetadataExtractor

Extracts and normalizes metadata from Instagram URLs.

**Features:**
- Uses yt-dlp for extraction
- Comprehensive fallback chain for robustness
- Extracts: title, author, duration, width, height, thumbnails, stream URLs
- Normalizes author names with @ prefix
- Derives fallback values from URL when extraction fails

**Key Method:**
```python
def extract(url: str) -> Dict[str, Any]:
    """Returns normalized metadata dict."""
```

#### ReelDownloader

Downloads reels with retry logic and progress tracking.

**Features:**
- Automatic retries on transient errors (3 attempts by default)
- Configurable retry delays
- Progress hooks for tracking download state
- Structured response format
- Exception normalization

**Key Method:**
```python
def download(
    url: str,
    output_path: str,
    progress_callback: Optional[Callable]
) -> Dict[str, Any]:
    """Returns success/error/file_path dict."""
```

## Kotlin Integration Examples

### Basic Metadata Extraction

```kotlin
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

// Initialize Python (if not already started)
if (!Python.isStarted()) {
    AndroidPlatform.start(context)
}

val python = Python.getInstance()
val pipeline = python.getModule("insta_dl.chaquopy_pipeline")

// Call extract_metadata
val url = "https://instagram.com/reel/ABC123XYZ/"
val metadata = pipeline.callAttr("extract_metadata", url)

// Extract fields (use get() for safe access to PyObject fields)
val title = metadata.get("title")?.toString() ?: "Unknown"
val author = metadata.get("author")?.toString() ?: "@unknown"
val durationSeconds = metadata.get("duration")?.toInt() ?: 0
val width = metadata.get("width")
val height = metadata.get("height")
val thumbnailUrl = metadata.get("thumbnail_url")
val streamUrl = metadata.get("best_stream_url")

Log.d("Metadata", "Title: $title")
Log.d("Metadata", "Author: $author")
Log.d("Metadata", "Duration: $durationSeconds seconds")
```

### Download with Status Tracking

```kotlin
// Download file
val outputPath = "/storage/emulated/0/Documents/myreel.mp4"
val downloadResult = pipeline.callAttr("download_reel", url, outputPath)

// Check result
val success = downloadResult.get("success")?.toBoolean() ?: false
val error = downloadResult.get("error")
val filePath = downloadResult.get("file_path")

if (success) {
    Log.d("Download", "Success: $filePath")
    // Use the file
} else {
    Log.e("Download", "Failed: $error")
    // Handle error
}
```

### Download with Progress Callback

```kotlin
// Create a progress callback
val progressCallback = object : com.chaquo.python.PyObject {
    override fun call(vararg args: Any?): PyObject {
        if (args.size >= 1) {
            val statusDict = args[0]
            
            // Extract progress fields
            val status = statusDict.get("status")?.toString() ?: ""
            val downloadedBytes = statusDict.get("downloaded_bytes")?.toLong() ?: 0L
            val totalBytes = statusDict.get("total_bytes")?.toLong()
            val etaSeconds = statusDict.get("eta")?.toInt() ?: 0
            
            // Calculate percentage
            val percent = if (totalBytes != null && totalBytes > 0) {
                ((downloadedBytes * 100) / totalBytes).toInt()
            } else {
                0
            }
            
            Log.d("Progress", "$status: $percent% (ETA ${etaSeconds}s)")
            
            // Update UI
            updateProgressUI(percent, etaSeconds)
        }
        return python.builtins.callAttr("None")
    }
}

// Call download_video with callback (backward-compat signature)
val downloadResult = pipeline.callAttr(
    "download_video",
    url,
    outputPath,
    progressCallback
)
```

## Response Formats

### extract_metadata() Response

```python
{
    "title": "str - video title",
    "author": "@str - uploader username (with @ prefix)",
    "duration": int - seconds,
    "width": int or None - video width in pixels,
    "height": int or None - video height in pixels,
    "thumbnail_url": "str or None - thumbnail URL",
    "best_stream_url": "str or None - direct download URL if available",
    "raw_info": {} - raw yt-dlp output for debugging
}
```

### download_reel() Response

```python
{
    "success": bool - whether download completed successfully,
    "error": "str or None - error message if failed",
    "file_path": "str or None - absolute path to downloaded file if successful",
    "final_status": {} or None - last progress status dict from yt-dlp
}
```

### Progress Status Dict

```python
{
    "status": "downloading" or "finished",
    "downloaded_bytes": int,
    "total_bytes": int or None,  # May be None for unknown sizes
    "eta": int - seconds remaining
}
```

## Error Handling

All exceptions are normalized to readable strings:

```python
# Examples of normalized error messages:

"Download error: Some content not available"
"Extractor error: This extractor is currently disabled"
"Network error: [Errno -2] Name or service not known"
"Permission error: Permission denied"
"Network timeout: socket timeout"
"File path error: No such file or directory"
```

Kotlin side:

```kotlin
val result = pipeline.callAttr("download_reel", url, outputPath)
val error = result.get("error")

if (error != null && !error.isNull) {
    val errorMsg = error.toString()
    
    when {
        "Network" in errorMsg -> {
            // Handle network error (retry logic)
        }
        "Permission" in errorMsg -> {
            // Handle permission error (request permission)
        }
        "timeout" in errorMsg.lowercase() -> {
            // Handle timeout (retry or show message)
        }
        else -> {
            // Show generic error
            showError(errorMsg)
        }
    }
}
```

## Retry Logic

The downloader automatically retries on transient errors:

```python
# Default configuration:
max_retries = 3          # Total attempts
retry_delay = 2          # Seconds between attempts
```

This is transparent to the caller - `download_reel()` handles all retries internally.

## Logging

The pipeline logs to stderr with prefixed messages:

```
[MetadataExtractor:DEBUG] Extracting metadata for URL: ...
[MetadataExtractor:ERROR] Metadata extraction failed: ...
[ReelDownloader:DEBUG] Starting download: ...
[ReelDownloader:INFO] Retrying download (attempt 1/3): ...
```

These can be captured via Logcat on Android or stderr in testing.

## Testing

### Local Testing

```bash
# From android/app/src/main/python directory
python3 insta_dl/tests.py

# Expected output:
# ✓ Module imports successfully
# ✓ MetadataExtractor initializes
# ... (11 tests total)
# Results: 11/11 tests passed
```

### JVM Testing via Chaquopy

Add to `android/app/build.gradle.kts`:

```gradle
python {
    version = "3.11"
    pip.install("pytest==7.4.3")
}
```

Tests can then be run as part of the Gradle build.

### Real URL Testing

```python
from insta_dl.chaquopy_pipeline import extract_metadata, download_reel

url = "https://instagram.com/reel/ABC123XYZ/"

# Test metadata
metadata = extract_metadata(url)
assert metadata["title"], "Title should not be empty"
assert metadata["author"].startswith("@"), "Author should start with @"

# Test download (creates actual file)
result = download_reel(url, "/tmp/test_reel.mp4")
assert result["success"], f"Download failed: {result['error']}"
assert os.path.exists(result["file_path"]), "File should exist"
```

## Performance Considerations

### Metadata Extraction
- First call may take 2-5 seconds (yt-dlp initialization)
- Subsequent calls are faster (cached imports)
- Fallback extraction is instant (no network)

### Download
- Speed depends on video size and internet connection
- Typical Instagram reels: 5-30 seconds per video
- Retries add 2-6 seconds per failed attempt
- Progress updates at least every second

### Memory
- Minimal footprint (< 50MB for Python runtime)
- Streaming download (doesn't load entire file into memory)
- Temporary files cleared after completion

## Troubleshooting

### "No module named 'insta_dl'"

**Cause:** Python runtime not initialized or module not packaged.

**Solution:**
```kotlin
// Ensure Python is initialized
if (!Python.isStarted()) {
    AndroidPlatform.start(context)
}

// Then get module
val pipeline = python.getModule("insta_dl.chaquopy_pipeline")
```

### Download Returns Empty File

**Cause:** yt-dlp extraction failed, and fallback didn't produce usable stream.

**Solution:**
```python
# Check if URL is valid and accessible
result = extract_metadata(url)
if not result["best_stream_url"]:
    # This URL may not have a direct stream
    # Try with a different URL or use browser-based approach
```

### Progress Updates Not Triggering

**Cause:** Progress callback not being called by Python thread.

**Solution:**
```kotlin
// Ensure callback updates UI on main thread
val progressCallback = object : PyObject {
    override fun call(vararg args: Any?): PyObject {
        // Post to main thread
        Handler(Looper.getMainLooper()).post {
            updateProgressUI(...)
        }
        return python.builtins.callAttr("None")
    }
}
```

### "Permission denied" Error

**Cause:** App doesn't have permission to write to output directory.

**Solution:**
```kotlin
// Ensure storage permissions are granted before download
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    // Android 11+: MANAGE_EXTERNAL_STORAGE
    requestPermissions(arrayOf(Manifest.permission.MANAGE_EXTERNAL_STORAGE), 100)
} else {
    // Android 10: WRITE_EXTERNAL_STORAGE
    requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 100)
}
```

## Backward Compatibility

The legacy `ytdlp_wrapper.py` module is still available and functional. New code should use `insta_dl.chaquopy_pipeline`, but existing integrations will continue to work.

**Legacy to New Migration:**

```kotlin
// Old way (still works)
val module = python.getModule("ytdlp_wrapper")
val result = module.callAttr("extract_metadata", url)  // Returns JSON string

// New way (recommended)
val pipeline = python.getModule("insta_dl.chaquopy_pipeline")
val result = pipeline.callAttr("extract_metadata", url)  // Returns structured dict
```

## Future Enhancements

Potential improvements for the pipeline:

1. **Async callbacks** - Use `progress_token` to match progress updates across threads
2. **Concurrent downloads** - Download multiple reels in parallel
3. **Format selection** - Allow specifying preferred format (quality, codec, etc.)
4. **Cache** - Cache metadata and stream URLs to speed up repeated requests
5. **Analytics** - Track success rates, error types, and performance metrics

## Additional Resources

- **yt-dlp Documentation:** https://github.com/yt-dlp/yt-dlp
- **Chaquopy Documentation:** https://chaquo.com/chaquopy/doc/
- **Instagram API Reference:** (varies by region and account type)
- **Android Storage Permissions:** https://developer.android.com/training/data-storage
