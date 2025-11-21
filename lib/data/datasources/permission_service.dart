import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // For non-Android platforms, return true
      return true;
    }

    // For Android, try to request storage permission
    // The permission_handler package will handle API level differences automatically
    try {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      
      // Try requesting storage permission
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      }
      
      // For Android 11+, we may need MANAGE_EXTERNAL_STORAGE for full access
      // But for Documents folder, storage permission should suffice
      if (result.isPermanentlyDenied) {
        // Permission permanently denied, user needs to go to settings
        return false;
      }
      
      return result.isGranted;
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
      return await Permission.storage.isGranted;
    } catch (e) {
      return true;
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
