package com.example.insta_reel_downloader

import android.Manifest
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.IOException
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import java.util.regex.Pattern
import kotlin.math.absoluteValue
import kotlin.math.max
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode

private const val DOWNLOADER_CHANNEL = "com.insta.reel/downloader"
private const val DOWNLOADER_EVENTS = "com.insta.reel/downloader/events"

class DownloaderBridge(private val activity: FlutterActivity) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var commandChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val httpClient = OkHttpClient.Builder()
        .followRedirects(true)
        .followSslRedirects(true)
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .callTimeout(45, TimeUnit.SECONDS)
        .build()
    private val urlResolver = InstagramUrlResolver(httpClient)
    private val validator = ReelUrlValidator(urlResolver)
    private val graphqlClient = InstagramGraphqlClient(httpClient, urlResolver)
    private val metadataExtractor = YtDlpMetadataExtractor(activity.applicationContext, graphqlClient)
    private val downloadPipeline = ScopedDownloadPipeline(activity.applicationContext, httpClient)
    private val historyStore = DownloadHistoryStore(activity.applicationContext)
    private val permissionHelper = StoragePermissionHelper(activity)
    private val tasks = ConcurrentHashMap<String, NativeDownloadTask>()
    private val jobs = ConcurrentHashMap<String, kotlinx.coroutines.Job>()
    private var eventSink: EventChannel.EventSink? = null

    fun start(flutterEngine: FlutterEngine) {
        commandChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADER_CHANNEL)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADER_EVENTS)
        commandChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        scope.cancel()
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean = permissionHelper.onRequestPermissionsResult(requestCode, permissions, grantResults)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "validateUrl" -> handleValidate(call, result)
            "extractMetadata" -> handleMetadata(call, result)
            "queueDownload" -> handleQueue(call, result)
            "loadHistory" -> handleHistory(result)
            "cancelDownload" -> handleCancel(call, result)
            "retryDownload" -> handleRetry(call, result)
            "ensureStorageAccess" -> handlePermission(result)
            "getActiveDownloads" -> handleActive(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        replayActiveTasks()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun handleValidate(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url").orEmpty()
        scope.launch {
            try {
                val validation = validator.validate(url)
                replySuccess(result, validation.toMap())
            } catch (error: Throwable) {
                replyError(result, "validation_error", error.message ?: "Unable to validate URL")
            }
        }
    }

    private fun handleMetadata(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url").orEmpty()
        scope.launch {
            try {
                val validation = validator.validate(url)
                val normalized = validation.normalizedUrl
                    ?: throw IllegalArgumentException(validation.reason ?: "Invalid reel URL")
                val metadata = metadataExtractor.extract(normalized)
                replySuccess(result, metadata.toMap())
            } catch (error: Throwable) {
                replyError(result, "metadata_error", error.message ?: "Metadata unavailable")
            }
        }
    }

    private fun handleQueue(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url").orEmpty()
        val downloadFolder = call.argument<String>("downloadFolder")
        scope.launch {
            try {
                val validation = validator.validate(url)
                val normalized = validation.normalizedUrl
                    ?: throw IllegalArgumentException(validation.reason ?: "Invalid reel URL")
                val metadata = metadataExtractor.extract(normalized)
                val task = NativeDownloadTask.fromMetadata(normalized, metadata)
                tasks[task.id] = task
                emit(task)
                scheduleDownload(task, metadata, downloadFolder)
                replySuccess(result, task.toMap())
            } catch (error: Throwable) {
                replyError(result, "queue_error", error.message ?: "Unable to queue download")
            }
        }
    }

    private fun handleHistory(result: MethodChannel.Result) {
        replySuccess(result, historyStore.list())
    }

    private fun handleCancel(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId").orEmpty()
        val job = jobs.remove(taskId)
        job?.cancel()
        val updated = updateTask(taskId) {
            it.copy(
                status = NativeTaskStatus.FAILED,
                progress = 0.0,
                etaSeconds = null,
                error = "Cancelled by user",
            )
        }
        replySuccess(result, updated?.toMap())
    }

    private fun handleRetry(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId").orEmpty()
        val downloadFolder = call.argument<String>("downloadFolder")
        val existing = tasks[taskId]
        if (existing == null) {
            replyError(result, "retry_missing", "Task not found")
            return
        }
        scope.launch {
            try {
                val metadata = metadataExtractor.extract(existing.url)
                val reset = existing.copy(
                    title = metadata.title,
                    author = metadata.author,
                    thumbnailUrl = metadata.thumbnailUrl,
                    durationSeconds = metadata.durationSeconds,
                    width = metadata.width,
                    height = metadata.height,
                    status = NativeTaskStatus.QUEUED,
                    progress = 0.0,
                    etaSeconds = null,
                    completedAt = null,
                    localPath = null,
                    error = null,
                )
                tasks[taskId] = reset
                emit(reset)
                scheduleDownload(reset, metadata, downloadFolder)
                replySuccess(result, reset.toMap())
            } catch (error: Throwable) {
                replyError(result, "retry_error", error.message ?: "Unable to retry download")
            }
        }
    }

    private fun handlePermission(result: MethodChannel.Result) {
        permissionHelper.ensure { granted ->
            replySuccess(result, granted)
        }
    }

    private fun handleActive(result: MethodChannel.Result) {
        val payload = tasks.values.sortedBy { it.createdAt }.map { it.toMap() }
        replySuccess(result, payload)
    }

    private fun scheduleDownload(task: NativeDownloadTask, metadata: ReelMetadata, downloadFolder: String?) {
        val job = scope.launch {
            updateTask(task.id) {
                it.copy(
                    status = NativeTaskStatus.PREPARING,
                    progress = max(it.progress, 0.05),
                    etaSeconds = 180,
                )
            }
            try {
                val output = downloadPipeline.run(task.id, metadata, downloadFolder) { progress, eta ->
                    updateTask(task.id) {
                        it.copy(
                            status = if (progress >= 1.0) NativeTaskStatus.COMPLETED else NativeTaskStatus.DOWNLOADING,
                            progress = progress,
                            etaSeconds = eta,
                        )
                    }
                }
                val completed = updateTask(task.id) {
                    it.copy(
                        status = NativeTaskStatus.COMPLETED,
                        progress = 1.0,
                        completedAt = System.currentTimeMillis(),
                        etaSeconds = 0,
                        localPath = output.absolutePath,
                        error = null,
                    )
                }
                completed?.let {
                    historyStore.append(it)
                    tasks.remove(it.id)
                }
            } catch (cancelled: CancellationException) {
                updateTask(task.id) {
                    it.copy(
                        status = NativeTaskStatus.FAILED,
                        error = cancelled.message ?: "Cancelled",
                        etaSeconds = null,
                    )
                }
            } catch (error: Throwable) {
                updateTask(task.id) {
                    it.copy(
                        status = NativeTaskStatus.FAILED,
                        error = error.message ?: "Download failed",
                        etaSeconds = null,
                    )
                }
            } finally {
                jobs.remove(task.id)
            }
        }
        jobs[task.id] = job
    }

    private fun updateTask(
        taskId: String,
        transform: (NativeDownloadTask) -> NativeDownloadTask,
    ): NativeDownloadTask? {
        val current = tasks[taskId] ?: return null
        val updated = transform(current)
        tasks[taskId] = updated
        emit(updated)
        return updated
    }

    private fun replayActiveTasks() {
        val sink = eventSink ?: return
        tasks.values.sortedBy { it.createdAt }.forEach { task ->
            sink.success(task.toMap())
        }
    }

    private fun emit(task: NativeDownloadTask) {
        eventSink?.let { sink ->
            mainHandler.post { sink.success(task.toMap()) }
        }
    }

    private fun replySuccess(result: MethodChannel.Result, payload: Any?) {
        mainHandler.post { result.success(payload) }
    }

    private fun replyError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }
}

data class ValidationResult(
    val original: String,
    val normalizedUrl: String?,
    val isValid: Boolean,
    val reason: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "originalUrl" to original,
        "normalizedUrl" to normalizedUrl,
        "isValid" to isValid,
        "reason" to reason,
    )
}

class ReelUrlValidator(private val urlResolver: InstagramUrlResolver) {
    private val pattern = Pattern.compile("^https?://(?:www\\.)?instagram.com/(?:reel|reels|p|tv)/[A-Za-z0-9._-]+/?")

    suspend fun validate(value: String): ValidationResult {
        val normalized = try {
            urlResolver.normalize(value)
        } catch (_: Exception) {
            null
        }
        val isValid = normalized != null && pattern.matcher(normalized).find()
        val reason = if (isValid) null else "URL must be an instagram reel link"
        return ValidationResult(value, normalized, isValid, reason)
    }
}

data class ReelMetadata(
    val url: String,
    val title: String,
    val author: String,
    val durationSeconds: Int,
    val thumbnailUrl: String?,
    val width: Int?,
    val height: Int?,
    val directDownloadUrl: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "url" to url,
        "title" to title,
        "author" to author,
        "durationSeconds" to durationSeconds,
        "thumbnailUrl" to thumbnailUrl,
        "width" to width,
        "height" to height,
        "directDownloadUrl" to directDownloadUrl,
    )
}

enum class NativeTaskStatus(val wireValue: String) {
    QUEUED("queued"),
    PREPARING("preparing"),
    DOWNLOADING("downloading"),
    COMPLETED("completed"),
    FAILED("failed");
}

data class NativeDownloadTask(
    val id: String,
    val url: String,
    val title: String,
    val author: String?,
    val thumbnailUrl: String?,
    val durationSeconds: Int?,
    val width: Int?,
    val height: Int?,
    val status: NativeTaskStatus,
    val progress: Double,
    val etaSeconds: Int?,
    val createdAt: Long,
    val completedAt: Long?,
    val localPath: String?,
    val error: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "url" to url,
        "title" to title,
        "author" to author,
        "thumbnailUrl" to thumbnailUrl,
        "durationSeconds" to durationSeconds,
        "width" to width,
        "height" to height,
        "status" to status.wireValue,
        "progress" to progress,
        "etaSeconds" to etaSeconds,
        "createdAt" to createdAt,
        "completedAt" to completedAt,
        "localPath" to localPath,
        "error" to error,
    )

    companion object {
        fun fromMetadata(url: String, metadata: ReelMetadata): NativeDownloadTask {
            val now = System.currentTimeMillis()
            return NativeDownloadTask(
                id = UUID.randomUUID().toString(),
                url = url,
                title = metadata.title,
                author = metadata.author,
                thumbnailUrl = metadata.thumbnailUrl,
                durationSeconds = metadata.durationSeconds,
                width = metadata.width,
                height = metadata.height,
                status = NativeTaskStatus.QUEUED,
                progress = 0.0,
                etaSeconds = null,
                createdAt = now,
                completedAt = null,
                localPath = null,
                error = null,
            )
        }
    }
}

class YtDlpMetadataExtractor(
    private val context: android.content.Context,
    private val graphqlClient: InstagramGraphqlClient,
) {
    suspend fun extract(url: String): ReelMetadata = withContext(Dispatchers.IO) {
        graphqlClient.fetchMedia(url)?.toMetadata(url)?.let { return@withContext it }
        val dump = runCommand(url)
        if (dump != null) {
            parseDump(url, dump)
        } else {
            fallback(url)
        }
    }

    private fun runCommand(url: String): String? {
        return try {
            val binaryPath = findYtDlpBinary()
            if (binaryPath == null) {
                android.util.Log.e("YtDlpMetadataExtractor", "yt-dlp binary not found")
                return null
            }
            
            android.util.Log.d("YtDlpMetadataExtractor", "yt-dlp binary path: $binaryPath")
            
            val process = ProcessBuilder(binaryPath, "--dump-json", url)
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.bufferedReader().use { it.readText() }
            val finished = process.waitFor(8, TimeUnit.SECONDS)
            if (finished && process.exitValue() == 0 && output.isNotBlank()) output else null
        } catch (_: Exception) {
            null
        }
    }

    private fun findYtDlpBinary(): String? {
        val nativeLibDir = context.applicationInfo.nativeLibraryDir
        return if (nativeLibDir != null) {
            File(nativeLibDir, "libytdlp_bridge.so").takeIf { it.exists() && it.canExecute() }?.absolutePath
        } else {
            null
        }
    }

    private fun parseDump(url: String, payload: String): ReelMetadata {
        return try {
            val json = JSONObject(payload)
            val title = json.optString("title", "").takeIf { it.isNotBlank() }
                ?: json.optString("description", "").takeIf { it.isNotBlank() }
                ?: deriveTitle(url)

            val author = json.optString("uploader", "").takeIf { it.isNotBlank() }
                ?: json.optString("uploader_id", "").takeIf { it.isNotBlank() }
                ?: json.optString("channel", "").takeIf { it.isNotBlank() }
                ?: "instagram"

            val thumbnailUrl = extractThumbnail(json)
            val duration = json.optInt("duration", 45).coerceAtLeast(1)
            val width = json.optInt("width").takeIf { it > 0 }
            val height = json.optInt("height").takeIf { it > 0 }
            val directUrl = extractDirectUrl(json)

            ReelMetadata(
                url = url,
                title = title,
                author = if (author.startsWith("@")) author else "@$author",
                durationSeconds = duration,
                thumbnailUrl = thumbnailUrl,
                width = width,
                height = height,
                directDownloadUrl = directUrl,
            )
        } catch (_: JSONException) {
            fallback(url)
        }
    }

    private fun extractThumbnail(json: JSONObject): String? {
        json.optString("thumbnail", "").takeIf { it.isNotBlank() }?.let { return it }
        val thumbnails = json.optJSONArray("thumbnails") ?: return null
        if (thumbnails.length() == 0) return null
        return thumbnails.getJSONObject(thumbnails.length() - 1)
            .optString("url", "")
            .takeIf { it.isNotBlank() }
    }

    private fun extractDirectUrl(json: JSONObject): String? {
        val formats = json.optJSONArray("formats") ?: return json.optString("url", null)
        var bestUrl: String? = null
        var bestHeight = 0
        for (index in 0 until formats.length()) {
            val format = formats.optJSONObject(index) ?: continue
            val url = format.optString("url").takeIf { it.isNotBlank() } ?: continue
            val ext = format.optString("ext")
            val vcodec = format.optString("vcodec")
            val acodec = format.optString("acodec")
            val height = format.optInt("height", 0)
            if (ext != "mp4") continue
            if (vcodec == "none" || acodec == "none") continue
            if (vcodec.isNotBlank() && !vcodec.startsWith("h264") && !vcodec.startsWith("avc")) continue
            if (height >= bestHeight) {
                bestHeight = height
                bestUrl = url
            }
        }
        return bestUrl ?: json.optString("url", null)
    }

    private fun fallback(url: String): ReelMetadata {
        val title = deriveTitle(url)
        val author = deriveAuthor(url)
        val duration = 30 + (url.hashCode().absoluteValue % 45)
        val reelId = url.trimEnd('/').split('/').lastOrNull()?.take(11) ?: "placeholder"
        return ReelMetadata(
            url = url,
            title = title,
            author = author,
            durationSeconds = duration,
            thumbnailUrl = "https://instagram.com/p/$reelId/media/?size=m",
            width = 1080,
            height = 1920,
            directDownloadUrl = null,
        )
    }

    private fun deriveTitle(url: String): String {
        val token = url.trimEnd('/').split('/').lastOrNull().orEmpty()
        return "Reel ${token.uppercase()}"
    }

    private fun deriveAuthor(url: String): String {
        val parts = url.trimEnd('/').split('/')
        return if (parts.size > 3) "@${parts[3]}" else "@instagram"
    }
}

class ScopedDownloadPipeline(
    private val context: Context,
    private val httpClient: OkHttpClient,
) {
    suspend fun run(
        taskId: String,
        metadata: ReelMetadata,
        downloadFolder: String?,
        onProgress: (Double, Int) -> Unit,
    ): File = withContext(Dispatchers.IO) {
        val baseDir = resolveDownloadDir(downloadFolder)
        // Use app's internal cache for temporary processing (supports execution)
        val tempDir = File(context.cacheDir, "download-temp").apply { mkdirs() }
        
        android.util.Log.d("DownloadPipeline", "Base directory: ${baseDir.absolutePath}")
        android.util.Log.d("DownloadPipeline", "Temp directory: ${tempDir.absolutePath}")

        if (!baseDir.exists()) {
            val created = baseDir.mkdirs()
            if (!created && !baseDir.exists()) {
                throw IOException("Failed to create download directory: ${baseDir.absolutePath}")
            }
            android.util.Log.d("DownloadPipeline", "Created base directory")
        }

        if (!baseDir.isDirectory) {
            throw IOException("Download path is not a directory: ${baseDir.absolutePath}")
        }

        verifyDirectoryWritable(baseDir)

        val safeTitle = sanitizeFilename(metadata.title)
        val timestamp = currentTimestampToken()
        val baseFileName = "${safeTitle}_$timestamp"
        val finalOutput = ensureUniqueOutputFile(baseDir, baseFileName)
        // Use internal cache temp directory (supports execution) instead of external storage (typically noexec)
        val tempOutput = File(tempDir, "${finalOutput.nameWithoutExtension}_temp.mp4")

        android.util.Log.d("DownloadPipeline", "Original title: '${metadata.title}'")
        android.util.Log.d("DownloadPipeline", "Sanitized title: '$safeTitle'")
        android.util.Log.d("DownloadPipeline", "Timestamp: $timestamp")
        android.util.Log.d("DownloadPipeline", "Final output (unique): ${finalOutput.absolutePath}")
        android.util.Log.d("DownloadPipeline", "Temp output: ${tempOutput.absolutePath}")

        if (tempOutput.exists()) tempOutput.delete()

        var lastError: String? = null

        android.util.Log.d("DownloadPipeline", "Starting yt-dlp download")
        val ytResult = downloadWithYtDlp(metadata.url, tempOutput, onProgress)
        if (!ytResult.success) {
            lastError = ytResult.error ?: lastError
            android.util.Log.e("DownloadPipeline", "yt-dlp failed: $lastError")
        }
        
        if (tempOutput.exists() && tempOutput.length() > 0) {
            android.util.Log.d("DownloadPipeline", "yt-dlp downloaded file size: ${tempOutput.length()} bytes")
            val encodeResult = encodeWithFfmpeg(tempOutput, finalOutput)
            
            if (encodeResult.success && finalOutput.exists() && finalOutput.length() > 0) {
                android.util.Log.d("DownloadPipeline", "FFmpeg encoding successful. Final size: ${finalOutput.length()} bytes")
                tempOutput.delete()
                try {
                    tempDir.deleteRecursively()
                } catch (e: Exception) {
                    android.util.Log.w("DownloadPipeline", "Failed to cleanup temp directory: ${e.message}")
                }
                return@withContext finalOutput
            } else {
                android.util.Log.e("DownloadPipeline", "FFmpeg encoding failed: ${encodeResult.error}")
                lastError = encodeResult.error ?: "Failed to optimize downloaded reel"
            }
            tempOutput.delete()
        }

        android.util.Log.d("DownloadPipeline", "Trying direct download method")
        tempOutput.delete()
        val directUrl = metadata.directDownloadUrl
        if (!directUrl.isNullOrBlank()) {
            android.util.Log.d("DownloadPipeline", "Direct URL: $directUrl")
            val directResult = downloadDirect(directUrl, tempOutput, onProgress)
            if (!directResult.success) {
                lastError = directResult.error ?: lastError
                android.util.Log.e("DownloadPipeline", "Direct download failed: $lastError")
            } else if (tempOutput.exists() && tempOutput.length() > 0) {
                android.util.Log.d("DownloadPipeline", "Direct download successful, size: ${tempOutput.length()} bytes")
                val encodeResult = encodeWithFfmpeg(tempOutput, finalOutput)
                
                if (encodeResult.success && finalOutput.exists() && finalOutput.length() > 0) {
                    android.util.Log.d("DownloadPipeline", "FFmpeg encoding successful. Final size: ${finalOutput.length()} bytes")
                    tempOutput.delete()
                    try {
                        tempDir.deleteRecursively()
                    } catch (e: Exception) {
                        android.util.Log.w("DownloadPipeline", "Failed to cleanup temp directory: ${e.message}")
                    }
                    return@withContext finalOutput
                } else {
                    android.util.Log.e("DownloadPipeline", "FFmpeg encoding failed: ${encodeResult.error}")
                    lastError = encodeResult.error ?: "Failed to optimize direct reel stream"
                }
                tempOutput.delete()
            } else {
                android.util.Log.e("DownloadPipeline", "Direct download created no file")
                tempOutput.delete()
            }
        }

        tempOutput.delete()
        android.util.Log.e("DownloadPipeline", "All download methods failed. Last error: $lastError")
        
        // Cleanup temp directory
        try {
            tempDir.deleteRecursively()
        } catch (e: Exception) {
            android.util.Log.w("DownloadPipeline", "Failed to cleanup temp directory: ${e.message}")
        }
        
        throw IOException(lastError ?: "Instagram download failed. Please try again.")
    }

    private fun resolveDownloadDir(downloadFolder: String?): File {
        return if (!downloadFolder.isNullOrBlank()) {
            File(downloadFolder.trim()).absoluteFile
        } else {
            File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "instagram-reels"
            )
        }
    }

    private fun downloadWithYtDlp(url: String, output: File, onProgress: (Double, Int) -> Unit): DownloadAttempt {
        return try {
            val binaryPath = findYtDlpBinary()
            if (binaryPath == null) {
                val errorMsg = "yt-dlp binary not found"
                android.util.Log.e("DownloadPipeline", errorMsg)
                return DownloadAttempt(false, errorMsg)
            }
            
            android.util.Log.d("DownloadPipeline", "yt-dlp binary path: $binaryPath")
            
            val process = ProcessBuilder(
                binaryPath,
                "--no-check-certificate",
                "--no-warnings",
                "--retries", "5",
                "--fragment-retries", "5",
                "--retry-sleep", "2",
                "--concurrent-fragments", "4",
                "-f",
                "bestvideo[ext=mp4][vcodec^=avc]+bestaudio[ext=m4a]/best[ext=mp4]/best",
                "-o",
                output.absolutePath,
                url
            )
                .redirectErrorStream(true)
                .start()

            val reader = process.inputStream.bufferedReader()
            var line: String?
            var lastMessage: String? = null
            while (reader.readLine().also { line = it } != null) {
                val progressLine = line ?: continue
                lastMessage = progressLine
                val progressMatch = PROGRESS_PATTERN.find(progressLine)
                if (progressMatch != null) {
                    val percent = progressMatch.groupValues[2].toDoubleOrNull() ?: 0.0
                    val eta = ETA_PATTERN.find(progressLine)?.let { parseEta(it.groupValues[1]) } ?: 0
                    onProgress((percent / 100.0).coerceIn(0.0, 0.98), eta)
                }
            }

            val finished = process.waitFor(240, TimeUnit.SECONDS)
            val success = finished && process.exitValue() == 0 && output.exists() && output.length() > 0
            if (!success) {
                output.delete()
            }
            DownloadAttempt(success, if (success) null else lastMessage ?: "yt-dlp exited with code ${process.exitValue()}")
        } catch (error: Exception) {
            output.delete()
            DownloadAttempt(false, error.message ?: "yt-dlp failed")
        }
    }

    private fun downloadDirect(url: String, output: File, onProgress: (Double, Int) -> Unit): DownloadAttempt {
        return try {
            val request = Request.Builder()
                .url(url)
                .get()
                .header("User-Agent", INSTAGRAM_MOBILE_USER_AGENT)
                .header("Accept", "*/*")
                .build()
            httpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    return DownloadAttempt(false, "Instagram responded with HTTP ${response.code}")
                }
                val body = response.body ?: return DownloadAttempt(false, "Instagram returned an empty stream")
                val total = body.contentLength()
                output.outputStream().use { sink ->
                    body.byteStream().use { input ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        var read: Int
                        var downloaded = 0L
                        val startTime = System.nanoTime()
                        while (input.read(buffer).also { read = it } != -1) {
                            sink.write(buffer, 0, read)
                            downloaded += read
                            if (total > 0) {
                                val progress = downloaded.toDouble() / total.toDouble()
                                val elapsedSeconds = ((System.nanoTime() - startTime) / 1_000_000_000.0).coerceAtLeast(0.001)
                                val speed = downloaded / elapsedSeconds
                                val etaSeconds = if (speed > 0) ((total - downloaded) / speed).toInt() else 0
                                onProgress(progress.coerceIn(0.0, 0.99), etaSeconds)
                            }
                        }
                    }
                }
                DownloadAttempt(true, null)
            }
        } catch (error: Exception) {
            output.delete()
            DownloadAttempt(false, error.message ?: "Direct download failed")
        }
    }

    private fun encodeWithFfmpeg(input: File, output: File): EncodingResult {
        return try {
            if (!input.exists()) {
                android.util.Log.e("DownloadPipeline", "FFmpeg input file does not exist: ${input.absolutePath}")
                return EncodingResult(false, "Input file not found")
            }
            
            if (input.length() == 0L) {
                android.util.Log.e("DownloadPipeline", "FFmpeg input file is empty: ${input.absolutePath}")
                return EncodingResult(false, "Input file is empty")
            }

            // Verify input file is readable (critical for Android 15+)
            if (!input.canRead()) {
                android.util.Log.e("DownloadPipeline", "FFmpeg input file is not readable (permission denied): ${input.absolutePath}")
                return EncodingResult(false, "Cannot read input file - check permissions (Error 13: Permission denied)")
            }
            
            // Verify output directory is writable
            val outputDir = output.parentFile
            if (outputDir != null && !outputDir.canWrite()) {
                android.util.Log.e("DownloadPipeline", "FFmpeg output directory is not writable: ${outputDir.absolutePath}")
                return EncodingResult(false, "Cannot write to output directory - check MANAGE_EXTERNAL_STORAGE permission")
            }
            
            android.util.Log.d("DownloadPipeline", "Starting FFmpeg encoding using FFmpeg Kit: ${input.absolutePath} -> ${output.absolutePath}")
            
            // Build FFmpeg command using FFmpeg Kit
            val command = "-y -i \"${input.absolutePath}\" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart \"${output.absolutePath}\""
            
            android.util.Log.d("DownloadPipeline", "Executing FFmpeg command: ffmpeg $command")
            
            val session = FFmpegKit.execute(command)
            val returnCode = session.returnCode
            
            android.util.Log.d("DownloadPipeline", "FFmpeg Kit return code: $returnCode")
            
            if (ReturnCode.isSuccess(returnCode)) {
                if (!output.exists()) {
                    android.util.Log.e("DownloadPipeline", "FFmpeg Kit completed but output file not created")
                    return EncodingResult(false, "Output file was not created")
                }
                
                if (output.length() == 0L) {
                    android.util.Log.e("DownloadPipeline", "FFmpeg Kit completed but output file is empty")
                    return EncodingResult(false, "Output file is empty")
                }
                
                android.util.Log.d("DownloadPipeline", "FFmpeg Kit encoding successful. Output size: ${output.length()} bytes")
                EncodingResult(true, null)
            } else if (ReturnCode.isCancel(returnCode)) {
                android.util.Log.w("DownloadPipeline", "FFmpeg Kit encoding cancelled")
                EncodingResult(false, "FFmpeg encoding was cancelled")
            } else {
                val output = session.output
                android.util.Log.e("DownloadPipeline", "FFmpeg Kit failed with return code: $returnCode")
                if (output != null && output.isNotEmpty()) {
                    android.util.Log.e("DownloadPipeline", "FFmpeg Kit output: $output")
                }
                EncodingResult(false, "FFmpeg encoding failed (return code: $returnCode)")
            }
        } catch (error: Exception) {
            android.util.Log.e("DownloadPipeline", "FFmpeg Kit exception: ${error.message}", error)
            EncodingResult(false, "FFmpeg error: ${error.message}")
        }
    }

    private fun parseEta(token: String): Int {
        val parts = token.split(":")
        return when (parts.size) {
            2 -> parts[0].toIntOrNull()?.times(60)?.plus(parts[1].toIntOrNull() ?: 0) ?: 0
            3 -> {
                val hours = parts[0].toIntOrNull() ?: 0
                val minutes = parts[1].toIntOrNull() ?: 0
                val seconds = parts[2].toIntOrNull() ?: 0
                hours * 3600 + minutes * 60 + seconds
            }
            else -> 0
        }
    }

    private fun verifyDirectoryWritable(dir: File) {
        try {
            val testFile = File(dir, ".write_test_${System.currentTimeMillis()}")
            testFile.createNewFile()
            if (testFile.exists()) {
                testFile.delete()
            } else {
                throw IOException("Cannot write to directory")
            }
        } catch (error: Exception) {
            android.util.Log.e("DownloadPipeline", "Directory not writable: ${dir.absolutePath}", error)
            throw IOException("Cannot write to directory: ${dir.absolutePath}. Check permissions.")
        }
    }

    private fun currentTimestampToken(): String {
        val now = System.currentTimeMillis()
        return java.text.SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(now)
    }

    private fun ensureUniqueOutputFile(dir: File, baseName: String): File {
        var file = File(dir, "$baseName.mp4")
        var counter = 1
        while (file.exists() && counter < 1000) {
            file = File(dir, "${baseName}_$counter.mp4")
            counter++
        }
        return file
    }

    private fun sanitizeFilename(title: String?): String {
        val fallback = "Instagram_Reel"
        val rawTitle = title?.trim().orEmpty()
        if (rawTitle.isEmpty()) return fallback

        val normalized = java.text.Normalizer.normalize(rawTitle, java.text.Normalizer.Form.NFKD)
        var sanitized = normalized
            .replace(Regex("\\p{M}+"), "")
            .replace(Regex("[^A-Za-z0-9 _-]"), "_")
            .replace(Regex("\\s+"), "_")
            .replace(Regex("_+"), "_")
            .trim('_')

        if (sanitized.isEmpty()) {
            sanitized = fallback
        }

        if (sanitized.length > 80) {
            sanitized = sanitized.substring(0, 80)
        }

        return sanitized
    }

    private fun findYtDlpBinary(): String? {
        val nativeLibDir = context.applicationInfo.nativeLibraryDir
        return if (nativeLibDir != null) {
            File(nativeLibDir, "libytdlp_bridge.so").takeIf { it.exists() && it.canExecute() }?.absolutePath
        } else {
            null
        }
    }

    private data class DownloadAttempt(val success: Boolean, val error: String?)
    
    private data class EncodingResult(val success: Boolean, val error: String?)

    companion object {
        private val PROGRESS_PATTERN = Regex("\\[(download|ffmpeg)\\]\\s+([0-9.]+)%")
        private val ETA_PATTERN = Regex("ETA\\s+([0-9]{2}:[0-9]{2}(?::[0-9]{2})?)")
    }
}

class DownloadHistoryStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("downloader_history", Context.MODE_PRIVATE)

    fun append(task: NativeDownloadTask) {
        val history = JSONArray(prefs.getString(KEY_HISTORY, "[]"))
        val entry = JSONObject(task.toMap())
        val merged = JSONArray()
        merged.put(entry)
        for (i in 0 until history.length()) {
            if (merged.length() >= MAX_ENTRIES) break
            merged.put(history.getJSONObject(i))
        }
        prefs.edit().putString(KEY_HISTORY, merged.toString()).apply()
    }

    fun list(): List<Map<String, Any?>> {
        val raw = prefs.getString(KEY_HISTORY, "[]") ?: "[]"
        val json = JSONArray(raw)
        val items = mutableListOf<Map<String, Any?>>()
        for (i in 0 until json.length()) {
            val obj = json.getJSONObject(i)
            items.add(obj.toMap())
        }
        return items
    }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val keys = keys()
        val map = mutableMapOf<String, Any?>()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = this.opt(key)
        }
        return map
    }

    companion object {
        private const val KEY_HISTORY = "history"
        private const val MAX_ENTRIES = 40
    }
}

private const val PERMISSION_REQUEST_CODE = 9913
private val LEGACY_PERMISSIONS = arrayOf(
    Manifest.permission.READ_EXTERNAL_STORAGE,
    Manifest.permission.WRITE_EXTERNAL_STORAGE,
)

class StoragePermissionHelper(private val activity: FlutterActivity) {
    private var pending: ((Boolean) -> Unit)? = null

    fun ensure(callback: (Boolean) -> Unit) {
        // Android 13+ (API 33+) - Request READ_MEDIA_VIDEO, READ_MEDIA_AUDIO, READ_MEDIA_IMAGES
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val mediaPermissions = arrayOf(
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_AUDIO,
                Manifest.permission.READ_MEDIA_IMAGES,
            )
            
            val missingPermissions = mediaPermissions.filter { perm ->
                ContextCompat.checkSelfPermission(activity, perm) != android.content.pm.PackageManager.PERMISSION_GRANTED
            }
            
            if (missingPermissions.isEmpty()) {
                callback(true)
                return
            }
            
            if (pending != null) {
                callback(false)
                return
            }
            pending = callback
            ActivityCompat.requestPermissions(activity, missingPermissions.toTypedArray(), PERMISSION_REQUEST_CODE)
            return
        }
        
        // Android 11-12 (API 30-31) - Use scoped storage for Downloads folder
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            callback(true)
            return
        }
        
        // Android 10 (API 29) - Scoped storage introduced
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            callback(true)
            return
        }
        
        // Android 9 and below - Need legacy permissions
        val missing = LEGACY_PERMISSIONS.any { perm ->
            ContextCompat.checkSelfPermission(activity, perm) != android.content.pm.PackageManager.PERMISSION_GRANTED
        }
        if (!missing) {
            callback(true)
            return
        }
        if (pending != null) {
            callback(false)
            return
        }
        pending = callback
        ActivityCompat.requestPermissions(activity, LEGACY_PERMISSIONS, PERMISSION_REQUEST_CODE)
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val granted = grantResults.isNotEmpty() && grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }
        pending?.invoke(granted)
        pending = null
        return true
    }
}
