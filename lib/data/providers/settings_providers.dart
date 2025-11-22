import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsOptInProvider = StateProvider<bool>((ref) => true);
final autoUpscaleProvider = StateProvider<bool>((ref) => false);
final upscaleScaleFactorProvider = StateProvider<int>((ref) => 2);
final autoSaveHistoryProvider = StateProvider<bool>((ref) => true);
final privacyModeProvider = StateProvider<bool>((ref) => false);

// Downloads folder selection
// Option: 'downloads_root' or 'downloads_instagram_reels'
final downloadsFolderOptionProvider = StateProvider<String>((ref) => 'downloads_instagram_reels');

// Full path to the downloads folder
final downloadsFolderPathProvider = StateProvider<String>((ref) {
  const defaultPath = '/storage/emulated/0/Downloads/instagram-reels/';
  final option = ref.watch(downloadsFolderOptionProvider);
  
  if (option == 'downloads_root') {
    return '/storage/emulated/0/Downloads/';
  }
  return defaultPath;
});
