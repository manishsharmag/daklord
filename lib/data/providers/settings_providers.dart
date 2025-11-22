import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final analyticsOptInProvider = StateProvider<bool>((ref) => true);
final autoUpscaleProvider = StateProvider<bool>((ref) => false);
final upscaleScaleFactorProvider = StateProvider<int>((ref) => 2);
final autoSaveHistoryProvider = StateProvider<bool>((ref) => true);
final privacyModeProvider = StateProvider<bool>((ref) => false);

// Downloads folder selection
// Option: 'downloads_root', 'downloads_instagram_reels', or 'custom'
final downloadsFolderOptionProvider = StateProvider<String>((ref) => 'downloads_instagram_reels');

// Load custom downloads folder path from SharedPreferences
final customDownloadsFolderPathAsyncProvider = FutureProvider<String>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_downloads_path') ?? '/storage/emulated/0/Downloads/';
  } catch (_) {
    return '/storage/emulated/0/Downloads/';
  }
});

// Store custom downloads folder path
Future<void> saveCustomDownloadsPath(String path) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_downloads_path', path);
  } catch (_) {
    // Ignore save errors
  }
}

// Full path to the downloads folder
final downloadsFolderPathProvider = Provider<String>((ref) {
  const defaultPath = '/storage/emulated/0/Downloads/instagram-reels/';
  final option = ref.watch(downloadsFolderOptionProvider);
  
  if (option == 'downloads_root') {
    return '/storage/emulated/0/Downloads/';
  } else if (option == 'custom') {
    // Return a placeholder, actual path is retrieved via async provider
    return '/storage/emulated/0/Downloads/';
  }
  return defaultPath;
});

// Get the actual downloads folder path considering all options
final resolvedDownloadsFolderPathProvider = FutureProvider<String>((ref) async {
  final option = ref.watch(downloadsFolderOptionProvider);
  
  if (option == 'downloads_root') {
    return '/storage/emulated/0/Downloads/';
  } else if (option == 'custom') {
    return ref.watch(customDownloadsFolderPathAsyncProvider).when(
      data: (path) => path,
      loading: () => '/storage/emulated/0/Downloads/',
      error: (_, __) => '/storage/emulated/0/Downloads/',
    );
  }
  
  return '/storage/emulated/0/Downloads/instagram-reels/';
});
