import 'package:equatable/equatable.dart';

class UrlValidationResult extends Equatable {
  const UrlValidationResult({
    required this.originalUrl,
    required this.isValid,
    this.normalizedUrl,
    this.reason,
  });

  final String originalUrl;
  final bool isValid;
  final String? normalizedUrl;
  final String? reason;

  factory UrlValidationResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const UrlValidationResult(originalUrl: '', isValid: false);
    }
    return UrlValidationResult(
      originalUrl: map['originalUrl']?.toString() ?? '',
      isValid: map['isValid'] == true,
      normalizedUrl: map['normalizedUrl']?.toString(),
      reason: map['reason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'originalUrl': originalUrl,
        'isValid': isValid,
        'normalizedUrl': normalizedUrl,
        'reason': reason,
      };

  @override
  List<Object?> get props => [originalUrl, isValid, normalizedUrl, reason];
}
