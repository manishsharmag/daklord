package com.example.insta_reel_downloader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var downloaderBridge: DownloaderBridge
    private lateinit var upscalerBridge: UpscalerBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        downloaderBridge = DownloaderBridge(this)
        downloaderBridge.start(flutterEngine)

        upscalerBridge = UpscalerBridge(this)
        upscalerBridge.start(flutterEngine)
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
        if (this::upscalerBridge.isInitialized) {
            upscalerBridge.dispose()
        }
        super.onDestroy()
    }
}
