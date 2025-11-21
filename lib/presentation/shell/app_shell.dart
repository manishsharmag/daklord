import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/presentation/downloads/downloads_view.dart';
import 'package:insta_reel_downloader/presentation/home/home_view.dart';
import 'package:insta_reel_downloader/presentation/settings/settings_view.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
