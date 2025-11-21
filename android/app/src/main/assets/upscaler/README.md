# ESRGAN Model Assets

This directory should contain the Real-ESRGAN model converted to TensorFlow Lite format.

## Required File

- `esrgan_fp16.tflite` - Real-ESRGAN model in TFLite fp16 format optimized for mobile

## Model Conversion

To convert Real-ESRGAN to TFLite format:

1. Export the PyTorch model to ONNX
2. Convert ONNX to TensorFlow using onnx-tf
3. Convert TensorFlow to TFLite with fp16 quantization
4. Place the resulting .tflite file in this directory

Example conversion script:
```python
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('esrgan_saved_model')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open('esrgan_fp16.tflite', 'wb') as f:
    f.write(tflite_model)
```

## Alternative: NCNN Format

For better performance on some devices, you can also use NCNN format:
- `esrgan.param` - NCNN parameter file
- `esrgan.bin` - NCNN weights file

The upscaler will fall back to bicubic upscaling if no model is found.
