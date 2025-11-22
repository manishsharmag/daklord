import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/data/providers/settings_providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsOptIn = ref.watch(analyticsOptInProvider);
    final autoUpscale = ref.watch(autoUpscaleProvider);
    final scaleFactor = ref.watch(upscaleScaleFactorProvider);
    final autoSaveHistory = ref.watch(autoSaveHistoryProvider);
    final privacyMode = ref.watch(privacyModeProvider);
    final downloadsFolderOption = ref.watch(downloadsFolderOptionProvider);
    final downloadsFolderPath = ref.watch(downloadsFolderPathProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile.adaptive(
            title: const Text('Enable AI upscaling preview'),
            subtitle: const Text(
              'Experimental — routes tasks to the upscaler service when available.',
            ),
            value: autoUpscale,
            onChanged: (value) =>
                ref.read(autoUpscaleProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Upscaling scale factor'),
                subtitle: Text('${scaleFactor}x resolution enhancement'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('2x'),
                    Expanded(
                      child: Slider(
                        value: scaleFactor.toDouble(),
                        min: 2,
                        max: 4,
                        divisions: 1,
                        label: '${scaleFactor}x',
                        onChanged: (value) {
                          ref.read(upscaleScaleFactorProvider.notifier).state =
                              value.toInt();
                        },
                      ),
                    ),
                    const Text('4x'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Higher scale factors produce better quality but take longer to process.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile.adaptive(
            title: const Text('Share anonymous diagnostics'),
            subtitle: const Text(
              'Helps us tune downloader performance across devices.',
            ),
            value: analyticsOptIn,
            onChanged: (value) =>
                ref.read(analyticsOptInProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile.adaptive(
            title: const Text('Auto-save download history'),
            subtitle: const Text(
              'Automatically save downloaded reels to history database.',
            ),
            value: autoSaveHistory,
            onChanged: (value) =>
                ref.read(autoSaveHistoryProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile.adaptive(
            title: const Text('Privacy mode'),
            subtitle: const Text(
              'Disable history tracking and auto-save. No URLs stored.',
            ),
            value: privacyMode,
            onChanged: (value) {
              ref.read(privacyModeProvider.notifier).state = value;
              if (value) {
                ref.read(autoSaveHistoryProvider.notifier).state = false;
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Downloads Folder',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            downloadsFolderPath,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: downloadsFolderPath));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Path copied to clipboard')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Downloads folder directly'),
                      subtitle: const Text('/storage/emulated/0/Downloads/'),
                      value: 'downloads_root',
                      groupValue: downloadsFolderOption,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(downloadsFolderOptionProvider.notifier).state = value;
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Instagram Reels subfolder'),
                      subtitle: const Text('/storage/emulated/0/Downloads/instagram-reels/'),
                      value: 'downloads_instagram_reels',
                      groupValue: downloadsFolderOption,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(downloadsFolderOptionProvider.notifier).state = value;
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.safety_check),
            title: const Text('Permissions checklist'),
            subtitle: const Text(
              'Storage, network, and share sheet permissions configured.',
            ),
          ),
        ),
      ],
    );
  }
}
