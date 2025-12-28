import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/essays/presentation/pages/essays_list_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'What would you like to work on?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionCard(
                    context,
                    icon: Icons.article_outlined,
                    title: 'Essays',
                    subtitle: 'Short-form writing\nDrafts & archives',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EssaysListPage()),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildOptionCard(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Projects',
                    subtitle: 'Long-form writing\nBooks & series',
                    color: Theme.of(context).colorScheme.tertiary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Projects coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    comingSoon: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool comingSoon = false,
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
              color: comingSoon
                  ? Theme.of(context).dividerColor.withOpacity(0.2)
                  : Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Opacity(
            opacity: comingSoon ? 0.5 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (comingSoon) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
