import 'package:flutter/services.dart';

import '../../core/constants/channel_names.dart';
import '../../domain/services/upscaler_service.dart';

class UpscalerChannelService implements UpscalerService {
  UpscalerChannelService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(ChannelNames.upscaler);

  final MethodChannel _channel;

  @override
  Future<void> upscaleVideo(String taskId) async {
    try {
      await _channel.invokeMethod('upscaleVideo', {'taskId': taskId});
    } on PlatformException {
      // Native implementation pending. No-op keeps the UI responsive.
    } on MissingPluginException {
      // Native implementation pending. No-op keeps the UI responsive.
    }
  }

  @override
  void dispose() {}
}
