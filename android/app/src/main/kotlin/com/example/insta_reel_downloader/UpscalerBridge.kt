package com.example.insta_reel_downloader

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

private const val UPSCALER_CHANNEL = "com.insta.reel/upscaler"
private const val UPSCALER_EVENTS = "com.insta.reel/upscaler/events"

class UpscalerBridge(private val activity: FlutterActivity) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var commandChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val tasks = ConcurrentHashMap<String, UpscaleTask>()
    private val jobs = ConcurrentHashMap<String, kotlinx.coroutines.Job>()
    private var eventSink: EventChannel.EventSink? = null
    private var interpreter: Interpreter? = null
    private var delegate: Any? = null
    private val bootstrapper = BinaryBootstrapper(activity.applicationContext)

    fun start(flutterEngine: FlutterEngine) {
        commandChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPSCALER_CHANNEL)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, UPSCALER_EVENTS)
        commandChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        initializeModel()
    }

    fun dispose() {
        scope.cancel()
        cleanupModel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "upscaleVideo" -> handleUpscale(call, result)
            "cancelUpscale" -> handleCancel(call, result)
            "getActiveTasks" -> handleActive(result)
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

    private fun initializeModel() {
        try {
            val modelFile = loadModelFile(activity.applicationContext)
            if (modelFile != null) {
                try {
                    interpreter = Interpreter(modelFile)
                    android.util.Log.d("UpscalerBridge", "TensorFlow Lite model loaded successfully")
                } catch (e: Exception) {
                    android.util.Log.e("UpscalerBridge", "Failed to create interpreter: ${e.message}", e)
                    interpreter = null
                }
            } else {
                android.util.Log.w("UpscalerBridge", "Model file not found, upscaling will use bicubic fallback")
            }
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "Error during model initialization: ${e.message}", e)
            interpreter = null
        }
    }

    private fun cleanupModel() {
        interpreter?.close()
        interpreter = null
        delegate = null
    }

    private fun loadModelFile(context: Context): MappedByteBuffer? {
        return try {
            val assetManager = context.assets
            val modelPath = "upscaler/esrgan_fp16.tflite"
            try {
                val fileDescriptor = assetManager.openFd(modelPath)
                val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
                val fileChannel = inputStream.channel
                val startOffset = fileDescriptor.startOffset
                val declaredLength = fileDescriptor.declaredLength
                android.util.Log.d("UpscalerBridge", "Loading model from $modelPath (size: $declaredLength bytes)")
                fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
            } catch (e: java.io.FileNotFoundException) {
                android.util.Log.w("UpscalerBridge", "Model file not found: $modelPath - will use bicubic upscaling")
                null
            } catch (e: Exception) {
                android.util.Log.e("UpscalerBridge", "Error loading model file: ${e.message}", e)
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "Unexpected error in loadModelFile: ${e.message}", e)
            null
        }
    }

    private fun handleUpscale(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val scaleFactor = call.argument<Int>("scaleFactor") ?: 2
        
        if (videoPath == null) {
            replyError(result, "invalid_argument", "videoPath is required")
            return
        }

        val taskId = UUID.randomUUID().toString()
        val task = UpscaleTask(
            id = taskId,
            videoPath = videoPath,
            scaleFactor = scaleFactor,
            status = UpscaleStatus.QUEUED,
            progress = 0.0,
            createdAt = System.currentTimeMillis()
        )
        
        tasks[taskId] = task
        emit(task)
        
        scope.launch {
            try {
                processUpscale(task)
                replySuccess(result, task.toMap())
            } catch (e: Exception) {
                replyError(result, "upscale_error", e.message ?: "Failed to start upscaling")
            }
        }
    }

    private fun handleCancel(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId").orEmpty()
        val job = jobs.remove(taskId)
        job?.cancel()
        
        val updated = updateTask(taskId) {
            it.copy(
                status = UpscaleStatus.FAILED,
                error = "Cancelled by user"
            )
        }
        replySuccess(result, updated?.toMap())
    }

    private fun handleActive(result: MethodChannel.Result) {
        val payload = tasks.values.sortedBy { it.createdAt }.map { it.toMap() }
        replySuccess(result, payload)
    }

    private suspend fun processUpscale(task: UpscaleTask) {
        val job = scope.launch {
            try {
                updateTask(task.id) {
                    it.copy(status = UpscaleStatus.PREPARING, progress = 0.05)
                }

                val inputFile = File(task.videoPath)
                if (!inputFile.exists()) {
                    throw IllegalArgumentException("Input video file not found: ${task.videoPath}")
                }

                if (!inputFile.canRead()) {
                    throw IllegalArgumentException("Input video file is not readable: ${task.videoPath}")
                }

                android.util.Log.d("UpscalerBridge", "Starting upscale for: ${inputFile.absolutePath}")

                val outputDir = File(inputFile.parent, "upscaled")
                if (!outputDir.mkdirs() && !outputDir.isDirectory) {
                    throw IllegalArgumentException("Failed to create output directory: ${outputDir.absolutePath}")
                }
                
                val outputFile = File(
                    outputDir,
                    "${inputFile.nameWithoutExtension}_${task.scaleFactor}x.mp4"
                )

                updateTask(task.id) {
                    it.copy(status = UpscaleStatus.EXTRACTING_FRAMES, progress = 0.1)
                }

                val framesDir = File(activity.applicationContext.cacheDir, "frames_${task.id}")
                if (!framesDir.mkdirs() && !framesDir.isDirectory) {
                    throw IllegalArgumentException("Failed to create frames directory: ${framesDir.absolutePath}")
                }

                try {
                    android.util.Log.d("UpscalerBridge", "Extracting frames to: ${framesDir.absolutePath}")
                    extractFrames(inputFile, framesDir)

                    val frameFiles = framesDir.listFiles()?.sortedBy { it.name } ?: emptyList()
                    val totalFrames = frameFiles.size

                    if (totalFrames == 0) {
                        throw IllegalStateException("No frames extracted from video")
                    }

                    android.util.Log.d("UpscalerBridge", "Extracted $totalFrames frames")

                    updateTask(task.id) {
                        it.copy(status = UpscaleStatus.UPSCALING, progress = 0.2)
                    }

                    val upscaledDir = File(activity.applicationContext.cacheDir, "upscaled_${task.id}")
                    if (!upscaledDir.mkdirs() && !upscaledDir.isDirectory) {
                        throw IllegalArgumentException("Failed to create upscaled directory: ${upscaledDir.absolutePath}")
                    }

                    frameFiles.forEachIndexed { index, frameFile ->
                        if (!isActive) throw CancellationException("Task cancelled")

                        try {
                            upscaleFrame(frameFile, File(upscaledDir, frameFile.name), task.scaleFactor)
                        } catch (e: Exception) {
                            android.util.Log.e("UpscalerBridge", "Error upscaling frame ${index + 1}/$totalFrames: ${e.message}", e)
                            throw e
                        }

                        val progress = 0.2 + (0.7 * (index + 1) / totalFrames)
                        updateTask(task.id) {
                            it.copy(progress = progress)
                        }
                    }

                    updateTask(task.id) {
                        it.copy(status = UpscaleStatus.ENCODING, progress = 0.9)
                    }

                    android.util.Log.d("UpscalerBridge", "Encoding upscaled frames to: ${outputFile.absolutePath}")
                    encodeVideo(upscaledDir, inputFile, outputFile)

                    if (!outputFile.exists()) {
                        throw IllegalStateException("Output file was not created: ${outputFile.absolutePath}")
                    }

                    updateTask(task.id) {
                        it.copy(
                            status = UpscaleStatus.COMPLETED,
                            progress = 1.0,
                            outputPath = outputFile.absolutePath,
                            completedAt = System.currentTimeMillis()
                        )
                    }

                    android.util.Log.d("UpscalerBridge", "Upscaling completed successfully: ${outputFile.absolutePath}")
                } finally {
                    framesDir.deleteRecursively()
                    File(activity.applicationContext.cacheDir, "upscaled_${task.id}").deleteRecursively()
                    jobs.remove(task.id)
                }
            } catch (e: CancellationException) {
                android.util.Log.d("UpscalerBridge", "Upscaling cancelled for task ${task.id}")
                updateTask(task.id) {
                    it.copy(
                        status = UpscaleStatus.FAILED,
                        error = "Cancelled by user"
                    )
                }
            } catch (e: Exception) {
                android.util.Log.e("UpscalerBridge", "Error during upscaling: ${e.message}", e)
                updateTask(task.id) {
                    it.copy(
                        status = UpscaleStatus.FAILED,
                        error = e.message ?: "Unknown error occurred"
                    )
                }
            }
        }
        
        jobs[task.id] = job
        
        try {
            job.join()
        } catch (e: CancellationException) {
            // Already handled in the job
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "Unexpected error in job.join(): ${e.message}", e)
        }
    }

    private suspend fun extractFrames(inputFile: File, outputDir: File) = withContext(Dispatchers.IO) {
        try {
            val ffmpeg = bootstrapper.ensureExecutable(BinaryAsset.FFMPEG)
            android.util.Log.d("UpscalerBridge", "Using FFmpeg: ${ffmpeg.absolutePath}")
            
            val process = ProcessBuilder(
                ffmpeg.absolutePath,
                "-i", inputFile.absolutePath,
                "-vf", "fps=30",
                "${outputDir.absolutePath}/frame_%04d.png"
            ).redirectErrorStream(true).start()

            val exitCode = process.waitFor()
            if (exitCode != 0) {
                android.util.Log.e("UpscalerBridge", "FFmpeg frame extraction failed with exit code $exitCode")
                throw RuntimeException("FFmpeg frame extraction failed with code $exitCode")
            }
            android.util.Log.d("UpscalerBridge", "Frame extraction completed successfully")
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "Error during frame extraction: ${e.message}", e)
            throw e
        }
    }

    private suspend fun upscaleFrame(inputFrame: File, outputFrame: File, scaleFactor: Int) = withContext(Dispatchers.IO) {
        val currentInterpreter = interpreter
        
        if (currentInterpreter == null) {
            try {
                simulateUpscale(inputFrame, outputFrame, scaleFactor)
            } catch (e: Exception) {
                android.util.Log.e("UpscalerBridge", "Error in bicubic upscale fallback: ${e.message}", e)
                throw e
            }
            return@withContext
        }

        try {
            val bitmap = BitmapFactory.decodeFile(inputFrame.absolutePath)
                ?: throw IllegalArgumentException("Failed to decode bitmap from ${inputFrame.absolutePath}")
            
            try {
                val inputBuffer = bitmapToByteBuffer(bitmap)
                
                val inputShape = currentInterpreter.getInputTensor(0).shape()
                val outputShape = currentInterpreter.getOutputTensor(0).shape()
                
                android.util.Log.d("UpscalerBridge", "Input shape: ${inputShape.contentToString()}, Output shape: ${outputShape.contentToString()}")
                
                val outputBuffer = ByteBuffer.allocateDirect(
                    outputShape[1] * outputShape[2] * outputShape[3] * 4
                ).order(ByteOrder.nativeOrder())
                
                currentInterpreter.run(inputBuffer, outputBuffer)
                
                val upscaledBitmap = byteBufferToBitmap(outputBuffer, outputShape[1], outputShape[2])
                
                FileOutputStream(outputFrame).use { out ->
                    upscaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                }
                upscaledBitmap.recycle()
            } finally {
                bitmap.recycle()
            }
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "TFLite upscaling failed, falling back to bicubic: ${e.message}", e)
            try {
                simulateUpscale(inputFrame, outputFrame, scaleFactor)
            } catch (fallbackError: Exception) {
                android.util.Log.e("UpscalerBridge", "Fallback upscaling also failed: ${fallbackError.message}", fallbackError)
                throw fallbackError
            }
        }
    }

    private fun simulateUpscale(inputFrame: File, outputFrame: File, scaleFactor: Int) {
        var bitmap: Bitmap? = null
        var scaled: Bitmap? = null
        try {
            bitmap = BitmapFactory.decodeFile(inputFrame.absolutePath)
                ?: throw IllegalArgumentException("Failed to decode bitmap from ${inputFrame.absolutePath}")
            
            val newWidth = bitmap.width * scaleFactor
            val newHeight = bitmap.height * scaleFactor
            
            android.util.Log.d("UpscalerBridge", "Bicubic upscaling: ${bitmap.width}x${bitmap.height} -> ${newWidth}x${newHeight}")
            
            scaled = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
            
            FileOutputStream(outputFrame).use { out ->
                scaled.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
        } finally {
            scaled?.recycle()
            bitmap?.recycle()
        }
    }

    private fun bitmapToByteBuffer(bitmap: Bitmap): ByteBuffer {
        val byteBuffer = ByteBuffer.allocateDirect(4 * bitmap.width * bitmap.height * 3)
        byteBuffer.order(ByteOrder.nativeOrder())
        
        val intValues = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(intValues, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        
        var pixel = 0
        for (i in 0 until bitmap.width) {
            for (j in 0 until bitmap.height) {
                val value = intValues[pixel++]
                byteBuffer.putFloat(((value shr 16) and 0xFF) / 255.0f)
                byteBuffer.putFloat(((value shr 8) and 0xFF) / 255.0f)
                byteBuffer.putFloat((value and 0xFF) / 255.0f)
            }
        }
        
        return byteBuffer
    }

    private fun byteBufferToBitmap(buffer: ByteBuffer, width: Int, height: Int): Bitmap {
        buffer.rewind()
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val pixels = IntArray(width * height)
        
        for (i in pixels.indices) {
            val r = (buffer.float * 255).toInt().coerceIn(0, 255)
            val g = (buffer.float * 255).toInt().coerceIn(0, 255)
            val b = (buffer.float * 255).toInt().coerceIn(0, 255)
            pixels[i] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
        }
        
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
        return bitmap
    }

    private suspend fun encodeVideo(framesDir: File, originalVideo: File, outputFile: File) = withContext(Dispatchers.IO) {
        try {
            val ffmpeg = bootstrapper.ensureExecutable(BinaryAsset.FFMPEG)
            android.util.Log.d("UpscalerBridge", "Using FFmpeg for encoding: ${ffmpeg.absolutePath}")
            
            val process = ProcessBuilder(
                ffmpeg.absolutePath,
                "-framerate", "30",
                "-i", "${framesDir.absolutePath}/frame_%04d.png",
                "-i", originalVideo.absolutePath,
                "-map", "0:v",
                "-map", "1:a?",
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "18",
                "-c:a", "copy",
                "-pix_fmt", "yuv420p",
                outputFile.absolutePath
            ).redirectErrorStream(true).start()

            val exitCode = process.waitFor()
            if (exitCode != 0) {
                android.util.Log.e("UpscalerBridge", "FFmpeg video encoding failed with exit code $exitCode")
                throw RuntimeException("FFmpeg video encoding failed with code $exitCode")
            }
            android.util.Log.d("UpscalerBridge", "Video encoding completed successfully")
        } catch (e: Exception) {
            android.util.Log.e("UpscalerBridge", "Error during video encoding: ${e.message}", e)
            throw e
        }
    }

    private fun updateTask(
        taskId: String,
        transform: (UpscaleTask) -> UpscaleTask
    ): UpscaleTask? {
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

    private fun emit(task: UpscaleTask) {
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

enum class UpscaleStatus(val wireValue: String) {
    QUEUED("queued"),
    PREPARING("preparing"),
    EXTRACTING_FRAMES("extracting_frames"),
    UPSCALING("upscaling"),
    ENCODING("encoding"),
    COMPLETED("completed"),
    FAILED("failed");
}

data class UpscaleTask(
    val id: String,
    val videoPath: String,
    val scaleFactor: Int,
    val status: UpscaleStatus,
    val progress: Double,
    val createdAt: Long,
    val completedAt: Long? = null,
    val outputPath: String? = null,
    val error: String? = null
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "videoPath" to videoPath,
        "scaleFactor" to scaleFactor,
        "status" to status.wireValue,
        "progress" to progress,
        "createdAt" to createdAt,
        "completedAt" to completedAt,
        "outputPath" to outputPath,
        "error" to error
    )
}
