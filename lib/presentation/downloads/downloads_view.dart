import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/domain/entities/download_status.dart';
import 'package:insta_reel_downloader/presentation/downloads/downloads_controller.dart';
import 'package:insta_reel_downloader/presentation/widgets/download_task_tile.dart';

class DownloadsView extends ConsumerWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadsControllerProvider);
    final controller = ref.read(downloadsControllerProvider.notifier);

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
              child: ListTile(
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
