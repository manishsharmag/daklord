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
    private val binariesDir = File(context.filesDir, "native-binaries").apply { mkdirs() }

    fun ensureExecutable(asset: BinaryAsset): File {
        val target = File(binariesDir, asset.outputName)
        if (target.exists()) {
            target.setExecutable(true)
            return target
        }
        val input = loadBinary(asset)
        input.use { source ->
            FileOutputStream(target).use { output ->
                source.copyTo(output)
            }
        }
        target.setExecutable(true)
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
