import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsOptInProvider = StateProvider<bool>((ref) => true);
final autoUpscaleProvider = StateProvider<bool>((ref) => false);
final upscaleScaleFactorProvider = StateProvider<int>((ref) => 2);
final autoSaveHistoryProvider = StateProvider<bool>((ref) => true);
final privacyModeProvider = StateProvider<bool>((ref) => false);
