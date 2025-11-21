import 'dart:async';

import '../../domain/entities/download_metadata.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/entities/url_validation_result.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/services/downloader_service.dart';
import '../../domain/services/upscaler_service.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl({
    required DownloaderService downloaderService,
    required UpscalerService upscalerService,
  }) : _downloaderService = downloaderService,
       _upscalerService = upscalerService {
    _tasksController.add(const <DownloadTask>[]);
    unawaited(_primeActiveTasks());
    _taskSubscription = _downloaderService.observeTasks().listen(_handleTask);
  }

  final DownloaderService _downloaderService;
  final UpscalerService _upscalerService;
  final _tasks = <DownloadTask>[];
  final _tasksController = StreamController<List<DownloadTask>>.broadcast();
  late final StreamSubscription<DownloadTask> _taskSubscription;

  Future<void> _primeActiveTasks() async {
    try {
      final tasks = await _downloaderService.loadActiveTasks();
      if (tasks.isEmpty) return;
      for (final task in tasks) {
        _handleTask(task);
      }
    } catch (_) {
      // Native bootstrapping is best-effort.
    }
  }

  void _handleTask(DownloadTask task) {
    final index = _tasks.indexWhere((element) => element.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _tasksController.add(List.unmodifiable(_tasks));
  }

  @override
  Future<DownloadTask> enqueueDownload(String url) async {
    final task = await _downloaderService.queueDownload(url);
    return task;
  }

  @override
  Stream<List<DownloadTask>> watchDownloads() => _tasksController.stream;

  @override
  Future<List<HistoryEntry>> loadHistory() => _downloaderService.loadHistory();

  @override
  Future<void> upscaleTask(String taskId) async {
    // This method is deprecated - upscaling now handled directly via UpscaleController
    // Keeping for backward compatibility but marking as no-op
  }

  @override
  Future<UrlValidationResult> validateUrl(String url) =>
      _downloaderService.validateUrl(url);

  @override
  Future<DownloadMetadata> fetchMetadata(String url) =>
      _downloaderService.extractMetadata(url);

  @override
  Future<bool> ensureStorageAccess() =>
      _downloaderService.ensureStorageAccess();

  @override
  Future<void> cancelTask(String taskId) =>
      _downloaderService.cancelDownload(taskId);

  @override
  Future<void> retryTask(String taskId) =>
      _downloaderService.retryDownload(taskId);

  @override
  Future<void> saveHistoryEntry(HistoryEntry entry) =>
      _downloaderService.saveHistoryEntry(entry);

  @override
  Future<void> deleteHistoryEntry(String entryId) =>
      _downloaderService.deleteHistoryEntry(entryId);

  @override
  void dispose() {
    _taskSubscription.cancel();
    _tasksController.close();
    _downloaderService.dispose();
    _upscalerService.dispose();
  }
}
