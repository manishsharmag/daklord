import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/core/di/providers.dart';
import 'package:insta_reel_downloader/domain/entities/download_status.dart';
import 'package:insta_reel_downloader/domain/entities/download_task.dart';
import 'package:insta_reel_downloader/domain/entities/history_entry.dart';
import 'package:insta_reel_downloader/domain/repositories/download_repository.dart';
import 'package:insta_reel_downloader/presentation/settings/settings_view.dart';

final downloadsControllerProvider =
    StateNotifierProvider<DownloadsController, DownloadsState>((ref) {
      return DownloadsController(ref);
    });

class DownloadsController extends StateNotifier<DownloadsState> {
  DownloadsController(this._ref) : super(const DownloadsState.loading()) {
    _subscription = _repository.watchDownloads().listen((tasks) async {
      final active = tasks.where((task) => !task.isComplete).toList();
      if (mounted) {
        state = state.copyWith(activeTasks: active, isLoading: false);
      }
      final newlyCompleted = tasks
          .where((task) => task.isComplete && !_syncedHistoryIds.contains(task.id))
          .toList();
      if (newlyCompleted.isNotEmpty) {
        _syncedHistoryIds.addAll(newlyCompleted.map((t) => t.id));
        final autoSave = _ref.read(autoSaveHistoryProvider);
        final privacyMode = _ref.read(privacyModeProvider);
        if (autoSave && !privacyMode) {
          for (final task in newlyCompleted) {
            await _saveTaskToHistory(task);
          }
        }
        await _refreshHistoryInternal();
      }
    });
    unawaited(_refreshHistoryInternal());
  }

  final Ref _ref;
  final _syncedHistoryIds = <String>{};
  StreamSubscription<List<DownloadTask>>? _subscription;

  DownloadRepository get _repository => _ref.read(downloadRepositoryProvider);

  Future<void> _saveTaskToHistory(DownloadTask task) async {
    try {
      final entry = HistoryEntry(
        id: task.id,
        url: task.url,
        completedAt: task.completedAt ?? DateTime.now(),
        status: task.status,
        title: task.title,
        author: task.author,
        thumbnailUrl: task.thumbnailUrl,
        duration: task.duration,
        localPath: task.localPath,
        error: task.error,
      );
      await _repository.saveHistoryEntry(entry);
    } catch (_) {
      // Ignore save errors
    }
  }

  Future<void> _refreshHistoryInternal() async {
    try {
      final entries = await _repository.loadHistory();
      if (mounted) {
        state = state.copyWith(history: entries, isLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> refreshHistory() async {
    state = state.copyWith(isLoading: true);
    await _refreshHistoryInternal();
  }

  Future<void> cancelTask(String taskId) => _repository.cancelTask(taskId);

  Future<void> retryTask(String taskId) => _repository.retryTask(taskId);

  Future<void> deleteHistoryEntry(String entryId) async {
    try {
      await _repository.deleteHistoryEntry(entryId);
      await _refreshHistoryInternal();
    } catch (_) {
      // Error occurred, try to refresh state anyway
      await _refreshHistoryInternal();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class DownloadsState extends Equatable {
  const DownloadsState({
    this.activeTasks = const <DownloadTask>[],
    this.history = const <HistoryEntry>[],
    this.isLoading = false,
  });

  const DownloadsState.loading()
    : activeTasks = const <DownloadTask>[],
      history = const <HistoryEntry>[],
      isLoading = true;

  final List<DownloadTask> activeTasks;
  final List<HistoryEntry> history;
  final bool isLoading;

  DownloadsState copyWith({
    List<DownloadTask>? activeTasks,
    List<HistoryEntry>? history,
    bool? isLoading,
  }) {
    return DownloadsState(
      activeTasks: activeTasks ?? this.activeTasks,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [activeTasks, history, isLoading];
}
