import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/core/di/providers.dart';
import 'package:insta_reel_downloader/domain/entities/download_task.dart';
import 'package:insta_reel_downloader/presentation/shell/app_shell.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref);
  },
);

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._ref) : super(const HomeState());

  final Ref _ref;

  void onUrlChanged(String url) {
    state = state.copyWith(
      url: url,
      feedback: null,
      feedbackSpecified: true,
      isError: false,
    );
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final clipboardValue = data?.text?.trim();
    if (clipboardValue == null || clipboardValue.isEmpty) {
      state = state.copyWith(
        feedback: 'Clipboard is empty',
        feedbackSpecified: true,
        isError: true,
      );
      return;
    }
    state = state.copyWith(
      url: clipboardValue,
      feedback: 'Link pasted',
      feedbackSpecified: true,
      isError: false,
    );
  }

  Future<void> shareCurrentLink() async {
    state = state.copyWith(
      feedback: 'Share targets will surface once native integration lands.',
      feedbackSpecified: true,
      isError: false,
    );
  }

  Future<void> enqueueDownload() async {
    if (!state.canSubmit) {
      state = state.copyWith(
        feedback: 'Paste a valid reel URL first.',
        feedbackSpecified: true,
        isError: true,
      );
      return;
    }
    state = state.copyWith(
      isSubmitting: true,
      feedback: null,
      feedbackSpecified: true,
    );
    try {
      final repository = _ref.read(downloadRepositoryProvider);
      final DownloadTask task = await repository.enqueueDownload(
        state.url.trim(),
      );
      state = state.copyWith(
        isSubmitting: false,
        feedback: 'Queued ${task.title ?? 'new reel'}',
        feedbackSpecified: true,
        isError: false,
      );
      _ref.read(navigationIndexProvider.notifier).state = 1;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedback: 'Unable to queue download. Please try again.',
        feedbackSpecified: true,
        isError: true,
      );
    }
  }
}

class HomeState extends Equatable {
  const HomeState({
    this.url = '',
    this.isSubmitting = false,
    this.feedback,
    this.isError = false,
  });

  final String url;
  final bool isSubmitting;
  final String? feedback;
  final bool isError;

  bool get canSubmit => url.trim().isNotEmpty && !isSubmitting;

  HomeState copyWith({
    String? url,
    bool? isSubmitting,
    String? feedback,
    bool? isError,
    bool feedbackSpecified = false,
  }) {
    return HomeState(
      url: url ?? this.url,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: feedbackSpecified ? feedback : this.feedback,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [url, isSubmitting, feedback, isError];
}
