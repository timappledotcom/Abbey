import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/flow_repository.dart';
import '../widgets/text_to_essay_dialog.dart';

enum FlowSortOrder { newestFirst, oldestFirst }

class FlowReaderPage extends ConsumerStatefulWidget {
  const FlowReaderPage({super.key});

  @override
  ConsumerState<FlowReaderPage> createState() => _FlowReaderPageState();
}

class _FlowReaderPageState extends ConsumerState<FlowReaderPage> {
  FlowSortOrder _sortOrder = FlowSortOrder.newestFirst;
  String _currentPlainText = '';
  TextSelection _currentSelection = const TextSelection.collapsed(offset: 0);
  final ValueNotifier<bool> _hasSelection = ValueNotifier(false);

  String _reorderContent(String content) {
    if (_sortOrder == FlowSortOrder.oldestFirst) {
      return content;
    }

    // Split content by session headers and reverse
    final sessions = <String>[];
    final lines = content.split('\n');
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('### Session:') && buffer.isNotEmpty) {
        sessions.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
    }

    // Add the last session
    if (buffer.isNotEmpty) {
      sessions.add(buffer.toString().trim());
    }

    // Reverse to show newest first
    return sessions.reversed.join('\n\n');
  }

  /// Build styled TextSpan from content with basic markdown-like formatting
  /// Also returns the plain text version that matches the rendered text
  (TextSpan, String) _buildStyledContent(BuildContext context, String content) {
    final List<InlineSpan> spans = [];
    final StringBuffer plainTextBuffer = StringBuffer();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('### Session:')) {
        // Session header - styled differently
        final displayText = '${line.replaceFirst('### ', '')}\n';
        spans.add(
          TextSpan(
            text: displayText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        plainTextBuffer.write(displayText);
      } else if (line.startsWith('# ')) {
        final displayText = '${line.replaceFirst('# ', '')}\n';
        spans.add(
          TextSpan(
            text: displayText,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        );
        plainTextBuffer.write(displayText);
      } else if (line.startsWith('## ')) {
        final displayText = '${line.replaceFirst('## ', '')}\n';
        spans.add(
          TextSpan(
            text: displayText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        );
        plainTextBuffer.write(displayText);
      } else {
        // Regular text
        final displayText = '$line\n';
        spans.add(
          TextSpan(
            text: displayText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
        plainTextBuffer.write(displayText);
      }
    }

    return (TextSpan(children: spans), plainTextBuffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Journal'),
        actions: [
          PopupMenuButton<FlowSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Order',
            onSelected: (order) {
              setState(() {
                _sortOrder = order;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FlowSortOrder.newestFirst,
                child: Row(
                  children: [
                    if (_sortOrder == FlowSortOrder.newestFirst)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Text('Newest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FlowSortOrder.oldestFirst,
                child: Row(
                  children: [
                    if (_sortOrder == FlowSortOrder.oldestFirst)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Text('Oldest First'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: ref.read(flowRepositoryProvider).getOrCreateFlowEssay(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final essay = snapshot.data;
          if (essay == null || essay.content.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.waves,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Flow sessions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a Flow session to begin your journal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          final displayContent = _reorderContent(essay.content);
          final (styledContent, plainText) = _buildStyledContent(
            context,
            displayContent,
          );
          _currentPlainText = plainText;

          return Stack(
            children: [
              // Use SelectableText.rich for proper selection with styling
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText.rich(
                  styledContent,
                  contextMenuBuilder: (context, editableTextState) {
                    final selection =
                        editableTextState.textEditingValue.selection;
                    final hasValidSelection = !selection.isCollapsed;

                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: [
                        ...editableTextState.contextMenuButtonItems,
                        if (hasValidSelection)
                          ContextMenuButtonItem(
                            label: 'Use for Essay',
                            onPressed: () {
                              final start = selection.start.clamp(
                                0,
                                plainText.length,
                              );
                              final end = selection.end.clamp(
                                0,
                                plainText.length,
                              );
                              final selectedText = plainText.substring(
                                start,
                                end,
                              );
                              ContextMenuController.removeAny();
                              showTextToEssayDialog(context, selectedText);
                            },
                          ),
                      ],
                    );
                  },
                  onSelectionChanged: (selection, cause) {
                    _currentSelection = selection;
                    final hasText = !selection.isCollapsed;
                    if (_hasSelection.value != hasText) {
                      _hasSelection.value = hasText;
                    }
                  },
                ),
              ),
              // Floating action button when text is selected
              ValueListenableBuilder<bool>(
                valueListenable: _hasSelection,
                builder: (context, hasSelection, child) {
                  if (!hasSelection) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        final start = _currentSelection.start.clamp(
                          0,
                          _currentPlainText.length,
                        );
                        final end = _currentSelection.end.clamp(
                          0,
                          _currentPlainText.length,
                        );
                        final selectedText = _currentPlainText.substring(
                          start,
                          end,
                        );
                        showTextToEssayDialog(context, selectedText);
                      },
                      icon: const Icon(Icons.article),
                      label: const Text('Use for Essay'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
