package com.example.insta_reel_downloader

import android.content.Context
import java.io.File
import java.io.IOException

enum class BinaryAsset(val jniName: String, val outputName: String) {
    YT_DLP("libytdlp_bridge.so", "yt-dlp"),
    // FFmpeg is now provided by ffmpeg_kit_flutter_new dependency
}

class BinaryBootstrapper(private val context: Context) {
    // Android 10+ security model: native libraries are extracted to /data/app/{package}/lib/{arch}/
    // This location has proper execute permissions and is the only approved location for binary execution
    // See: https://developer.android.com/training/articles/security-tips#NativeCode

    fun ensureExecutable(asset: BinaryAsset): File {
        val binary = findNativeLibrary(asset.jniName)
        
        if (binary != null && binary.exists() && binary.canExecute()) {
            android.util.Log.d("BinaryBootstrapper", "Found executable native library: ${binary.absolutePath}")
            android.util.Log.d("BinaryBootstrapper", "Binary size: ${binary.length()} bytes")
            android.util.Log.d("BinaryBootstrapper", "Permissions - canExecute: true, canRead: ${binary.canRead()}")
            
            // Warn if binary appears to be a placeholder (very small)
            if (binary.length() < 10000) {  // Less than 10 KB
                android.util.Log.w("BinaryBootstrapper", 
                    "WARNING: ${asset.jniName} appears to be a placeholder stub (${binary.length()} bytes). " +
                    "This will likely fail at runtime with exit code 127. " +
                    "See FFMPEG_BINARY_SETUP.md for instructions on obtaining real binaries.")
            }
            
            return binary
        }
        
        val diagnostics = buildString {
            appendLine("Native library not found or not executable: ${asset.jniName}")
            appendLine("Expected location: /data/app/com.example.insta_reel_downloader/lib/{arch}/${asset.jniName}")
            if (binary != null) {
                appendLine("Binary found at: ${binary.absolutePath}")
                appendLine("  - exists: ${binary.exists()}")
                appendLine("  - isFile: ${binary.isFile}")
                appendLine("  - canRead: ${binary.canRead()}")
                appendLine("  - canExecute: ${binary.canExecute()}")
                appendLine("  - size: ${binary.length()} bytes")
            } else {
                appendLine("Binary not found at expected location")
            }
            appendLine()
            appendLine("CRITICAL: This app requires the real yt-dlp binary to function.")
            appendLine("FFmpeg is provided by ffmpeg_kit_flutter_new dependency and does not need manual setup.")
            appendLine("The repository contains only placeholder stub files (4 KB) for yt-dlp.")
            appendLine()
            appendLine("To fix this issue:")
            appendLine("1. See FFMPEG_BINARY_SETUP.md for detailed instructions on obtaining yt-dlp")
            appendLine("2. Place the yt-dlp binary at android/app/src/main/jniLibs/<abi>/libytdlp_bridge.so")
            appendLine()
            appendLine("Possible causes:")
            appendLine("1. APK does not contain real yt-dlp binary (stub only)")
            appendLine("2. App was not properly installed (reinstall required)")
            appendLine("3. Device storage is full (clear space and reinstall)")
            appendLine("4. APK does not contain yt-dlp binary for device architecture")
            appendLine("5. Filesystem does not have execute permissions")
        }
        
        android.util.Log.e("BinaryBootstrapper", diagnostics)
        throw IOException(diagnostics.toString())
    }

    private fun findNativeLibrary(jniName: String): File? {
        // Get the native library directory where Android extracts libraries
        val nativeLibDir = context.applicationInfo.nativeLibraryDir
        
        if (nativeLibDir != null) {
            val libFile = File(nativeLibDir, jniName)
            
            android.util.Log.d("BinaryBootstrapper", "Checking native library at: ${libFile.absolutePath}")
            android.util.Log.d("BinaryBootstrapper", "Exists: ${libFile.exists()}")
            android.util.Log.d("BinaryBootstrapper", "Is file: ${libFile.isFile}")
            android.util.Log.d("BinaryBootstrapper", "Can execute: ${libFile.canExecute()}")
            
            if (libFile.exists() && libFile.isFile && libFile.canExecute()) {
                return libFile
            } else if (libFile.exists()) {
                android.util.Log.w("BinaryBootstrapper", 
                    "Native library exists but not executable. " +
                    "canRead: ${libFile.canRead()}, canWrite: ${libFile.canWrite()}")
            }
        }
        
        android.util.Log.e("BinaryBootstrapper", "Native library directory is null or inaccessible")
        return null
    }
}

