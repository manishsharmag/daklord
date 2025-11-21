abstract class UpscalerService {
  Future<Map<String, dynamic>> upscaleVideo({
    required String videoPath,
    required int scaleFactor,
  });

  Future<void> cancelUpscale(String taskId);

  Future<List<Map<String, dynamic>>> getActiveTasks();

  Stream<Map<String, dynamic>> get progressStream;

  void dispose() {}
}
