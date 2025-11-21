import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/constants/channel_names.dart';
import '../../domain/services/upscaler_service.dart';

class UpscalerChannelService implements UpscalerService {
  UpscalerChannelService({
    MethodChannel? channel,
    EventChannel? eventChannel,
  })  : _channel = channel ?? const MethodChannel(ChannelNames.upscaler),
        _eventChannel =
            eventChannel ?? const EventChannel(ChannelNames.upscalerEvents) {
    _progressController = StreamController<Map<String, dynamic>>.broadcast();
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        _progressController.add(Map<String, dynamic>.from(event));
      }
    });
  }

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  late final StreamController<Map<String, dynamic>> _progressController;

  @override
  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;

  @override
  Future<Map<String, dynamic>> upscaleVideo({
    required String videoPath,
    required int scaleFactor,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'upscaleVideo',
        {
          'videoPath': videoPath,
          'scaleFactor': scaleFactor,
        },
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw Exception('Upscaling failed: ${e.message}');
    }
  }

  @override
  Future<void> cancelUpscale(String taskId) async {
    try {
      await _channel.invokeMethod('cancelUpscale', {'taskId': taskId});
    } on PlatformException catch (e) {
      throw Exception('Cancel failed: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveTasks() async {
    try {
      final result = await _channel.invokeMethod<List>('getActiveTasks');
      return result
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    } on PlatformException {
      return [];
    }
  }

  @override
  void dispose() {
    _progressController.close();
  }
}
