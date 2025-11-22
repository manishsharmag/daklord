import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // For non-Android platforms, return true
      return true;
    }

    try {
      // For Android 13+ (API 33+), request READ_MEDIA_* permissions
      final permissions = <Permission>[
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ];
      
      final statuses = await permissions.request();
      
      // Check if at least one permission is granted
      final anyGranted = statuses.values.any((status) => status.isGranted);
      if (anyGranted) {
        return true;
      }
      
      // If permanently denied, user needs to go to settings
      return statuses.values.every((status) => !status.isPermanentlyDenied);
    } catch (e) {
      // If permission request fails, assume we have permission
      // (API might not be available on this Android version)
      return true;
    }
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    try {
      // Check if storage permission is granted
      final status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
