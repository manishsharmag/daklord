import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/upscale_status.dart';
import '../../domain/entities/upscale_task.dart';
import '../../domain/services/upscaler_service.dart';

class UpscaleControllerState {
  const UpscaleControllerState({
    this.activeTasks = const [],
    this.isLoading = false,
  });

  final List<UpscaleTask> activeTasks;
  final bool isLoading;

  UpscaleControllerState copyWith({
    List<UpscaleTask>? activeTasks,
    bool? isLoading,
  }) {
    return UpscaleControllerState(
      activeTasks: activeTasks ?? this.activeTasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UpscaleController extends StateNotifier<UpscaleControllerState> {
  UpscaleController(this._upscalerService)
      : super(const UpscaleControllerState()) {
    _progressSubscription = _upscalerService.progressStream.listen((event) {
      try {
        final task = UpscaleTask.fromMap(event);
        _updateTask(task);
      } catch (_) {}
    });
  }

  final UpscalerService _upscalerService;
  StreamSubscription<Map<String, dynamic>>? _progressSubscription;

  Future<void> upscaleVideo({
    required String videoPath,
    required int scaleFactor,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final taskMap = await _upscalerService.upscaleVideo(
        videoPath: videoPath,
        scaleFactor: scaleFactor,
      );
      final task = UpscaleTask.fromMap(taskMap);
      _updateTask(task);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> cancelTask(String taskId) async {
    try {
      await _upscalerService.cancelUpscale(taskId);
      state = state.copyWith(
        activeTasks: state.activeTasks
            .where((task) => task.id != taskId)
            .toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _updateTask(UpscaleTask updatedTask) {
    final tasks = [...state.activeTasks];
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);

    if (updatedTask.status == UpscaleStatus.completed ||
        updatedTask.status == UpscaleStatus.failed) {
      if (index >= 0) {
        tasks.removeAt(index);
      }
    } else {
      if (index >= 0) {
        tasks[index] = updatedTask;
      } else {
        tasks.add(updatedTask);
      }
    }

    state = state.copyWith(activeTasks: tasks);
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _upscalerService.dispose();
    super.dispose();
  }
}

final upscaleControllerProvider =
    StateNotifierProvider<UpscaleController, UpscaleControllerState>((ref) {
  return UpscaleController(ref.watch(upscalerServiceProvider));
});
