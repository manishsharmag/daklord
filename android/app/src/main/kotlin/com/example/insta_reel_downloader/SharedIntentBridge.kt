package com.example.insta_reel_downloader

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class SharedIntentBridge(private val activity: Activity) {
    private val channelName = "com.insta.reel/shared_intent"
    private lateinit var channel: MethodChannel
    private var sharedUrl: String? = null

    fun start(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    val url = sharedUrl
                    result.success(url)
                }
                "clearSharedUrl" -> {
                    sharedUrl = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        handleIntent(activity.intent)
    }

    fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND) {
            val sharedText: String? = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (sharedText != null) {
                sharedUrl = sharedText
                notifyFlutter(sharedText)
            }
        }
    }

    fun onNewIntent(intent: Intent) {
        handleIntent(intent)
    }

    private fun notifyFlutter(url: String) {
        if (::channel.isInitialized) {
            channel.invokeMethod("onSharedIntent", mapOf("url" to url))
        }
    }
}
