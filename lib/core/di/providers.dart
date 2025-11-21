import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/data/datasources/downloader_platform_channel.dart';
import 'package:insta_reel_downloader/data/datasources/upscaler_platform_channel.dart';
import 'package:insta_reel_downloader/data/repositories/download_repository_impl.dart';
import 'package:insta_reel_downloader/domain/repositories/download_repository.dart';
import 'package:insta_reel_downloader/domain/services/downloader_service.dart';
import 'package:insta_reel_downloader/domain/services/upscaler_service.dart';

final downloaderServiceProvider = Provider<DownloaderService>((ref) {
  final service = DownloaderChannelService();
  ref.onDispose(service.dispose);
  return service;
});

final upscalerServiceProvider = Provider<UpscalerService>((ref) {
  final service = UpscalerChannelService();
  ref.onDispose(service.dispose);
  return service;
});

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final repository = DownloadRepositoryImpl(
    downloaderService: ref.watch(downloaderServiceProvider),
    upscalerService: ref.watch(upscalerServiceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
