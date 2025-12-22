import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/editor_provider.dart';
import 'flow_reader_page.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final isZenMode = editorState.isZenMode;

    // Sync controller with state content if it changes externally (e.g. entering Flow Mode)
    // Note: This is a simple sync. In a real app, we need to be careful not to overwrite user input while typing.
    // For now, we only update if the length difference is significant or it's a mode switch.
    if (_textController.text != editorState.content) {
       // Only update if the state content is significantly different (e.g. loaded a new doc)
       // or if the controller is empty.
       // This is a bit hacky for a real editor but works for this prototype phase.
       // A better way is to have a separate "loaded" state.
       if (editorState.isFlowMode && !_textController.text.contains("### Session:")) {
          _textController.text = editorState.content;
          // Move cursor to end
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
       } else if (!editorState.isFlowMode && editorState.content.isEmpty && _textController.text.isNotEmpty) {
          // Cleared state
          _textController.clear();
       }
    }

    return Scaffold(
      appBar: isZenMode
          ? null
          : AppBar(
              title: Text(editorState.isFlowMode ? 'Flow Stream' : 'Untitled Draft'),
              actions: [
                IconButton(
                  icon: Icon(editorState.isFlowMode ? Icons.waves : Icons.timer),
                  tooltip: 'Flow Mode',
                  onPressed: () => _showFlowModeDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Zen Mode',
                  onPressed: () =>
                      ref.read(editorProvider.notifier).toggleZenMode(),
                ),
              ],
            ),
      drawer: isZenMode
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Text(
                      'Abbey',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Projects'),
                    onTap: () {
                      // TODO: Navigate to Project List
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.waves),
                    title: const Text('Read Flow Journal'),
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
            ),
      body: Stack(
        children: [
          // Main Editor Area
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isZenMode ? 40.0 : 16.0,
              vertical: 16.0,
            ),
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: editorState.isFlowMode ? 'Let it flow...' : 'Start writing...',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (value) {
                ref.read(editorProvider.notifier).updateContent(value);
              },
            ),
          ),

          // Zen Mode Exit Button (Floating)
          if (isZenMode)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                elevation: 0,
                onPressed: () =>
                    ref.read(editorProvider.notifier).toggleZenMode(),
                child: const Icon(Icons.fullscreen_exit),
              ),
            ),

          // Word Count Overlay
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
                '${editorState.wordCount} words',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          // Flow Mode Timer Overlay
          if (editorState.isFlowMode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.waves, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(editorState.flowRemaining),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showFlowModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Flow Phase'),
        content: const Text('Choose a duration for your writing sprint. This will open your continuous Flow Stream.'),
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
                  ref
                      .read(editorProvider.notifier)
                      .startFlowMode(const Duration(minutes: 5));
                  Navigator.pop(context);
                },
                child: const Text('5 Min'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(editorProvider.notifier)
                      .startFlowMode(const Duration(minutes: 10));
                  Navigator.pop(context);
                },
                child: const Text('10 Min'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(editorProvider.notifier)
                      .startFlowMode(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
                child: const Text('15 Min'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(editorProvider.notifier)
                      .startFlowMode(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
                child: const Text('30 Min'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
