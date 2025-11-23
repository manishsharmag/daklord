# Android FFmpeg Permission Fix - Comprehensive Solution

## Problems Encountered

### Issue 1: "Error 13: Permission Denied" at 99% Download
```
FFmpeg error: Cannot run program "/data/user/0/com.example.insta_reel_downloader/files/native-binaries/ffmpeg": 
error=13, Permission denied
```

### Issue 2: "Failed to set executable permission for binary"
```
FFmpeg error: Failed to set executable permission for binary: /storage/emulated/0/Android/data/
com.example.insta_reel_downloader/files/native-binaries/ffmpeg
```

## Root Cause Analysis

Both issues stem from the same fundamental problem: **External storage is mounted with the `noexec` flag**.

### Storage Architecture

```
Device Storage:
├── Internal Storage (/data/data/<package>/)
│   ├── cache/ [✓ Executable, ✓ Read/Write, Private]
│   └── files/ [✓ Executable, ✓ Read/Write, Private]
│
└── External Storage (/storage/emulated/0/)
    ├── Android/data/<package>/ [✗ No Execute (noexec), Conditional Write]
    ├── Android/media/<package>/ [✗ No Execute (noexec), Conditional Write]
    ├── Downloads/ [✗ No Execute (noexec), Requires MANAGE_EXTERNAL_STORAGE]
    └── Pictures/ [✗ No Execute (noexec), Requires MANAGE_EXTERNAL_STORAGE]
```

### Why This Happens

1. **Linux `noexec` Mount Flag:** External storage (emulated SD card) uses the `noexec` flag for security
   - Prevents execution of any binaries from that location
   - Applies to all Android versions, not just 15+
   - This is a filesystem-level restriction, not Android-specific

2. **Android 15+ Permission Model:** Adds strict file access controls
   - Requires `MANAGE_EXTERNAL_STORAGE` permission for unrestricted file access
   - Media-specific permissions insufficient for general file operations
   - Affects read/write operations to external storage

### Previous Failed Attempts

```
Attempt 1: context.cacheDir (worked for binary execution)
├── FFmpeg can execute ✓
└── But: Permission denied on file access ✗

Attempt 2: context.getExternalFilesDir() (failed)
├── Binary extraction succeeds
├── But: Cannot set executable permission ✗ (noexec flag)
└── Result: "Failed to set executable permission" error
```

## Final Solution

### Strategy: Separate Processing Locations

```
Download Process:
1. Download temp file → /data/data/.../cache/download-temp/
2. Process with FFmpeg (binary from same cache dir) → Reads from cache ✓
3. Move final output → /storage/emulated/0/Downloads/
```

**Key Insight:** Keep binaries and temp files in internal cache (executable), final output in external storage.

## Implementation Details

### 1. AndroidManifest.xml - Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
```

### 2. BinaryBootstrapper.kt - Binary Storage
**File:** `android/app/src/main/kotlin/com/example/insta_reel_downloader/BinaryBootstrapper.kt`

```kotlin
// Use app's internal cache directory for native binaries
// Internal storage allows executable permissions on all Android versions
// External storage is typically mounted with 'noexec' flag, preventing binary execution
private val binariesDir = File(context.cacheDir, "native-binaries").apply { mkdirs() }
```

**Why:**
- Internal cache directory: `/data/data/com.example.insta_reel_downloader/cache/` (exec allowed)
- External storage: `/storage/emulated/0/...` (noexec flag)

### 3. DownloaderBridge.kt - Separate Temp Storage
**File:** `android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt`

#### Updated ScopedDownloadPipeline Constructor
```kotlin
class ScopedDownloadPipeline(
    private val bootstrapper: BinaryBootstrapper,
    private val httpClient: OkHttpClient,
    private val context: Context,  // ← NEW: Add context parameter
) {
    suspend fun run(...): File = withContext(Dispatchers.IO) {
        val baseDir = resolveDownloadDir(downloadFolder)  // Final output location
        val tempDir = File(context.cacheDir, "download-temp").apply { mkdirs() }  // ← NEW: Temp processing
        
        // Processing flow:
        // 1. Download to tempDir (executable location in cache)
        val tempOutput = File(tempDir, "${finalOutput.nameWithoutExtension}_temp.mp4")
        
        // 2. FFmpeg processes from tempDir, outputs to baseDir
        encodeWithFfmpeg(tempOutput, finalOutput)  // temp (cache) → final (external)
        
        // 3. Cleanup temp directory
        tempDir.deleteRecursively()
    }
}
```

#### Updated Instantiation
```kotlin
private val downloadPipeline = ScopedDownloadPipeline(bootstrapper, httpClient, activity.applicationContext)
```

### 4. PermissionService.dart - Android 15+ Support
**File:** `lib/data/datasources/permission_service.dart`

```dart
Future<bool> requestStoragePermission() async {
    final permissions = <Permission>[
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.manageExternalStorage,  // ← NEW: Critical for Android 15+
    ];
    
    final statuses = await permissions.request();
    return statuses.values.any((status) => status.isGranted);
}

// New explicit permission methods
Future<bool> requestManageExternalStoragePermission() async {
    return (await Permission.manageExternalStorage.request()).isGranted;
}

Future<bool> requestAudioPermission() async {
    return (await Permission.audio.request()).isGranted;
}
```

### 5. AppShell.dart - Enhanced Permission Flow
**File:** `lib/presentation/shell/app_shell.dart`

```dart
Future<void> _requestPermissions() async {
    // Request all permission categories
    await _permissionService.requestStoragePermission();
    await _permissionService.requestManageExternalStoragePermission();
    await _permissionService.requestAudioPermission();
}
```

### 6. File Access Validation
Added runtime checks in `encodeWithFfmpeg()`:

```kotlin
// Verify input file is readable
if (!input.canRead()) {
    return EncodingResult(false, "Cannot read input file - check permissions (Error 13)")
}

// Verify output directory is writable
if (outputDir != null && !outputDir.canWrite()) {
    return EncodingResult(false, "Cannot write to output directory - check MANAGE_EXTERNAL_STORAGE")
}

// Verify FFmpeg binary is readable
if (!binary.canRead()) {
    return EncodingResult(false, "FFmpeg binary is not readable (Error 13: Permission denied)")
}
```

## Processing Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Download Workflow                           │
└─────────────────────────────────────────────────────────────────┘

1. REQUEST PERMISSIONS
   ├─ MANAGE_EXTERNAL_STORAGE
   ├─ READ_MEDIA_VIDEO, AUDIO, IMAGES
   └─ READ_MEDIA_VISUAL_USER_SELECTED

2. DOWNLOAD VIDEO
   ├─ Location: /data/data/.../cache/download-temp/ (internal cache)
   ├─ Supports: Read/Write ✓, Execute ✓
   └─ File: video_temp.mp4

3. PROCESS WITH FFmpeg
   ├─ Binary Location: /data/data/.../cache/native-binaries/ffmpeg
   ├─ Input: /data/data/.../cache/download-temp/video_temp.mp4
   ├─ Output: /storage/emulated/0/Downloads/video.mp4
   └─ Result: Encoded video saved

4. CLEANUP
   ├─ Delete: /data/data/.../cache/download-temp/
   └─ Keep: Final output on external storage

5. SUCCESS
   └─ Video available at: /storage/emulated/0/Downloads/video.mp4
```

## Files Modified

| File | Change | Why |
|------|--------|-----|
| `AndroidManifest.xml` | Added READ_MEDIA_VISUAL_USER_SELECTED | Android 15+ support |
| `BinaryBootstrapper.kt` | Use context.cacheDir | Enable binary execution |
| `DownloaderBridge.kt` | Add tempDir in internal cache | Separate processing location |
| `PermissionService.dart` | Add three new permission methods | Android 15+ permissions |
| `AppShell.dart` | Request MANAGE_EXTERNAL_STORAGE | File access on external storage |

## Testing on Device

### Minimum Requirements
- Android 11+ (for MANAGE_EXTERNAL_STORAGE)
- Recommended: Android 15+ (to verify all fixes)

### Test Steps
1. Install APK
2. Grant all permissions when prompted
3. Enter Instagram reel URL
4. Select download folder (optional - default is Downloads)
5. Start download
6. Monitor progress to 100% (previously failed at 99%)
7. Verify file appears in selected folder

### Expected Logs
```
Base directory: /storage/emulated/0/Downloads/instagram-reels
Temp directory: /data/data/com.example.insta_reel_downloader/cache/download-temp
FFmpeg binary path: /data/data/.../cache/native-binaries/ffmpeg
FFmpeg binary canExecute: true
FFmpeg binary canRead: true
Starting FFmpeg encoding: /data/data/.../video_temp.mp4 → /storage/emulated/0/.../video.mp4
FFmpeg encoding successful. Output size: XXXXXX bytes
```

### Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| "Permission denied (Error 13)" | MANAGE_EXTERNAL_STORAGE not granted | Grant in Settings → Apps → Permissions |
| "Failed to set executable permission" | External storage used for binary | Already fixed in this update |
| "Cannot read input file" | Missing READ_MEDIA_* permission | Grant media permissions |
| "Cannot write output directory" | Missing MANAGE_EXTERNAL_STORAGE | Grant file access permission |

## Performance Notes

- Temp files use internal cache (fast, private)
- Final output on external storage (user-accessible)
- Cleanup is automatic
- No impact on download speed
- FFmpeg processing time unchanged

## Android Version Compatibility

| Version | Support | Notes |
|---------|---------|-------|
| Android 11-12 | ✅ Full | MANAGE_EXTERNAL_STORAGE available |
| Android 13-14 | ✅ Full | Media permissions + MANAGE_EXTERNAL_STORAGE |
| Android 15+ | ✅ Full | Strictest permission model, all fixes applied |

## References

- [Android Storage Architecture](https://developer.android.com/training/data-storage/use-cases)
- [MANAGE_EXTERNAL_STORAGE Permission](https://developer.android.com/training/data-storage/manage-all-files)
- [Linux Mount Options - noexec](https://linux.die.net/man/2/mount)
- [Android 15 Privacy Changes](https://developer.android.com/about/versions/15/privacy)

## Version

- **Updated:** November 22, 2025
- **APK Size:** 170.5 MB
- **Status:** ✅ Ready for testing
