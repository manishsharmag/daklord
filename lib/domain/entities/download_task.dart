import 'package:equatable/equatable.dart';

import 'download_status.dart';

class DownloadTask extends Equatable {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.title,
    this.author,
    this.eta,
    this.completedAt,
    this.thumbnailUrl,
    this.duration,
    this.localPath,
    this.error,
    this.upscaleFactor = 0,
  });

  final String id;
  final String url;
  final String? title;
  final String? author;
  final DownloadStatus status;
  final double progress;
  final Duration? eta;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? localPath;
  final String? error;
  final int upscaleFactor;

  bool get isComplete => status == DownloadStatus.completed;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? author,
    DownloadStatus? status,
    double? progress,
    Duration? eta,
    DateTime? createdAt,
    DateTime? completedAt,
    String? thumbnailUrl,
    Duration? duration,
    String? localPath,
    String? error,
    int? upscaleFactor,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      author: author ?? this.author,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      eta: eta ?? this.eta,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      upscaleFactor: upscaleFactor ?? this.upscaleFactor,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
    'author': author,
    'status': status.key,
    'progress': progress,
    'etaSeconds': eta?.inSeconds,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': duration?.inSeconds,
    'localPath': localPath,
    'error': error,
    'upscaleFactor': upscaleFactor,
  };

  factory DownloadTask.fromMap(Map<dynamic, dynamic> map) {
    final etaSeconds = map['etaSeconds'];
    final durationSeconds = map['durationSeconds'];
    return DownloadTask(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString(),
      author: map['author']?.toString(),
      status: DownloadStatusX.fromKey(map['status']?.toString()),
      progress: _toProgress(map['progress']),
      eta: etaSeconds is num ? Duration(seconds: etaSeconds.toInt()) : null,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      duration: durationSeconds is num ? Duration(seconds: durationSeconds.toInt()) : null,
      localPath: map['localPath']?.toString(),
      error: map['error']?.toString(),
      upscaleFactor: map['upscaleFactor'] is num ? (map['upscaleFactor'] as num).toInt() : 0,
    );
  }

  static double _toProgress(dynamic value) {
    if (value is num) {
      final normalized = value.toDouble();
      if (normalized < 0) return 0;
      if (normalized > 1) return 1;
      return normalized;
    }
    return 0;
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

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        author,
        status,
        progress,
        eta,
        createdAt,
        completedAt,
        thumbnailUrl,
        duration,
        localPath,
        error,
        upscaleFactor,
      ];
}
