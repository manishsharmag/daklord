import 'package:flutter/material.dart';

import 'package:insta_reel_downloader/domain/entities/download_status.dart';
import 'package:insta_reel_downloader/domain/entities/download_task.dart';

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressText = '${(task.progress * 100).toStringAsFixed(0)}%';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title ?? task.url,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _statusLabel(task.status),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(progressText, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            if (task.eta != null) ...[
              const SizedBox(height: 8),
              Text('ETA · ${_formatDuration(task.eta!)}'),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.preparing:
        return 'Preparing stream';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }
}
