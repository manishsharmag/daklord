import 'package:flutter/services.dart';

class FolderPickerService {
  static const platform = MethodChannel('com.example.insta_reel_downloader/folder_picker');

  /// Opens a native folder picker and returns the selected directory path
  static Future<String?> selectFolder() async {
    try {
      final String? result = await platform.invokeMethod<String>('selectFolder');
      return result;
    } on PlatformException catch (e) {
      print('Failed to select folder: ${e.message}');
      return null;
    }
  }
}
