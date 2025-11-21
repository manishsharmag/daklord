import 'dart:async';

import '../../domain/entities/download_task.dart';
import '../../domain/entities/history_entry.dart';
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
    _taskSubscription = _downloaderService.observeTasks().listen(_handleTask);
  }

  final DownloaderService _downloaderService;
  final UpscalerService _upscalerService;
  final _tasks = <DownloadTask>[];
  final _tasksController = StreamController<List<DownloadTask>>.broadcast();
  late final StreamSubscription<DownloadTask> _taskSubscription;

  void _handleTask(DownloadTask task) {
    final index = _tasks.indexWhere((element) => element.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
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
  Future<void> upscaleTask(String taskId) =>
      _upscalerService.upscaleVideo(taskId);

  @override
  void dispose() {
    _taskSubscription.cancel();
    _tasksController.close();
    _downloaderService.dispose();
    _upscalerService.dispose();
  }
}
