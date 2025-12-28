import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/essays/data/essay_repository.dart';
import 'package:abbey/features/essays/domain/models/essay.dart';

enum EditorViewMode { edit, preview, split }

class EssayEditorPage extends ConsumerStatefulWidget {
  final String essayId;
  final bool embedded;
  final VoidCallback? onToggleSidebar;
  final bool sidebarCollapsed;

  const EssayEditorPage({
    super.key,
    required this.essayId,
    this.embedded = false,
    this.onToggleSidebar,
    this.sidebarCollapsed = false,
  });

  @override
  ConsumerState<EssayEditorPage> createState() => _EssayEditorPageState();
}

class _EssayEditorPageState extends ConsumerState<EssayEditorPage> {
  late TextEditingController _textController;
  Essay? _essay;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  int _wordCount = 0;
  EditorViewMode _viewMode = EditorViewMode.edit;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _loadEssay();
  }

  @override
  void didUpdateWidget(covariant EssayEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if essayId changed
    if (oldWidget.essayId != widget.essayId) {
      setState(() {
        _isLoading = true;
        _hasUnsavedChanges = false;
      });
      _loadEssay();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Save any pending changes before disposing
    if (_hasUnsavedChanges && _essay != null) {
      _saveEssay();
    }
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadEssay() async {
    final essay = await ref
        .read(essayRepositoryProvider.notifier)
        .getEssay(widget.essayId);
    if (mounted && essay != null) {
      setState(() {
        _essay = essay;
        _textController.text = essay.content;
        _wordCount = _calculateWordCount(essay.content);
        _isLoading = false;
      });
    }
  }

  int _calculateWordCount(String text) {
    if (text.isEmpty) return 0;
    return RegExp(r'\w+').allMatches(text).length;
  }

  void _onTextChanged(String value) {
    setState(() {
      _hasUnsavedChanges = true;
      _wordCount = _calculateWordCount(value);
    });

    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveEssay();
    });
  }

  /// Parse inline formatting (bold, italic) and return a TextSpan
  TextSpan _parseInlineFormatting(String text, TextStyle? baseStyle) {
    final List<InlineSpan> spans = [];

    // Regex to match **bold**, *italic*, or ***bold italic***
    final pattern = RegExp(r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*)');

    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      // Check which group matched
      if (match.group(2) != null) {
        // ***bold italic***
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // **bold**
        spans.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(4) != null) {
        // *italic*
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    // If no matches were found, return the whole text
    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    return TextSpan(children: spans);
  }

  /// Build styled preview from markdown-like content
  Widget _buildPreview(BuildContext context, String content) {
    final lines = content.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      if (line.startsWith('### ')) {
        final textContent = line.replaceFirst('### ', '');
        final style = Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text.rich(_parseInlineFormatting(textContent, style)),
          ),
        );
      } else if (line.startsWith('## ')) {
        final textContent = line.replaceFirst('## ', '');
        final style = Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Text.rich(_parseInlineFormatting(textContent, style)),
          ),
        );
      } else if (line.startsWith('# ')) {
        final textContent = line.replaceFirst('# ', '');
        final style = Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text.rich(_parseInlineFormatting(textContent, style)),
          ),
        );
      } else if (line.startsWith('> ')) {
        // Blockquote
        final textContent = line.replaceFirst('> ', '');
        final style = Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic);
        children.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text.rich(_parseInlineFormatting(textContent, style)),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        // Bullet list item
        final textContent = line.substring(2);
        final style = Theme.of(context).textTheme.bodyLarge;
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: style),
                Expanded(
                  child: Text.rich(_parseInlineFormatting(textContent, style)),
                ),
              ],
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
      } else {
        // Regular paragraph
        final style = Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.6);
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(_parseInlineFormatting(line, style)),
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _saveEssay() async {
    if (_essay == null || !_hasUnsavedChanges) return;

    final updated = _essay!.copyWith(
      content: _textController.text,
      updatedAt: DateTime.now(),
    );

    await ref.read(essayRepositoryProvider.notifier).updateEssay(updated);

    if (mounted) {
      setState(() {
        _essay = updated;
        _hasUnsavedChanges = false;
      });
    }
  }

  void _showRenameDialog() {
    if (_essay == null) return;

    final controller = TextEditingController(text: _essay!.title);

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
                    .renameEssay(_essay!.id, controller.text.trim());
                // Reload the essay to get updated title
                await _loadEssay();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.embedded) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_essay == null) {
      if (widget.embedded) {
        return const Center(child: Text('Essay not found'));
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Essay not found')),
      );
    }

    // Editor widget
    Widget editorWidget = Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing...',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: _onTextChanged,
      ),
    );

    // Preview widget
    Widget previewWidget = _buildPreview(context, _textController.text);

    // Build content based on view mode
    Widget mainContent;
    switch (_viewMode) {
      case EditorViewMode.edit:
        mainContent = editorWidget;
        break;
      case EditorViewMode.preview:
        mainContent = previewWidget;
        break;
      case EditorViewMode.split:
        mainContent = Row(
          children: [
            Expanded(child: editorWidget),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            Expanded(child: previewWidget),
          ],
        );
        break;
    }

    final content = Stack(
      children: [
        mainContent,
        // Word count overlay
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '$_wordCount words',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );

    // Build app bar actions
    final actions = <Widget>[
      // View mode toggle
      SegmentedButton<EditorViewMode>(
        segments: const [
          ButtonSegment(
            value: EditorViewMode.edit,
            icon: Icon(Icons.edit_note, size: 18),
            tooltip: 'Edit',
          ),
          ButtonSegment(
            value: EditorViewMode.split,
            icon: Icon(Icons.vertical_split, size: 18),
            tooltip: 'Split',
          ),
          ButtonSegment(
            value: EditorViewMode.preview,
            icon: Icon(Icons.visibility, size: 18),
            tooltip: 'Preview',
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (selection) {
          setState(() {
            _viewMode = selection.first;
          });
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      const SizedBox(width: 8),
      if (_hasUnsavedChanges)
        TextButton.icon(
          onPressed: _saveEssay,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Save'),
        )
      else
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.cloud_done, size: 18, color: Colors.green),
        ),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
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
            value: _essay!.status == EssayStatus.draft
                ? 'archive'
                : 'unarchive',
            child: Row(
              children: [
                Icon(
                  _essay!.status == EssayStatus.draft
                      ? Icons.archive
                      : Icons.unarchive,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _essay!.status == EssayStatus.draft
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
    ];

    // Embedded mode - no scaffold, just content with a simple header
    if (widget.embedded) {
      return Column(
        children: [
          // Simple header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                // Toggle sidebar button
                IconButton(
                  icon: Icon(
                    widget.sidebarCollapsed ? Icons.menu : Icons.menu_open,
                  ),
                  onPressed: widget.onToggleSidebar,
                  tooltip: widget.sidebarCollapsed
                      ? 'Show sidebar'
                      : 'Hide sidebar',
                ),
                const SizedBox(width: 8),
                // Title (tappable to rename)
                Expanded(
                  child: GestureDetector(
                    onTap: _showRenameDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _essay!.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    // Standalone mode - full scaffold
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(_essay!.title, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        actions: actions,
      ),
      body: content,
    );
  }

  void _handleMenuAction(String action) async {
    final repo = ref.read(essayRepositoryProvider.notifier);

    switch (action) {
      case 'rename':
        _showRenameDialog();
        break;
      case 'archive':
        await repo.archiveEssay(_essay!.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${_essay!.title} archived')));
          // Only pop if not embedded
          if (!widget.embedded) {
            Navigator.pop(context);
          }
        }
        break;
      case 'unarchive':
        await repo.unarchiveEssay(_essay!.id);
        await _loadEssay();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_essay!.title} moved to drafts')),
          );
        }
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Essay?'),
        content: Text(
          'Are you sure you want to delete "${_essay!.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(essayRepositoryProvider.notifier)
                  .deleteEssay(_essay!.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                // Only pop again if not embedded
                if (!widget.embedded) {
                  Navigator.pop(context); // Go back to list
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_essay!.title} deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
