import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/core/di/providers.dart';
import 'package:insta_reel_downloader/data/datasources/shared_intent_channel.dart';
import 'package:insta_reel_downloader/data/providers/settings_providers.dart';
import 'package:insta_reel_downloader/domain/entities/download_metadata.dart';
import 'package:insta_reel_downloader/domain/entities/download_task.dart';
import 'package:insta_reel_downloader/domain/entities/url_validation_result.dart';
import 'package:insta_reel_downloader/domain/repositories/download_repository.dart';
import 'package:insta_reel_downloader/presentation/shell/app_shell.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref);
  },
);

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._ref) : super(const HomeState()) {
    _initializeSharedIntent();
  }

  final Ref _ref;
  Timer? _validationTimer;
  late final SharedIntentHandler _sharedIntentHandler;

  DownloadRepository get _repository => _ref.read(downloadRepositoryProvider);

  void _initializeSharedIntent() {
    _sharedIntentHandler = _ref.read(sharedIntentHandlerProvider);
    _checkSharedUrl();
  }

  Future<void> _checkSharedUrl() async {
    try {
      final sharedUrl = await _sharedIntentHandler.getSharedUrl();
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        onUrlChanged(sharedUrl);
        await _sharedIntentHandler.clearSharedUrl();
      }
    } catch (_) {
      // Continue anyway if shared intent handling fails
    }
  }

  void onUrlChanged(String url) {
    _validationTimer?.cancel();
    final trimmed = url.trim();
    state = state.copyWith(
      url: url,
      feedback: null,
      feedbackSpecified: true,
      isError: false,
      isValidUrl: false,
      isCheckingUrl: trimmed.isNotEmpty,
      validationMessage: null,
      validationMessageSpecified: true,
      normalizedUrlSpecified: true,
      normalizedUrl: null,
      metadataSpecified: true,
      metadata: null,
    );
    if (trimmed.isEmpty) {
      state = state.copyWith(
        isCheckingUrl: false,
        validationMessage: null,
        validationMessageSpecified: true,
        metadataSpecified: true,
        metadata: null,
      );
      return;
    }
    _validationTimer = Timer(const Duration(milliseconds: 350), () {
      _validateUrl(trimmed);
    });
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
    onUrlChanged(clipboardValue);
    state = state.copyWith(
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

  Future<void> _validateUrl(String url) async {
    state = state.copyWith(isCheckingUrl: true);
    try {
      final UrlValidationResult validation = await _repository.validateUrl(url);
      if (!mounted) return;
      if (!validation.isValid || validation.normalizedUrl == null) {
        state = state.copyWith(
          isCheckingUrl: false,
          isValidUrl: false,
          validationMessage: validation.reason ?? 'Invalid reel URL',
          metadataSpecified: true,
          metadata: null,
        );
        return;
      }
      final normalized = validation.normalizedUrl!;
      state = state.copyWith(
        isCheckingUrl: false,
        isValidUrl: true,
        normalizedUrl: normalized,
        validationMessage: 'Link looks valid',
      );
      await _hydrateMetadata(normalized);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isCheckingUrl: false,
        isValidUrl: false,
        validationMessage: 'Unable to verify link. Please try again.',
        metadataSpecified: true,
        metadata: null,
      );
    }
  }

  Future<void> _hydrateMetadata(String url) async {
    try {
      final DownloadMetadata metadata = await _repository.fetchMetadata(url);
      if (mounted) {
        state = state.copyWith(metadata: metadata, metadataSpecified: true);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(metadataSpecified: true, metadata: null);
      }
    }
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
      final granted = await _repository.ensureStorageAccess();
      if (!granted) {
        state = state.copyWith(
          isSubmitting: false,
          feedback: 'Storage permission is required to save reels.',
          feedbackSpecified: true,
          isError: true,
        );
        return;
      }
      final url = (state.normalizedUrl ?? state.url).trim();

      // Get the download folder - handle both sync and async providers
      final option = _ref.read(downloadsFolderOptionProvider);
      String? downloadFolder;

      if (option == 'custom') {
        // For custom folders, we need to await the async provider
        try {
          final customPathAsync = await _ref.read(customDownloadsFolderPathAsyncProvider.future);
          downloadFolder = customPathAsync;
        } catch (_) {
          downloadFolder = null;
        }
      } else {
        // For preset options, use the sync provider
        downloadFolder = _ref.read(downloadsFolderPathProvider);
      }

      final DownloadTask task = await _repository.enqueueDownload(
        url,
        downloadFolder: downloadFolder,
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

  void toggleUpscale(bool enabled) {
    state = state.copyWith(upscaleEnabled: enabled);
  }

  void setScaleFactor(int factor) {
    state = state.copyWith(scaleFactor: factor);
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }
}

class HomeState extends Equatable {
  const HomeState({
    this.url = '',
    this.isSubmitting = false,
    this.feedback,
    this.isError = false,
    this.isCheckingUrl = false,
    this.isValidUrl = false,
    this.normalizedUrl,
    this.validationMessage,
    this.metadata,
    this.upscaleEnabled = false,
    this.scaleFactor = 2,
  });

  final String url;
  final bool isSubmitting;
  final String? feedback;
  final bool isError;
  final bool isCheckingUrl;
  final bool isValidUrl;
  final String? normalizedUrl;
  final String? validationMessage;
  final DownloadMetadata? metadata;
  final bool upscaleEnabled;
  final int scaleFactor;

  bool get canSubmit => isValidUrl && !isSubmitting;

  HomeState copyWith({
    String? url,
    bool? isSubmitting,
    String? feedback,
    bool? isError,
    bool? isCheckingUrl,
    bool? isValidUrl,
    String? normalizedUrl,
    String? validationMessage,
    DownloadMetadata? metadata,
    bool? upscaleEnabled,
    int? scaleFactor,
    bool feedbackSpecified = false,
    bool metadataSpecified = false,
    bool normalizedUrlSpecified = false,
    bool validationMessageSpecified = false,
  }) {
    return HomeState(
      url: url ?? this.url,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: feedbackSpecified ? feedback : this.feedback,
      isError: isError ?? this.isError,
      isCheckingUrl: isCheckingUrl ?? this.isCheckingUrl,
      isValidUrl: isValidUrl ?? this.isValidUrl,
      normalizedUrl:
          normalizedUrlSpecified ? normalizedUrl : (normalizedUrl ?? this.normalizedUrl),
      validationMessage: validationMessageSpecified
          ? validationMessage
          : (validationMessage ?? this.validationMessage),
      metadata: metadataSpecified ? metadata : (metadata ?? this.metadata),
      upscaleEnabled: upscaleEnabled ?? this.upscaleEnabled,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }

  @override
  List<Object?> get props => [
        url,
        isSubmitting,
        feedback,
        isError,
        isCheckingUrl,
        isValidUrl,
        normalizedUrl,
        validationMessage,
        metadata,
        upscaleEnabled,
        scaleFactor,
      ];
}
