import '../entities/download_task.dart';
import '../entities/history_entry.dart';

abstract class DownloadRepository {
  Future<DownloadTask> enqueueDownload(String url);

  Stream<List<DownloadTask>> watchDownloads();

  Future<List<HistoryEntry>> loadHistory();

  Future<void> upscaleTask(String taskId);

  void dispose() {}
}
