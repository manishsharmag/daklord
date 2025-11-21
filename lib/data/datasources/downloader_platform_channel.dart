import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../core/constants/channel_names.dart';
import '../../domain/entities/download_metadata.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/entities/url_validation_result.dart';
import '../../domain/services/downloader_service.dart';
import 'history_database.dart';

class DownloaderChannelService implements DownloaderService {
  DownloaderChannelService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
    HistoryDatabase? historyDatabase,
  })  : _channel = methodChannel ?? const MethodChannel(ChannelNames.downloader),
        _eventChannel =
            eventChannel ?? const EventChannel(ChannelNames.downloaderEvents),
        _historyDatabase = historyDatabase ?? HistoryDatabase() {
    _subscribeToNativeEvents();
    _bootstrapActiveTasks();
    _initializeDatabase();
  }

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  final HistoryDatabase _historyDatabase;
  final _controller = StreamController<DownloadTask>.broadcast();
  StreamSubscription<dynamic>? _nativeSubscription;
  bool _seededFallbacks = false;
  final _random = Random();

  Future<void> _initializeDatabase() async {
    try {
      await _historyDatabase.initialize();
    } catch (_) {
      // Database initialization error, continue anyway
    }
  }

  @override
  Stream<DownloadTask> observeTasks() => _controller.stream;

  void _subscribeToNativeEvents() {
    try {
      _nativeSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(_handleNativeEvent, onError: _handleNativeError);
    } on MissingPluginException {
      _seedFallbackTraffic();
    }
  }

  Future<void> _bootstrapActiveTasks() async {
    try {
      final payload = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('getActiveDownloads');
      if (payload == null) return;
      for (final raw in payload) {
        _emitTask(DownloadTask.fromMap(raw));
      }
    } on MissingPluginException {
      _seedFallbackTraffic();
    } on PlatformException {
      _seedFallbackTraffic();
    }
  }

  void _handleNativeEvent(dynamic event) {
    final map = _coerceMap(event);
    if (map == null) return;
    _emitTask(DownloadTask.fromMap(map));
  }

  void _handleNativeError(Object error) {
    if (_seededFallbacks) return;
    _seedFallbackTraffic();
  }

  Map<String, dynamic>? _coerceMap(dynamic payload) {
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  @override
  Future<DownloadTask> queueDownload(String url) async {
    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'queueDownload',
        {'url': url},
      );
      if (payload != null) {
        final task = DownloadTask.fromMap(payload);
        _emitTask(task);
        return task;
      }
    } on PlatformException {
      // Fall through to synthetic fallback.
    } on MissingPluginException {
      // Fall through to synthetic fallback.
    }
    final task = _syntheticTask(url);
    _emitTask(task);
    return task;
  }

  @override
  Future<List<HistoryEntry>> loadHistory() async {
    try {
      final localEntries = await _historyDatabase.loadAll();
      if (localEntries.isNotEmpty) {
        return localEntries;
      }
    } catch (_) {
      // Continue to native fallback
    }
    try {
      final payload = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'loadHistory',
      );
      if (payload != null && payload.isNotEmpty) {
        return payload.map(HistoryEntry.fromMap).toList();
      }
    } on PlatformException {
      // Ignore and fallback.
    } on MissingPluginException {
      // Ignore and fallback.
    }
    return _syntheticHistory();
  }

  @override
  Future<List<DownloadTask>> loadActiveTasks() async {
    try {
      final payload = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('getActiveDownloads');
      if (payload == null) return const [];
      return payload.map(DownloadTask.fromMap).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<UrlValidationResult> validateUrl(String url) async {
    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'validateUrl',
        {'url': url},
      );
      return UrlValidationResult.fromMap(payload);
    } catch (_) {
      final normalized = url.trim();
      final isValid = normalized.contains('instagram.com/reel');
      return UrlValidationResult(
        originalUrl: url,
        normalizedUrl: isValid ? normalized : null,
        isValid: isValid,
        reason: isValid ? null : 'URL must point to an Instagram reel',
      );
    }
  }

  @override
  Future<DownloadMetadata> extractMetadata(String url) async {
    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'extractMetadata',
        {'url': url},
      );
      if (payload != null) {
        return DownloadMetadata.fromMap(payload);
      }
    } catch (_) {
      // Fall through to heuristic metadata.
    }
    return DownloadMetadata(
      url: url,
      title: 'Reel preview',
      author: '@instagram',
      duration: const Duration(seconds: 45),
      thumbnailUrl: null,
      width: 1080,
      height: 1920,
    );
  }

  @override
  Future<bool> ensureStorageAccess() async {
    try {
      final granted = await _channel.invokeMethod<bool>('ensureStorageAccess');
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    try {
      await _channel.invokeMethod('cancelDownload', {'taskId': taskId});
    } catch (_) {
      // Ignore errors to keep UI responsive.
    }
  }

  @override
  Future<void> retryDownload(String taskId) async {
    try {
      await _channel.invokeMethod('retryDownload', {'taskId': taskId});
    } catch (_) {
      // Ignore errors to keep UI responsive.
    }
  }

  @override
  Future<void> saveHistoryEntry(HistoryEntry entry) async {
    try {
      await _historyDatabase.saveEntry(entry);
    } catch (_) {
      // Database save error, continue anyway
    }
  }

  @override
  Future<void> deleteHistoryEntry(String entryId) async {
    try {
      await _historyDatabase.deleteEntry(entryId);
    } catch (_) {
      // Database delete error, continue anyway
    }
  }

  void _seedFallbackTraffic() {
    if (_seededFallbacks) return;
    _seededFallbacks = true;
    final placeholders = [
      DownloadTask(
        id: 'seed-downloading',
        url: 'https://instagram.com/reel/demo-1',
        title: 'Street fashion drop',
        author: '@demo',
        status: DownloadStatus.downloading,
        progress: 0.42,
        eta: const Duration(minutes: 2, seconds: 10),
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        thumbnailUrl: null,
        duration: const Duration(seconds: 45),
        localPath: null,
        error: null,
      ),
      DownloadTask(
        id: 'seed-queued',
        url: 'https://instagram.com/reel/demo-2',
        title: 'Food vlog mashup',
        author: '@demo',
        status: DownloadStatus.preparing,
        progress: 0.15,
        eta: const Duration(minutes: 5),
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        thumbnailUrl: null,
        duration: const Duration(seconds: 60),
        localPath: null,
        error: null,
      ),
    ];

    for (final task in placeholders) {
      _emitTask(task);
    }
  }

  DownloadTask _syntheticTask(String url) {
    final suffix = _random.nextInt(9999).toString().padLeft(4, '0');
    return DownloadTask(
      id: 'synthetic-$suffix',
      url: url,
      title: 'Queued reel $suffix',
      author: '@instagram',
      status: DownloadStatus.queued,
      progress: 0,
      createdAt: DateTime.now(),
      eta: const Duration(minutes: 3),
      thumbnailUrl: null,
      duration: const Duration(seconds: 50),
      localPath: null,
      error: null,
    );
  }

  List<HistoryEntry> _syntheticHistory() {
    return [
      HistoryEntry(
        id: 'history-1',
        url: 'https://instagram.com/reel/history-1',
        title: 'Dance challenge compilation',
        author: '@demo',
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: DownloadStatus.completed,
        thumbnailUrl: null,
        duration: const Duration(seconds: 45),
        localPath: '/storage/emulated/0/Movies/demo1.mp4',
        error: null,
      ),
      HistoryEntry(
        id: 'history-2',
        url: 'https://instagram.com/reel/history-2',
        title: 'Cityscape timelapse',
        author: '@demo',
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        status: DownloadStatus.completed,
        thumbnailUrl: null,
        duration: const Duration(minutes: 1, seconds: 12),
        localPath: '/storage/emulated/0/Movies/demo2.mp4',
        error: null,
      ),
    ];
  }

  void _emitTask(DownloadTask task) {
    if (!_controller.isClosed) {
      _controller.add(task);
    }
  }

  @override
  void dispose() {
    _nativeSubscription?.cancel();
    _controller.close();
    _historyDatabase.close();
  }
}
