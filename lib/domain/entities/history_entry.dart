import 'package:equatable/equatable.dart';

import 'download_status.dart';

class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.url,
    required this.completedAt,
    required this.status,
    this.title,
    this.author,
    this.thumbnailUrl,
    this.duration,
    this.localPath,
    this.error,
  });

  final String id;
  final String url;
  final String? title;
  final String? author;
  final DateTime completedAt;
  final DownloadStatus status;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? localPath;
  final String? error;

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    final durationSeconds = map['durationSeconds'];
    return HistoryEntry(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString(),
      author: map['author']?.toString(),
      completedAt: _parseDateTime(map['completedAt']) ?? DateTime.now(),
      status: DownloadStatusX.fromKey(map['status']?.toString()),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      duration: durationSeconds is num
          ? Duration(seconds: durationSeconds.toInt())
          : null,
      localPath: map['localPath']?.toString(),
      error: map['error']?.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
    'author': author,
    'completedAt': completedAt.toIso8601String(),
    'status': status.key,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': duration?.inSeconds,
    'localPath': localPath,
    'error': error,
  };

  @override
  List<Object?> get props => [
    id,
    url,
    title,
    author,
    completedAt,
    status,
    thumbnailUrl,
    duration,
    localPath,
    error,
  ];
}
