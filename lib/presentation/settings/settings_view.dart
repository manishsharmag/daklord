import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsOptInProvider = StateProvider<bool>((ref) => true);
final autoUpscaleProvider = StateProvider<bool>((ref) => false);
final upscaleScaleFactorProvider = StateProvider<int>((ref) => 2);

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsOptIn = ref.watch(analyticsOptInProvider);
    final autoUpscale = ref.watch(autoUpscaleProvider);
    final scaleFactor = ref.watch(upscaleScaleFactorProvider);

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
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Scoped storage directory'),
            subtitle: const Text('Android/media/com.insta.reel/Downloads'),
            trailing: FilledButton.tonalIcon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy path'),
              onPressed: () async {
                const path = 'Android/media/com.insta.reel/Downloads';
                await Clipboard.setData(const ClipboardData(text: path));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Path copied to clipboard')),
                  );
                }
              },
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
