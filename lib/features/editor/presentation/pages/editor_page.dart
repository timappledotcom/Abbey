import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abbey/features/settings/presentation/pages/settings_page.dart';
import 'package:abbey/features/essays/presentation/pages/essays_list_page.dart';
import '../providers/editor_provider.dart';
import '../widgets/text_to_essay_dialog.dart';
import 'flow_reader_page.dart';

class EditorPage extends ConsumerStatefulWidget {
  final Duration? startFlowDuration;

  const EditorPage({super.key, this.startFlowDuration});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late TextEditingController _textController;
  bool _hasSelection = false;
  String _selectedText = '';
  String _flowEndedContent = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onSelectionChanged);

    // Start flow mode if duration was passed
    if (widget.startFlowDuration != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(editorProvider.notifier)
            .startFlowMode(widget.startFlowDuration!);
      });
    }
  }

  void _onSelectionChanged() {
    final hasSelection =
        _textController.selection.start != _textController.selection.end;
    if (hasSelection != _hasSelection) {
      setState(() {
        _hasSelection = hasSelection;
      });
    }
  }

  String _getSelectedText() {
    // Return stored selected text (works for both TextField and SelectableText)
    if (_selectedText.isNotEmpty) {
      return _selectedText;
    }
    // Fallback to controller selection for TextField
    final selection = _textController.selection;
    if (selection.start != selection.end) {
      return _textController.text.substring(selection.start, selection.end);
    }
    return '';
  }

  void _onSelectableTextSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final hasSelection = selection.start != selection.end;
    String newSelectedText = '';
    if (hasSelection && _flowEndedContent.isNotEmpty) {
      newSelectedText = _flowEndedContent.substring(
        selection.start,
        selection.end,
      );
    }
    if (hasSelection != _hasSelection || newSelectedText != _selectedText) {
      setState(() {
        _hasSelection = hasSelection;
        _selectedText = newSelectedText;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onSelectionChanged);
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
      if (editorState.isFlowMode &&
          !_textController.text.contains("### Session:")) {
        _textController.text = editorState.content;
        // Move cursor to end
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      } else if (!editorState.isFlowMode &&
          editorState.content.isEmpty &&
          _textController.text.isNotEmpty) {
        // Cleared state
        _textController.clear();
      }
    }

    return Scaffold(
      appBar: isZenMode
          ? null
          : AppBar(
              title: Text(
                editorState.isFlowMode ? 'Flow Stream' : 'Untitled Draft',
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    editorState.isFlowMode ? Icons.waves : Icons.timer,
                  ),
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
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    subtitle: const Text('Main menu'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pop(context); // Go back to HomePage
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('Essays'),
                    subtitle: const Text('Your standalone writings'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EssaysListPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Projects'),
                    subtitle: const Text('Collections & books'),
                    onTap: () {
                      // TODO: Navigate to Project List
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Projects coming soon!')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.waves,
                      color: editorState.isFlowMode
                          ? Theme.of(context).colorScheme.secondary
                          : null,
                    ),
                    title: const Text('Flow'),
                    subtitle: Text(
                      editorState.isFlowMode
                          ? 'In session • ${_formatDuration(editorState.flowRemaining)}'
                          : 'Write freely or read past sessions',
                    ),
                    trailing: editorState.isFlowMode
                        ? Icon(
                            Icons.circle,
                            size: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _showFlowOptionsDialog(context, editorState.isFlowMode);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      body: Stack(
        children: [
          // Flow Mode visual indicator - subtle border glow
          if (editorState.isFlowMode)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),

          // Main Editor Area
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isZenMode ? 40.0 : 16.0,
              vertical: (editorState.isFlowMode || editorState.isFlowEnded)
                  ? 80.0
                  : 16.0, // Extra top padding for flow banner
            ),
            child: editorState.isFlowEnded
                // Read-only selectable text when flow has ended
                ? Builder(
                    builder: (context) {
                      // Store content for selection tracking
                      _flowEndedContent = _textController.text;
                      return SelectableText(
                        _textController.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                        onSelectionChanged: _onSelectableTextSelectionChanged,
                      );
                    },
                  )
                // Editable text field during normal use
                : TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: editorState.isFlowMode
                          ? 'Let it flow...'
                          : 'Start writing...',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    // Enable spell check only when NOT in flow mode
                    spellCheckConfiguration: editorState.isFlowMode
                        ? const SpellCheckConfiguration.disabled()
                        : const SpellCheckConfiguration(),
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withOpacity(0.8),
                elevation: 0,
                onPressed: () =>
                    ref.read(editorProvider.notifier).toggleZenMode(),
                child: const Icon(Icons.fullscreen_exit),
              ),
            ),

          // "Use for Essay" button when text is selected in Flow Mode or after flow ends
          if ((editorState.isFlowMode || editorState.isFlowEnded) &&
              _hasSelection)
            Positioned(
              bottom: 70,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  final selectedText = _getSelectedText();
                  if (selectedText.isNotEmpty) {
                    showTextToEssayDialog(context, selectedText);
                  }
                },
                icon: const Icon(Icons.article),
                label: const Text('Use for Essay'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),

          // Word Count and Sync Status Overlay
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync status indicator
                  _buildSyncIndicator(context, editorState.syncStatus),
                  const SizedBox(width: 8),
                  Text(
                    '${editorState.wordCount} words',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Flow Mode Banner - more prominent indicator
          if (editorState.isFlowMode || editorState.isFlowEnded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: editorState.isFlowEnded
                        ? [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
                          ]
                        : [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.8),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (editorState.isFlowEnded
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          editorState.isFlowEnded
                              ? Icons.check_circle
                              : Icons.waves,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          editorState.isFlowEnded
                              ? 'SESSION COMPLETE'
                              : 'FLOW MODE',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                        if (!editorState.isFlowEnded) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDuration(editorState.flowRemaining),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'End Flow Session',
                            onPressed: () => _showStopFlowDialog(context),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                        if (editorState.isFlowEnded) ...[
                          const SizedBox(width: 16),
                          FilledButton.tonal(
                            onPressed: () {
                              ref.read(editorProvider.notifier).exitFlow();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Done'),
                          ),
                        ],
                      ],
                    ),
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

  Widget _buildSyncIndicator(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Syncing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      case SyncStatus.synced:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Synced',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green),
            ),
          ],
        );
      case SyncStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Sync failed',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ],
        );
      case SyncStatus.idle:
        return const SizedBox.shrink();
    }
  }

  void _showFlowOptionsDialog(BuildContext context, bool isInFlowMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(
                isInFlowMode ? 'Continue Flow Session' : 'Start Flow Session',
              ),
              subtitle: Text(
                isInFlowMode
                    ? 'Return to your current flow'
                    : 'Begin a timed writing sprint',
              ),
              onTap: () {
                Navigator.pop(context);
                if (isInFlowMode) {
                  // Already in flow mode, just close dialog
                } else {
                  _showFlowModeDialog(context);
                }
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
            if (isInFlowMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Stop Flow Session'),
                subtitle: const Text('End your current session early'),
                onTap: () {
                  Navigator.pop(context);
                  _showStopFlowDialog(context);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFlowModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Flow Phase'),
        content: const Text(
          'Choose a duration for your writing sprint. This will open your continuous Flow Stream.',
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

  void _showStopFlowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Flow Session?'),
        content: const Text(
          'Your writing will be saved. Are you sure you want to stop the flow session early?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Writing'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(editorProvider.notifier).stopFlowMode();
              Navigator.pop(context);
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
