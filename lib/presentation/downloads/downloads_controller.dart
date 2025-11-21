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
    _subscription = _repository.watchDownloads().listen((tasks) {
      state = state.copyWith(activeTasks: tasks, isLoading: false);
    });
    _bootstrapHistory();
  }

  final Ref _ref;
  StreamSubscription<List<DownloadTask>>? _subscription;

  DownloadRepository get _repository => _ref.read(downloadRepositoryProvider);

  Future<void> _bootstrapHistory() async {
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
    await _bootstrapHistory();
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
