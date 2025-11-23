import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/data/datasources/permission_service.dart';
import 'package:insta_reel_downloader/presentation/downloads/downloads_view.dart';
import 'package:insta_reel_downloader/presentation/home/home_view.dart';
import 'package:insta_reel_downloader/presentation/settings/settings_view.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _permissionService = PermissionService();
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    // Request storage permission (includes media permissions)
    final storageGranted = await _permissionService.requestStoragePermission();
    
    // For Android 15+, also explicitly request MANAGE_EXTERNAL_STORAGE
    // This is needed for FFmpeg to access and write files
    final manageStorageGranted = await _permissionService.requestManageExternalStoragePermission();
    
    // Request audio permission for FFmpeg operations
    await _permissionService.requestAudioPermission();
    
    if ((!storageGranted || !manageStorageGranted) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Storage and file access permissions are required to download videos. '
            'You can grant them in Settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              _permissionService.openSettings();
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  static final _destinations = <_NavDestination>[
    const _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      child: HomeView(),
    ),
    const _NavDestination(
      label: 'Downloads',
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
      child: DownloadsView(),
    ),
    const _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      child: SettingsView(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final destination = _destinations[selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () =>
                ref.read(navigationIndexProvider.notifier).state = 1,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: _destinations.map((e) => e.child).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: _destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
            )
            .toList(),
        onDestinationSelected: (value) =>
            ref.read(navigationIndexProvider.notifier).state = value,
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}
