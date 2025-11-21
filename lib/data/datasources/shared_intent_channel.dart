import 'package:flutter/services.dart';

import '../../core/constants/channel_names.dart';

class SharedIntentHandler {
  SharedIntentHandler({
    MethodChannel? methodChannel,
  }) : _channel = methodChannel ?? const MethodChannel(ChannelNames.sharedIntent);

  final MethodChannel _channel;

  Future<String?> getSharedUrl() async {
    try {
      final url = await _channel.invokeMethod<String>('getSharedUrl');
      return url;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> clearSharedUrl() async {
    try {
      await _channel.invokeMethod('clearSharedUrl');
    } catch (_) {
      // Ignore errors
    }
  }
}
