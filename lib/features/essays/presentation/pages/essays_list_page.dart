import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/essays/data/essay_repository.dart';
import 'package:abbey/features/essays/domain/models/essay.dart';
import 'essay_editor_page.dart';

/// Sidebar filter for essays
enum EssayFilter { drafts, archive }

class EssaysListPage extends ConsumerStatefulWidget {
  const EssaysListPage({super.key});

  @override
  ConsumerState<EssaysListPage> createState() => _EssaysListPageState();
}

class _EssaysListPageState extends ConsumerState<EssaysListPage> {
  EssayFilter _currentFilter = EssayFilter.drafts;
  String? _selectedEssayId;
  bool _sidebarCollapsed = false;

  static const double _sidebarWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final essaysAsync = ref.watch(essayRepositoryProvider);

    return Scaffold(
      body: essaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (essays) {
          final drafts = essays
              .where((e) => e.status == EssayStatus.draft)
              .toList();
          final archived = essays
              .where((e) => e.status == EssayStatus.archived)
              .toList();
          final currentList = _currentFilter == EssayFilter.drafts
              ? drafts
              : archived;

          // Clear selection if the selected essay no longer exists
          if (_selectedEssayId != null &&
              !essays.any((e) => e.id == _selectedEssayId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedEssayId = null;
                });
              }
            });
          }

          return Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _sidebarCollapsed ? 0 : _sidebarWidth,
                child: _sidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildSidebar(drafts, archived, currentList),
              ),
              // Divider
              if (!_sidebarCollapsed)
                const VerticalDivider(width: 1, thickness: 1),
              // Main content area
              Expanded(
                child:
                    _selectedEssayId != null &&
                        essays.any((e) => e.id == _selectedEssayId)
                    ? _buildEditorArea()
                    : _buildEmptyState(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(
    List<Essay> drafts,
    List<Essay> archived,
    List<Essay> currentList,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 8),
                Text('Essays', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _createNewEssay(context),
                  tooltip: 'New Essay',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: 'Drafts',
                    count: drafts.length,
                    icon: Icons.edit_note,
                    isSelected: _currentFilter == EssayFilter.drafts,
                    onTap: () =>
                        setState(() => _currentFilter = EssayFilter.drafts),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    label: 'Archive',
                    count: archived.length,
                    icon: Icons.archive,
                    isSelected: _currentFilter == EssayFilter.archive,
                    onTap: () =>
                        setState(() => _currentFilter = EssayFilter.archive),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Essay list
          Expanded(
            child: currentList.isEmpty
                ? _buildEmptyListMessage()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final essay = currentList[index];
                      return _buildEssayTile(essay);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEssayTile(Essay essay) {
    final isSelected = essay.id == _selectedEssayId;
    final wordCount = essay.content.isEmpty
        ? 0
        : RegExp(r'\w+').allMatches(essay.content).length;

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedEssayId = essay.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      essay.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$wordCount words • ${_formatDate(essay.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) => _handleMenuAction(value, essay),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: essay.status == EssayStatus.draft
                        ? 'archive'
                        : 'unarchive',
                    child: Row(
                      children: [
                        Icon(
                          essay.status == EssayStatus.draft
                              ? Icons.archive
                              : Icons.unarchive,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          essay.status == EssayStatus.draft
                              ? 'Archive'
                              : 'Move to Drafts',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyListMessage() {
    final isDrafts = _currentFilter == EssayFilter.drafts;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDrafts ? Icons.edit_note : Icons.archive,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isDrafts ? 'No drafts' : 'No archived',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorArea() {
    return Stack(
      children: [
        EssayEditorPage(
          essayId: _selectedEssayId!,
          embedded: true,
          onToggleSidebar: () =>
              setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          sidebarCollapsed: _sidebarCollapsed,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an essay to edit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Or create a new one from the sidebar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _createNewEssay(context),
            icon: const Icon(Icons.add),
            label: const Text('New Essay'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m';
      }
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _handleMenuAction(String action, Essay essay) async {
    final repo = ref.read(essayRepositoryProvider.notifier);

    switch (action) {
      case 'rename':
        _showRenameDialog(essay);
        break;
      case 'archive':
        await repo.archiveEssay(essay.id);
        if (_selectedEssayId == essay.id) {
          setState(() => _selectedEssayId = null);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${essay.title} archived')));
        }
        break;
      case 'unarchive':
        await repo.unarchiveEssay(essay.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${essay.title} moved to drafts')),
          );
        }
        break;
      case 'delete':
        _showDeleteDialog(essay);
        break;
    }
  }

  void _showRenameDialog(Essay essay) {
    final controller = TextEditingController(text: essay.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Essay'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(essayRepositoryProvider.notifier)
                    .renameEssay(essay.id, controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Essay renamed')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Essay essay) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Essay?'),
        content: Text(
          'Are you sure you want to delete "${essay.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_selectedEssayId == essay.id) {
                setState(() => _selectedEssayId = null);
              }
              await ref
                  .read(essayRepositoryProvider.notifier)
                  .deleteEssay(essay.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${essay.title} deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewEssay(BuildContext context) async {
    // Create with timestamp, no dialog needed
    final now = DateTime.now();
    final title =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      final essay = await ref
          .read(essayRepositoryProvider.notifier)
          .createEssay(title: title);

      if (mounted) {
        setState(() => _selectedEssayId = essay.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating essay: $e')));
      }
    }
  }
}
