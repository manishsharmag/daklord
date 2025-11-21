package com.example.insta_reel_downloader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queueDownload" -> {
                        val url = call.argument<String>("url").orEmpty()
                        result.success(syntheticTask(url))
                    }

                    "loadHistory" -> result.success(sampleHistory())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPSCALER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "upscaleVideo") {
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun syntheticTask(url: String): Map<String, Any> {
        return mapOf(
            "id" to UUID.randomUUID().toString(),
            "url" to url,
            "title" to "Shared reel",
            "status" to "queued",
            "progress" to 0.0,
            "createdAt" to System.currentTimeMillis(),
            "etaSeconds" to 120,
        )
    }

    private fun sampleHistory(): List<Map<String, Any>> {
        return listOf(
            mapOf(
                "id" to UUID.randomUUID().toString(),
                "url" to "https://instagram.com/reel/native-history",
                "title" to "Device cached reel",
                "status" to "completed",
                "completedAt" to System.currentTimeMillis() - 3_600_000,
            )
        )
    }

    companion object {
        private const val DOWNLOADER_CHANNEL = "com.insta.reel/downloader"
        private const val UPSCALER_CHANNEL = "com.insta.reel/upscaler"
    }
}
