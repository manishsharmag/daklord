import '../entities/download_metadata.dart';
import '../entities/download_task.dart';
import '../entities/history_entry.dart';
import '../entities/url_validation_result.dart';

abstract class DownloadRepository {
  Future<DownloadTask> enqueueDownload(String url);

  Stream<List<DownloadTask>> watchDownloads();

  Future<List<HistoryEntry>> loadHistory();

  Future<void> upscaleTask(String taskId);

  Future<UrlValidationResult> validateUrl(String url);

  Future<DownloadMetadata> fetchMetadata(String url);

  Future<bool> ensureStorageAccess();

  Future<void> cancelTask(String taskId);

  Future<void> retryTask(String taskId);

  Future<void> saveHistoryEntry(HistoryEntry entry);

  Future<void> deleteHistoryEntry(String entryId);

  void dispose() {}
}
