import '../entities/download_task.dart';
import '../entities/history_entry.dart';

abstract class DownloaderService {
  Future<DownloadTask> queueDownload(String url);

  Stream<DownloadTask> observeTasks();

  Future<List<HistoryEntry>> loadHistory();

  void dispose() {}
}
