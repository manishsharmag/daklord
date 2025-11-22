package com.example.insta_reel_downloader

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var downloaderBridge: DownloaderBridge
    private lateinit var upscalerBridge: UpscalerBridge
    private lateinit var sharedIntentBridge: SharedIntentBridge
    private lateinit var folderPickerService: FolderPickerService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        downloaderBridge = DownloaderBridge(this)
        downloaderBridge.start(flutterEngine)

        upscalerBridge = UpscalerBridge(this)
        upscalerBridge.start(flutterEngine)

        sharedIntentBridge = SharedIntentBridge(this)
        sharedIntentBridge.start(flutterEngine)
        
        folderPickerService = FolderPickerService(this)
        folderPickerService.start(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (this::sharedIntentBridge.isInitialized) {
            sharedIntentBridge.onNewIntent(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (this::folderPickerService.isInitialized &&
            folderPickerService.onActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
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
        if (this::folderPickerService.isInitialized) {
            folderPickerService.dispose()
        }
        super.onDestroy()
    }
}
