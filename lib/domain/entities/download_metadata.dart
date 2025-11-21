import 'package:equatable/equatable.dart';

class DownloadMetadata extends Equatable {
  const DownloadMetadata({
    required this.url,
    required this.title,
    required this.author,
    required this.duration,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  final String url;
  final String title;
  final String author;
  final Duration duration;
  final String? thumbnailUrl;
  final int? width;
  final int? height;

  factory DownloadMetadata.fromMap(Map<dynamic, dynamic> map) {
    final durationSeconds = map['durationSeconds'];
    return DownloadMetadata(
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      author: map['author']?.toString() ?? 'instagram',
      duration: Duration(
        seconds: durationSeconds is num && durationSeconds > 0
            ? durationSeconds.toInt()
            : 1,
      ),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      width: _toInt(map['width']),
      height: _toInt(map['height']),
    );
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'title': title,
    'author': author,
    'durationSeconds': duration.inSeconds,
    'thumbnailUrl': thumbnailUrl,
    'width': width,
    'height': height,
  };

  static int? _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [
        url,
        title,
        author,
        duration,
        thumbnailUrl,
        width,
        height,
      ];
}
