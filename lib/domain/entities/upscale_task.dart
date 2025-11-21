import 'package:equatable/equatable.dart';

import 'upscale_status.dart';

class UpscaleTask extends Equatable {
  const UpscaleTask({
    required this.id,
    required this.videoPath,
    required this.scaleFactor,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.completedAt,
    this.outputPath,
    this.error,
  });

  final String id;
  final String videoPath;
  final int scaleFactor;
  final UpscaleStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? outputPath;
  final String? error;

  factory UpscaleTask.fromMap(Map<String, dynamic> map) {
    return UpscaleTask(
      id: map['id'] as String,
      videoPath: map['videoPath'] as String,
      scaleFactor: map['scaleFactor'] as int,
      status: UpscaleStatus.fromWireValue(map['status'] as String),
      progress: (map['progress'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      outputPath: map['outputPath'] as String?,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoPath': videoPath,
      'scaleFactor': scaleFactor,
      'status': status.wireValue,
      'progress': progress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'outputPath': outputPath,
      'error': error,
    };
  }

  UpscaleTask copyWith({
    String? id,
    String? videoPath,
    int? scaleFactor,
    UpscaleStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
    String? outputPath,
    String? error,
  }) {
    return UpscaleTask(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      outputPath: outputPath ?? this.outputPath,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        id,
        videoPath,
        scaleFactor,
        status,
        progress,
        createdAt,
        completedAt,
        outputPath,
        error,
      ];
}
