import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/core/theme/app_theme.dart';
import 'package:insta_reel_downloader/presentation/shell/app_shell.dart';

class InstaReelDownloaderApp extends ConsumerWidget {
  const InstaReelDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insta Reel Downloader',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
