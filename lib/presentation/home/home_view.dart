import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/domain/entities/download_metadata.dart';
import 'package:insta_reel_downloader/presentation/home/home_controller.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(homeControllerProvider).url,
    );
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      if (_controller.text != next.url) {
        _controller.value = TextEditingValue(
          text: next.url,
          selection: TextSelection.collapsed(offset: next.url.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final homeController = ref.read(homeControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 720 ? 640.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insta Reel Downloader',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste a reel link to queue downloads and prep upcoming AI upscaling.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    onChanged: homeController.onUrlChanged,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Reel URL',
                      hintText: 'https://instagram.com/reel/...',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: state.isCheckingUrl
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Validating reel link…',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          )
                        : state.validationMessage == null
                            ? const SizedBox.shrink()
                            : Text(
                                state.validationMessage!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: state.isValidUrl
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                    ),
                              ),
                  ),
                  if (state.metadata != null) ...[
                    const SizedBox(height: 12),
                    _MetadataPreview(metadata: state.metadata!),
                  ],
                  const SizedBox(height: 16),
                  
                  // Upscaling options
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Upscaling',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: state.upscaleFactor,
                            decoration: const InputDecoration(
                              labelText: 'Upscale quality',
                              hintText: 'Choose upscaling factor',
                              prefixIcon: Icon(Icons.hd),
                            ),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('No upscaling')),
                              DropdownMenuItem(value: 2, child: Text('2x Quality')),
                              DropdownMenuItem(value: 4, child: Text('4x Quality')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(homeControllerProvider.notifier).onUpscaleFactorChanged(value);
                              }
                            },
                          ),
                          if (state.upscaleFactor > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Video will be upscaled ${state.upscaleFactor}x after download',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.paste),
                        label: const Text('Paste link'),
                        onPressed: homeController.pasteFromClipboard,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share sheet'),
                        onPressed: homeController.shareCurrentLink,
                      ),
                      FilledButton.icon(
                        icon: state.isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          state.isSubmitting
                              ? 'Queuing download'
                              : 'Download reel',
                        ),
                        onPressed: state.canSubmit && !state.isSubmitting
                            ? homeController.enqueueDownload
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: state.feedback == null
                        ? const SizedBox.shrink()
                        : Card(
                            color: state.isError
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    state.isError
                                        ? Icons.warning_rounded
                                        : Icons.check_circle,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(state.feedback!)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetadataPreview extends StatelessWidget {
  const _MetadataPreview({required this.metadata});

  final DownloadMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail with fallback
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primaryContainer,
              ),
              child: metadata.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        metadata.thumbnailUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackIcon(theme);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : _buildFallbackIcon(theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metadata.author,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Duration · ${_formatDuration(metadata.duration)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (metadata.width != null && metadata.height != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${metadata.width}×${metadata.height}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Icon(
      Icons.movie,
      color: theme.colorScheme.onPrimaryContainer,
      size: 30,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (minutes > 0) {
      return '$minutes:$seconds';
    }
    return '${duration.inSeconds}s';
  }
}
