import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/essays/data/essay_repository.dart';
import 'package:abbey/features/essays/domain/models/essay.dart';

/// Dialog to create a new essay or append to existing one from selected text
class TextToEssayDialog extends ConsumerStatefulWidget {
  final String selectedText;

  const TextToEssayDialog({super.key, required this.selectedText});

  @override
  ConsumerState<TextToEssayDialog> createState() => _TextToEssayDialogState();
}

class _TextToEssayDialogState extends ConsumerState<TextToEssayDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  String? _selectedEssayId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final essaysAsync = ref.watch(essayRepositoryProvider);

    return AlertDialog(
      title: const Text('Use Selected Text'),
      content: SizedBox(
        width: 400,
        height: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview of selected text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 80),
              child: SingleChildScrollView(
                child: Text(
                  widget.selectedText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'New Essay'),
                Tab(text: 'Append to Existing'),
              ],
            ),
            const SizedBox(height: 16),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // New Essay tab
                  Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Essay Title',
                          hintText: 'Press Enter for date/time title',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onSubmitted: (_) => _handleSubmit(context),
                      ),
                    ],
                  ),
                  // Append to existing tab
                  essaysAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (essays) {
                      final drafts = essays
                          .where((e) => e.status == EssayStatus.draft)
                          .toList();
                      if (drafts.isEmpty) {
                        return const Center(
                          child: Text('No essays yet. Create one first!'),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: drafts.length,
                        itemBuilder: (context, index) {
                          final essay = drafts[index];
                          return RadioListTile<String>(
                            title: Text(essay.title),
                            subtitle: Text(
                              '${essay.content.length} characters',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            value: essay.id,
                            groupValue: _selectedEssayId,
                            onChanged: (value) {
                              setState(() {
                                _selectedEssayId = value;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _handleSubmit(context),
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final essayRepo = ref.read(essayRepositoryProvider.notifier);

    if (_tabController.index == 0) {
      // Create new essay
      var title = _titleController.text.trim();
      if (title.isEmpty) {
        title = _generateDefaultTitle();
      }
      await essayRepo.createEssay(title: title, content: widget.selectedText);
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Created essay: $title')));
      }
    } else {
      // Append to existing essay
      if (_selectedEssayId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select an essay')));
        return;
      }
      final essay = await essayRepo.getEssay(_selectedEssayId!);
      if (essay != null) {
        final newContent = essay.content.isEmpty
            ? widget.selectedText
            : '${essay.content}\n\n${widget.selectedText}';
        await essayRepo.updateEssay(essay.copyWith(content: newContent));
        if (context.mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Added to: ${essay.title}')));
        }
      }
    }
  }
}

/// Shows the text to essay dialog
Future<bool?> showTextToEssayDialog(BuildContext context, String selectedText) {
  return showDialog<bool>(
    context: context,
    builder: (context) => TextToEssayDialog(selectedText: selectedText),
  );
}
