package com.example.insta_reel_downloader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var downloaderBridge: DownloaderBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        downloaderBridge = DownloaderBridge(this)
        downloaderBridge.start(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPSCALER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "upscaleVideo") {
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        if (this::downloaderBridge.isInitialized &&
            downloaderBridge.onRequestPermissionsResult(requestCode, permissions, grantResults)
        ) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        if (this::downloaderBridge.isInitialized) {
            downloaderBridge.dispose()
        }
        super.onDestroy()
    }

    companion object {
        private const val UPSCALER_CHANNEL = "com.insta.reel/upscaler"
    }
}
