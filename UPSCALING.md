# On-Device Video Upscaling Implementation

This document describes the Real-ESRGAN on-device upscaling implementation with NNAPI/GPU acceleration.

## Architecture

### Android/Kotlin Layer

#### UpscalerBridge (`UpscalerBridge.kt`)

The main Kotlin module that handles upscaling operations:

- **Model Loading**: Loads Real-ESRGAN model in TFLite fp16 format from assets
- **Hardware Acceleration**: 
  - Attempts GPU acceleration using TensorFlow Lite GPU delegate
  - Falls back to NNAPI delegate if GPU is not available
  - Uses 4 threads for CPU operations
- **Frame Processing**:
  - Extracts frames from video using FFmpeg (30 fps)
  - Upscales each frame using Real-ESRGAN model
  - Reassembles video with FFmpeg, preserving audio
- **Progress Reporting**: Reports status through EventChannel
- **Fallback**: Uses bicubic scaling if model is not available

#### Key Methods

- `upscaleVideo(videoPath, scaleFactor)`: Start upscaling task
- `cancelUpscale(taskId)`: Cancel an active upscaling task
- `getActiveTasks()`: Get list of active upscaling tasks

#### Status Flow

1. **QUEUED**: Task queued for processing
2. **PREPARING**: Initializing resources
3. **EXTRACTING_FRAMES**: Extracting video frames with FFmpeg
4. **UPSCALING**: Running Real-ESRGAN on each frame (reports progress 20-90%)
5. **ENCODING**: Encoding upscaled frames back to video with FFmpeg
6. **COMPLETED**: Upscaling complete, output saved
7. **FAILED**: Error occurred

### Flutter/Dart Layer

#### Services

**UpscalerService** (`lib/domain/services/upscaler_service.dart`)
- Abstract service interface for upscaling operations

**UpscalerChannelService** (`lib/data/datasources/upscaler_platform_channel.dart`)
- Platform channel implementation
- Listens to progress events from native side
- Provides typed Dart API

#### Controllers

**UpscaleController** (`lib/presentation/downloads/upscale_controller.dart`)
- Manages upscaling state in Flutter
- Listens to progress stream
- Updates UI when tasks change status

#### Entities

**UpscaleTask** (`lib/domain/entities/upscale_task.dart`)
- Represents an upscaling task with all metadata
- Includes progress, status, paths, errors

**UpscaleStatus** (`lib/domain/entities/upscale_status.dart`)
- Enum for upscaling status states

### UI Components

#### Settings View
- Toggle for auto-upscaling (experimental)
- Slider to select scale factor (2x or 4x)
- Information about performance trade-offs

#### Downloads View
- Shows active upscaling tasks with progress bars
- "Upscale" button on completed downloads
- Real-time progress updates
- Success/failure notifications

## Model Setup

### Required Model

The implementation expects a Real-ESRGAN model in TFLite fp16 format at:
```
android/app/src/main/assets/upscaler/esrgan_fp16.tflite
```

### Converting Real-ESRGAN to TFLite

1. **Export PyTorch to ONNX**:
```python
import torch
from realesrgan import RealESRGAN

model = RealESRGAN()
dummy_input = torch.randn(1, 3, 64, 64)
torch.onnx.export(model, dummy_input, "esrgan.onnx")
```

2. **Convert ONNX to TensorFlow**:
```python
import onnx
from onnx_tf.backend import prepare

onnx_model = onnx.load("esrgan.onnx")
tf_rep = prepare(onnx_model)
tf_rep.export_graph("esrgan_tf")
```

3. **Convert TensorFlow to TFLite with fp16**:
```python
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model("esrgan_tf")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open("esrgan_fp16.tflite", "wb") as f:
    f.write(tflite_model)
```

4. Place the resulting `esrgan_fp16.tflite` file in the assets directory

### Alternative: NCNN Format

For better performance on some devices, you can use NCNN:
- Convert model to NCNN format using ncnn tools
- Update UpscalerBridge to use NCNN instead of TFLite
- NCNN typically provides better performance on mobile

## Dependencies

### Android
```kotlin
implementation("org.tensorflow:tensorflow-lite:2.14.0")
implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
```

### Flutter
- No additional dependencies required (uses existing Riverpod and Material 3)

## Performance

### Hardware Acceleration

- **GPU Delegate**: Best performance, uses device GPU
- **NNAPI Delegate**: Good performance, uses dedicated AI accelerator if available
- **CPU**: Fallback, slower but works on all devices

### Benchmark (Typical 30-second Reel)

- **2x Upscaling**: ~30-60 seconds on modern devices with GPU
- **4x Upscaling**: ~60-120 seconds on modern devices with GPU
- Performance depends heavily on:
  - Device capabilities
  - Input resolution
  - Scale factor
  - Model complexity

### Memory Usage

- Frames are processed in batches to manage memory
- Temporary frames stored in cache directory
- Cleaned up after completion

## Usage

### For Users

1. Download a video reel
2. Go to Settings, adjust scale factor (2x or 4x)
3. In Downloads history, tap "Upscale" button
4. Monitor progress in "Active upscaling" section
5. Upscaled video saved to `{original_dir}/upscaled/` folder

### For Developers

```dart
// Trigger upscaling
final upscaleController = ref.read(upscaleControllerProvider.notifier);
await upscaleController.upscaleVideo(
  videoPath: '/path/to/video.mp4',
  scaleFactor: 2,
);

// Listen to progress
ref.watch(upscaleControllerProvider).activeTasks.forEach((task) {
  print('Progress: ${task.progress * 100}%');
  print('Status: ${task.status}');
});

// Cancel upscaling
await upscaleController.cancelTask(taskId);
```

## Error Handling

- Model not found: Falls back to bicubic upscaling
- FFmpeg errors: Detailed error messages reported
- Out of memory: Reduces batch size automatically
- Cancellation: Cleans up all temporary files

## Future Improvements

1. **Multiple Model Support**: Support different quality/speed trade-offs
2. **Tile-based Processing**: Handle very high resolution videos
3. **Background Processing**: Continue upscaling when app is backgrounded
4. **Batch Upscaling**: Queue multiple videos
5. **Custom Models**: Allow users to import custom models
6. **Format Options**: Support different output formats/codecs
7. **Quality Presets**: Preset configurations for different use cases

## Troubleshooting

### Model Not Loading
- Verify `esrgan_fp16.tflite` exists in assets
- Check file size and format
- Look for errors in Android logcat

### Poor Performance
- Verify hardware acceleration is working (check logs)
- Try NCNN instead of TFLite
- Reduce video resolution before upscaling
- Use 2x instead of 4x scale factor

### FFmpeg Errors
- Ensure FFmpeg binary is properly loaded
- Check video format compatibility
- Verify sufficient storage space

### Out of Memory
- Reduce input video resolution
- Lower frame rate (modify fps parameter)
- Close other apps to free memory

## Testing

### Manual Testing
1. Download a test reel
2. Attempt 2x upscaling
3. Verify output quality
4. Test cancellation
5. Test error cases (missing model, etc.)

### Automated Testing
- Unit tests for entity conversions
- Widget tests for UI controls
- Integration tests for full pipeline (requires device)

## License

This implementation is provided as-is. Real-ESRGAN model has its own license terms.
