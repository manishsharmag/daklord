import '../entities/download_metadata.dart';
import '../entities/download_task.dart';
import '../entities/history_entry.dart';
import '../entities/url_validation_result.dart';

abstract class DownloaderService {
  Future<DownloadTask> queueDownload(String url, {int upscaleFactor = 0});

  Stream<DownloadTask> observeTasks();

  Future<List<HistoryEntry>> loadHistory();

  Future<List<DownloadTask>> loadActiveTasks();

  Future<UrlValidationResult> validateUrl(String url);

  Future<DownloadMetadata> extractMetadata(String url);

  Future<bool> ensureStorageAccess();

  Future<void> cancelDownload(String taskId);

  Future<void> retryDownload(String taskId);

  Future<void> saveHistoryEntry(HistoryEntry entry);

  Future<void> deleteHistoryEntry(String entryId);

  void dispose() {}
}
