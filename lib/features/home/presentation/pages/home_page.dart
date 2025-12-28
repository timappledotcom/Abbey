import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/editor/presentation/pages/editor_page.dart';
import 'package:abbey/features/editor/presentation/pages/flow_reader_page.dart';
import 'package:abbey/features/library/presentation/pages/library_page.dart';
import 'package:abbey/features/settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App title
              Text(
                'Abbey',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"One word is worth a thousand pictures."',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 64),
              // Mode selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeCard(
                    context,
                    icon: Icons.waves,
                    title: 'Flow',
                    subtitle: 'Freeform writing\nLet thoughts flow',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => _showFlowOptionsDialog(context, ref),
                  ),
                  const SizedBox(width: 24),
                  _buildModeCard(
                    context,
                    icon: Icons.auto_stories,
                    title: 'Library',
                    subtitle: 'Essays & Projects\nOrganized writing',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LibraryPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Settings link
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Settings'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlowOptionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start Flow Session'),
              subtitle: const Text('Begin a timed writing sprint'),
              onTap: () {
                Navigator.pop(context);
                _showFlowTimerDialog(context, ref);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Flow Journal'),
              subtitle: const Text('Read your past flow sessions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlowReaderPage(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFlowTimerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Duration'),
        content: const Text(
          'Select how long you want to write. Your session will be saved to your Flow Journal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startFlowAndNavigate(
                    context,
                    ref,
                    const Duration(minutes: 5),
                  );
                },
                child: const Text('5 Min'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startFlowAndNavigate(
                    context,
                    ref,
                    const Duration(minutes: 10),
                  );
                },
                child: const Text('10 Min'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startFlowAndNavigate(
                    context,
                    ref,
                    const Duration(minutes: 15),
                  );
                },
                child: const Text('15 Min'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startFlowAndNavigate(
                    context,
                    ref,
                    const Duration(minutes: 30),
                  );
                },
                child: const Text('30 Min'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startFlowAndNavigate(
    BuildContext context,
    WidgetRef ref,
    Duration duration,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorPage(startFlowDuration: duration),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
