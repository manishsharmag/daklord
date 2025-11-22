package com.example.insta_reel_downloader

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class FolderPickerService(private val activity: FlutterActivity) {
    companion object {
        const val CHANNEL = "com.example.insta_reel_downloader/folder_picker"
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 4567
    }

    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    fun start(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "selectFolder" -> selectFolder(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun selectFolder(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        activity.startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE) {
            if (resultCode == FlutterActivity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    val path = getPathFromUri(uri)
                    pendingResult?.success(path)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
            return true
        }
        return false
    }

    private fun getPathFromUri(uri: Uri): String {
        // For document tree URIs, try to get the actual path
        val path = uri.path
        return if (path?.contains("/tree/") == true) {
            // Extract the actual path from the document tree URI
            val parts = path.split("/tree/")
            if (parts.size > 1) {
                val decoded = parts[1].replace("%3A", ":").replace("%2F", "/")
                // Handle storage IDs
                if (decoded.startsWith("primary:")) {
                    decoded.substring(8)
                } else {
                    decoded
                }
            } else {
                uri.toString()
            }
        } else {
            uri.toString()
        }
    }

    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}
