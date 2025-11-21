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
    this.eta,
    this.completedAt,
    this.thumbnailUrl,
  });

  final String id;
  final String url;
  final String? title;
  final DownloadStatus status;
  final double progress;
  final Duration? eta;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? thumbnailUrl;

  bool get isComplete => status == DownloadStatus.completed;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    DownloadStatus? status,
    double? progress,
    Duration? eta,
    DateTime? createdAt,
    DateTime? completedAt,
    String? thumbnailUrl,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      eta: eta ?? this.eta,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
    'status': status.key,
    'progress': progress,
    'etaSeconds': eta?.inSeconds,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'thumbnailUrl': thumbnailUrl,
  };

  factory DownloadTask.fromMap(Map<dynamic, dynamic> map) {
    final etaSeconds = map['etaSeconds'];
    return DownloadTask(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString(),
      status: DownloadStatusX.fromKey(map['status']?.toString()),
      progress: _toProgress(map['progress']),
      eta: etaSeconds is num ? Duration(seconds: etaSeconds.toInt()) : null,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
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
    status,
    progress,
    eta,
    createdAt,
    completedAt,
    thumbnailUrl,
  ];
}
