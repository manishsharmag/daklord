import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/domain/entities/download_status.dart';
import 'package:insta_reel_downloader/domain/entities/upscale_status.dart';
import 'package:insta_reel_downloader/presentation/downloads/downloads_controller.dart';
import 'package:insta_reel_downloader/presentation/downloads/upscale_controller.dart';
import 'package:insta_reel_downloader/presentation/settings/settings_view.dart';
import 'package:insta_reel_downloader/presentation/widgets/download_task_tile.dart';

class DownloadsView extends ConsumerWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadsControllerProvider);
    final controller = ref.read(downloadsControllerProvider.notifier);
    final upscaleState = ref.watch(upscaleControllerProvider);
    final upscaleController = ref.read(upscaleControllerProvider.notifier);
    final scaleFactor = ref.watch(upscaleScaleFactorProvider);

    return RefreshIndicator(
      onRefresh: controller.refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.isLoading
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Active downloads',
            subtitle: state.activeTasks.isEmpty
                ? 'Queued reels will appear here.'
                : 'Monitor progress and status in real time.',
          ),
          const SizedBox(height: 8),
          if (state.activeTasks.isEmpty) const _EmptyDownloadsState(),
          ...state.activeTasks.map((task) {
            final isCancelable = task.status == DownloadStatus.queued ||
                task.status == DownloadStatus.preparing ||
                task.status == DownloadStatus.downloading;
            final isRetryable = task.status == DownloadStatus.failed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DownloadTaskTile(
                task: task,
                onCancel: isCancelable
                    ? () {
                        unawaited(controller.cancelTask(task.id));
                      }
                    : null,
                onRetry: isRetryable
                    ? () {
                        unawaited(controller.retryTask(task.id));
                      }
                    : null,
              ),
            );
          }),
          if (upscaleState.activeTasks.isNotEmpty) ...[
            const Divider(height: 48),
            _SectionHeader(
              title: 'Active upscaling',
              subtitle: 'AI-powered video enhancement in progress.',
            ),
            const SizedBox(height: 8),
            ...upscaleState.activeTasks.map((task) {
              final isCancelable = task.status != UpscaleStatus.completed &&
                  task.status != UpscaleStatus.failed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${task.scaleFactor}x Upscaling',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    _upscaleStatusLabel(task.status),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(task.progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          child: LinearProgressIndicator(
                            value: task.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                          ),
                        ),
                        if (task.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        if (isCancelable) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  unawaited(upscaleController.cancelTask(task.id));
                                },
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const Divider(height: 48),
          _SectionHeader(
            title: 'History',
            subtitle:
                'Recent completions sync with your scoped storage directory.',
          ),
          const SizedBox(height: 8),
          if (state.history.isEmpty)
            const Text('No history yet. Complete a download to see it listed.'),
          ...state.history.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.movie),
                    title: Text(entry.title ?? entry.url),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Completed ${_timeAgo(entry.completedAt)} · '
                          '${entry.author ?? entry.url}',
                        ),
                        if (entry.localPath != null)
                          Text(
                            entry.localPath!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: Icon(
                      entry.status == DownloadStatus.completed
                          ? Icons.check_circle
                          : Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (entry.localPath != null &&
                      entry.status == DownloadStatus.completed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              try {
                                await upscaleController.upscaleVideo(
                                  videoPath: entry.localPath!,
                                  scaleFactor: scaleFactor,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Started ${scaleFactor}x upscaling',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: Text('Upscale ${scaleFactor}x'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  static String _upscaleStatusLabel(UpscaleStatus status) {
    switch (status) {
      case UpscaleStatus.queued:
        return 'Queued';
      case UpscaleStatus.preparing:
        return 'Preparing';
      case UpscaleStatus.extractingFrames:
        return 'Extracting frames';
      case UpscaleStatus.upscaling:
        return 'Upscaling with AI';
      case UpscaleStatus.encoding:
        return 'Encoding video';
      case UpscaleStatus.completed:
        return 'Completed';
      case UpscaleStatus.failed:
        return 'Failed';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyDownloadsState extends StatelessWidget {
  const _EmptyDownloadsState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No downloads yet. Paste a URL on the home tab to get started.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
