package com.example.insta_reel_downloader

import android.content.Context
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

enum class BinaryAsset(val jniName: String, val stubName: String, val outputName: String) {
    YT_DLP("libytdlp_bridge.so", "yt-dlp.stub", "yt-dlp"),
    FFMPEG("libffmpeg_bridge.so", "ffmpeg.stub", "ffmpeg"),
}

class BinaryBootstrapper(private val context: Context) {
    private val binariesDir = File(context.cacheDir, "native-binaries").apply { mkdirs() }

    fun ensureExecutable(asset: BinaryAsset): File {
        val target = File(binariesDir, asset.outputName)
        
        if (target.exists()) {
            // Verify existing binary is executable
            if (target.canExecute() && target.length() > 0) {
                android.util.Log.d("BinaryBootstrapper", "Using existing executable binary: ${target.absolutePath}")
                return target
            } else {
                android.util.Log.w("BinaryBootstrapper", "Existing binary not executable or empty, re-extracting: ${target.absolutePath}")
                target.delete()
            }
        }
        
        android.util.Log.d("BinaryBootstrapper", "Extracting binary ${asset.outputName} to: ${target.absolutePath}")
        
        val input = loadBinary(asset)
        input.use { source ->
            FileOutputStream(target).use { output ->
                source.copyTo(output)
            }
        }
        
        // Set proper permissions for execution
        target.setExecutable(true, false)  // false = allow execution for all users
        target.setReadable(true, false)     // false = allow reading for all users  
        target.setWritable(true, false)     // false = allow writing for all users
        
        // Verify the binary is executable before returning
        if (!target.canExecute()) {
            val errorMsg = "Failed to set executable permission for binary: ${target.absolutePath}"
            android.util.Log.e("BinaryBootstrapper", errorMsg)
            throw IOException(errorMsg)
        }
        
        if (target.length() == 0L) {
            val errorMsg = "Extracted binary is empty: ${target.absolutePath}"
            android.util.Log.e("BinaryBootstrapper", errorMsg)
            throw IOException(errorMsg)
        }
        
        android.util.Log.d("BinaryBootstrapper", "Successfully extracted and made executable: ${target.absolutePath} (${target.length()} bytes)")
        return target
    }

    private fun loadBinary(asset: BinaryAsset): InputStream {
        val nativeDir = context.applicationInfo.nativeLibraryDir
        if (nativeDir != null) {
            val candidate = File(nativeDir, asset.jniName)
            if (candidate.exists()) {
                return FileInputStream(candidate)
            }
        }
        return try {
            context.assets.open("downloader/${asset.stubName}")
        } catch (_: IOException) {
            asset.stubName.byteInputStream()
        }
    }
}
