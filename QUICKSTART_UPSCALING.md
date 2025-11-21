# Quick Start: Video Upscaling

This guide helps you get the upscaling feature running.

## For End Users

### How to Upscale a Video

1. **Download a video**
   - Go to Home tab
   - Paste an Instagram reel URL
   - Wait for download to complete

2. **Configure upscaling**
   - Go to Settings tab
   - Use the slider to choose scale factor (2x or 4x)
   - 2x is faster, 4x is higher quality but slower

3. **Start upscaling**
   - Go to Downloads tab
   - Find your completed download in History
   - Tap the "Upscale" button
   - A notification will confirm it started

4. **Monitor progress**
   - Watch the "Active upscaling" section
   - Real-time progress bar shows status
   - Process can take 30-120 seconds depending on video length and device

5. **Access upscaled video**
   - Upscaled video saved to: `{original_path}/upscaled/`
   - Example: `Downloads/video.mp4` → `Downloads/upscaled/video_2x.mp4`

### Cancel Upscaling

- Tap the "Cancel" button in the Active upscaling card
- Temporary files are automatically cleaned up

## For Developers

### Quick Setup (No Model)

The implementation includes a fallback bicubic upscaler, so you can test without the ML model:

```bash
# Build and run
flutter pub get
flutter run
```

The app will use bicubic scaling if no model is found.

### Full Setup (With Real-ESRGAN Model)

1. **Obtain or convert Real-ESRGAN model to TFLite**

```python
# Example conversion (requires TensorFlow, PyTorch, ONNX)
# See UPSCALING.md for detailed instructions

import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('esrgan_model')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open('esrgan_fp16.tflite', 'wb') as f:
    f.write(tflite_model)
```

2. **Place model in assets**

```bash
cp esrgan_fp16.tflite android/app/src/main/assets/upscaler/
```

3. **Build and run**

```bash
flutter pub get
flutter run --release  # Release mode recommended for best performance
```

### Testing Upscaling

```dart
// Test upscaling programmatically
final upscaleController = ref.read(upscaleControllerProvider.notifier);

try {
  await upscaleController.upscaleVideo(
    videoPath: '/path/to/downloaded/video.mp4',
    scaleFactor: 2,
  );
  print('Upscaling started!');
} catch (e) {
  print('Error: $e');
}

// Listen to progress
ref.listen(upscaleControllerProvider, (previous, next) {
  for (final task in next.activeTasks) {
    print('${task.status}: ${(task.progress * 100).toStringAsFixed(1)}%');
  }
});
```

### Debug Logging

To see upscaling logs:

```bash
# Android
adb logcat | grep -i "upscaler\|esrgan\|tflite"

# Check for model loading
adb logcat | grep -i "model"

# Check FFmpeg operations
adb logcat | grep -i "ffmpeg"
```

### Common Issues

**Model not loading**
```
Solution: Check that esrgan_fp16.tflite is in android/app/src/main/assets/upscaler/
Workaround: Will use bicubic fallback
```

**Out of memory**
```
Solution: Reduce video resolution or use 2x instead of 4x
Note: High-res videos need more memory
```

**Slow performance**
```
Solution: Run in release mode with --release flag
Check: Verify GPU/NNAPI acceleration in logs
```

**FFmpeg errors**
```
Solution: Ensure FFmpeg binary is properly loaded from jniLibs
Check: Look for libffmpeg_bridge.so in app/src/main/jniLibs/
```

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │DownloadsView│  │SettingsView │  │UpscaleCtrl  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└───────────────────────────┬─────────────────────────────┘
                            │
                   ┌────────▼────────┐
                   │  MethodChannel  │
                   │  EventChannel   │
                   └────────┬────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                   Kotlin Native Layer                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │            UpscalerBridge                        │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │  │
│  │  │TFLite    │  │FFmpeg    │  │Progress  │      │  │
│  │  │+NNAPI/GPU│  │Extract   │  │Reporting │      │  │
│  │  │          │  │Encode    │  │          │      │  │
│  │  └──────────┘  └──────────┘  └──────────┘      │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Performance Tips

1. **Use 2x for faster processing** - Typically 30-60 seconds
2. **Use 4x for best quality** - Typically 60-120 seconds
3. **Close other apps** - Frees memory for processing
4. **Run in release mode** - 2-3x faster than debug
5. **Shorter videos process faster** - ~2 seconds per second of video

## Model Sources

For production, you can:
1. Train your own Real-ESRGAN model
2. Use pre-trained Real-ESRGAN weights (check license)
3. Use alternative super-resolution models (EDSR, SRCNN, etc.)
4. Convert existing PyTorch/ONNX models to TFLite

Popular options:
- [Real-ESRGAN GitHub](https://github.com/xinntao/Real-ESRGAN)
- [BasicSR Models](https://github.com/XPixelGroup/BasicSR)
- TensorFlow Hub super-resolution models

## Support

For issues or questions:
- Check `UPSCALING.md` for comprehensive documentation
- Review Android logcat for error messages
- Verify model file exists and is valid TFLite format
- Test with bicubic fallback first (no model needed)

## Next Steps

1. Test with sample videos
2. Adjust scale factor based on needs
3. Monitor performance on target devices
4. Add custom models if needed
5. Fine-tune FFmpeg encoding parameters
6. Implement background processing (future)
