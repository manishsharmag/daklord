import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../core/constants/channel_names.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/services/downloader_service.dart';

class DownloaderChannelService implements DownloaderService {
  DownloaderChannelService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(ChannelNames.downloader) {
    _seedPlaceholderTraffic();
  }

  final MethodChannel _channel;
  final _controller = StreamController<DownloadTask>.broadcast();
  final _random = Random();

  @override
  Stream<DownloadTask> observeTasks() => _controller.stream;

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
      // Fall through to synthetic task below.
    } on MissingPluginException {
      // Fall through to synthetic task below.
    }
    final task = _syntheticTask(url);
    _emitTask(task);
    return task;
  }

  @override
  Future<List<HistoryEntry>> loadHistory() async {
    try {
      final payload = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'loadHistory',
      );
      if (payload != null && payload.isNotEmpty) {
        return payload.map(HistoryEntry.fromMap).toList();
      }
    } on PlatformException {
      // Ignore and use placeholder.
    } on MissingPluginException {
      // Ignore and use placeholder.
    }
    return _syntheticHistory();
  }

  void _seedPlaceholderTraffic() {
    final placeholders = [
      DownloadTask(
        id: 'seed-downloading',
        url: 'https://instagram.com/reel/demo-1',
        title: 'Street fashion drop',
        status: DownloadStatus.downloading,
        progress: 0.42,
        eta: const Duration(minutes: 2, seconds: 10),
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        thumbnailUrl: null,
      ),
      DownloadTask(
        id: 'seed-queued',
        url: 'https://instagram.com/reel/demo-2',
        title: 'Food vlog mashup',
        status: DownloadStatus.preparing,
        progress: 0.15,
        eta: const Duration(minutes: 5),
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        thumbnailUrl: null,
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
      status: DownloadStatus.queued,
      progress: 0,
      createdAt: DateTime.now(),
      eta: const Duration(minutes: 3),
      thumbnailUrl: null,
    );
  }

  List<HistoryEntry> _syntheticHistory() {
    return [
      HistoryEntry(
        id: 'history-1',
        url: 'https://instagram.com/reel/history-1',
        title: 'Dance challenge compilation',
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: DownloadStatus.completed,
        thumbnailUrl: null,
        duration: const Duration(seconds: 45),
      ),
      HistoryEntry(
        id: 'history-2',
        url: 'https://instagram.com/reel/history-2',
        title: 'Cityscape timelapse',
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        status: DownloadStatus.completed,
        thumbnailUrl: null,
        duration: const Duration(minutes: 1, seconds: 12),
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
    _controller.close();
  }
}
