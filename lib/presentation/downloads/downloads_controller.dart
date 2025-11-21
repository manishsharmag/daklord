import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/core/di/providers.dart';
import 'package:insta_reel_downloader/domain/entities/download_task.dart';
import 'package:insta_reel_downloader/domain/entities/history_entry.dart';
import 'package:insta_reel_downloader/domain/repositories/download_repository.dart';

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
          .map((task) => task.id)
          .toList();
      if (newlyCompleted.isNotEmpty) {
        _syncedHistoryIds.addAll(newlyCompleted);
        await _refreshHistoryInternal();
      }
    });
    unawaited(_refreshHistoryInternal());
  }

  final Ref _ref;
  final _syncedHistoryIds = <String>{};
  StreamSubscription<List<DownloadTask>>? _subscription;

  DownloadRepository get _repository => _ref.read(downloadRepositoryProvider);

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
