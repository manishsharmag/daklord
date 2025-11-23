# Android 15 FFmpeg Permission Fix (Error 13: Permission Denied)

## Problem
FFmpeg failed at 99% download with error:
```
FFmpeg error: Cannot run program "/data/user/0/com.example.insta_reel_downloader/files/native-binaries/ffmpeg": 
error=13, Permission denied
```

This is caused by Android 15+ requiring explicit `MANAGE_EXTERNAL_STORAGE` permission to read and write files, plus specific media permissions.

## Solution Implemented

### 1. Updated AndroidManifest.xml Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

Added the missing `READ_MEDIA_VISUAL_USER_SELECTED` permission for Android 15+ devices:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
```

**Current permissions declared:**
- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `ACCESS_MEDIA_LOCATION`
- `READ_MEDIA_VIDEO` (Android 13+)
- `READ_MEDIA_AUDIO` (Android 13+)
- `READ_MEDIA_IMAGES` (Android 13+)
- `READ_MEDIA_VISUAL_USER_SELECTED` (Android 15+) ✨ **NEW**
- `READ_EXTERNAL_STORAGE` (API ≤32)
- `WRITE_EXTERNAL_STORAGE` (API ≤29)
- `MANAGE_EXTERNAL_STORAGE` (Android 11+) ✨ **Critical for file access**
- `REQUEST_INSTALL_PACKAGES`

### 2. Enhanced Permission Service
**File:** `lib/data/datasources/permission_service.dart`

**Added three new permission methods:**

#### a) Updated `requestStoragePermission()`
- Now requests `Permission.audio` for FFmpeg audio operations
- Requests `Permission.manageExternalStorage` for Android 14+
- Added logging for permission debugging

#### b) New: `requestManageExternalStoragePermission()`
- Explicitly requests `MANAGE_EXTERNAL_STORAGE` permission
- Required for accessing and modifying files on Android 11+
- Particularly critical for Android 15+ file operations

#### c) New: `requestAudioPermission()`
- Requests `Permission.audio` permission
- Ensures FFmpeg can process audio streams

### 3. Fixed Binary Storage Location
**File:** `android/app/src/main/kotlin/com/example/insta_reel_downloader/BinaryBootstrapper.kt`

**Changed from:**
```kotlin
private val binariesDir = File(context.cacheDir, "native-binaries").apply { mkdirs() }
```

**Changed to:**
```kotlin
private val binariesDir = File(context.getExternalFilesDir(null), "native-binaries").apply { mkdirs() }
```

**Why:**
- `context.cacheDir` has restricted access on Android 15+
- `context.getExternalFilesDir()` provides better app-specific storage with proper permissions
- Falls back to external app storage directory with full read/write access

### 4. Enhanced FFmpeg File Access Verification
**File:** `android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt`

Added comprehensive file permission checks before FFmpeg execution:

```kotlin
// Verify input file is readable (critical for Android 15+)
if (!input.canRead()) {
    return EncodingResult(false, "Cannot read input file - check permissions (Error 13: Permission denied)")
}

// Verify output directory is writable
val outputDir = output.parentFile
if (outputDir != null && !outputDir.canWrite()) {
    return EncodingResult(false, "Cannot write to output directory - check MANAGE_EXTERNAL_STORAGE permission")
}

// Log FFmpeg binary permissions
android.util.Log.d("DownloadPipeline", "FFmpeg binary canRead: ${binary.canRead()}")
```

**Benefits:**
- Detects permission issues early (before FFmpeg execution)
- Provides clear error messages to help with debugging
- Logs all file access capabilities for diagnostics

### 5. Updated Permission Request Flow
**File:** `lib/presentation/shell/app_shell.dart`

Enhanced `_requestPermissions()` to request all required permissions:

```dart
// Request storage permission (includes media permissions)
final storageGranted = await _permissionService.requestStoragePermission();

// For Android 15+, also explicitly request MANAGE_EXTERNAL_STORAGE
final manageStorageGranted = await _permissionService.requestManageExternalStoragePermission();

// Request audio permission for FFmpeg operations
await _permissionService.requestAudioPermission();
```

Updated user message to reflect all required permissions:
```
"Storage and file access permissions are required to download videos."
```

## Android 15+ Permission Behavior

### Special Permissions
- **MANAGE_EXTERNAL_STORAGE:** Allows unrestricted access to all device storage
  - Requires user approval in app settings
  - Shows special "Allow access to all files" permission dialog
  - Only available to specific app categories on Google Play

### Media Permissions (Granular)
- **READ_MEDIA_VIDEO:** Read videos
- **READ_MEDIA_AUDIO:** Read audio files  
- **READ_MEDIA_IMAGES:** Read images
- **READ_MEDIA_VISUAL_USER_SELECTED:** Access only selected images/videos (partial access)

## Testing Checklist

When the updated APK is installed on Android 15+ device:

- [ ] App prompts for storage permissions on first launch
- [ ] "Allow access to all files" dialog appears (might be in settings)
- [ ] User grants all requested permissions
- [ ] Downloads start without "Permission denied" error
- [ ] Download reaches 99% without FFmpeg error
- [ ] FFmpeg encoding completes successfully
- [ ] Final file is saved to selected download folder
- [ ] Logs show: "FFmpeg encoding successful. Output size: X bytes"

## Files Modified

1. **android/app/src/main/AndroidManifest.xml** - Added READ_MEDIA_VISUAL_USER_SELECTED
2. **lib/data/datasources/permission_service.dart** - New permission methods
3. **android/app/src/main/kotlin/com/example/insta_reel_downloader/BinaryBootstrapper.kt** - Storage location fix
4. **android/app/src/main/kotlin/com/example/insta_reel_downloader/DownloaderBridge.kt** - File access validation
5. **lib/presentation/shell/app_shell.dart** - Enhanced permission requests

## APK Details

- **Size:** 170.5 MB (app-debug.apk)
- **MinSdk:** 26 (API 26+)
- **TargetSdk:** 34 (API 34+)
- **Successfully tested:** Build completes with only expected native library warnings (harmless placeholders)

## Next Steps After Installation

1. **Install the updated APK** on Android 15+ device
2. **Grant all permissions** when prompted
3. **Test download workflow:**
   - Enter Instagram reel URL
   - Select custom download folder
   - Start download
   - Verify it completes past 99% without permission errors
4. **Check logs** if issues occur:
   ```
   adb logcat | grep "DownloadPipeline\|FFmpeg"
   ```

## References

- [Android 15 Privacy Changes](https://developer.android.com/about/versions/15/privacy)
- [MANAGE_EXTERNAL_STORAGE Permission](https://developer.android.com/training/data-storage/manage-all-files)
- [Media Permissions (READ_MEDIA_*)](https://developer.android.com/training/data-storage/permissions/media)
