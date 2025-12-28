import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:abbey/core/storage/file_service.dart';
import '../../data/flow_repository.dart';

part 'editor_provider.g.dart';

/// Sync status for cloud storage
enum SyncStatus {
  idle, // No sync in progress
  syncing, // Currently syncing
  synced, // Successfully synced
  error, // Sync failed
}

@riverpod
class Editor extends _$Editor {
  Timer? _timer;
  Timer? _syncTimer;
  Timer? _autoBackupTimer;
  static const Duration _autoBackupInterval = Duration(minutes: 15);

  @override
  EditorState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _syncTimer?.cancel();
      _autoBackupTimer?.cancel();
    });
    // Start the auto-backup timer
    _startAutoBackupTimer();
    return const EditorState();
  }

  void _startAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(_autoBackupInterval, (timer) {
      _performAutoBackup();
    });
  }

  Future<void> _performAutoBackup() async {
    if (state.content.isEmpty) return;

    try {
      print('Performing auto-backup to Backups folder...');
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final filename = 'backup_$timestamp.md';

      await ref
          .read(fileServiceProvider)
          .saveFile(
            subfolder: 'Backups',
            filename: filename,
            content: state.content,
          );
      print('Auto-backup completed: $filename');
    } catch (e) {
      print('Auto-backup failed: $e');
    }
  }

  /// Manually trigger a backup to the Backups folder
  Future<void> manualBackup() async {
    if (state.content.isEmpty) {
      throw Exception('Nothing to backup');
    }

    state = state.copyWith(syncStatus: SyncStatus.syncing);

    try {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final filename = 'backup_$timestamp.md';

      await ref
          .read(fileServiceProvider)
          .saveFile(
            subfolder: 'Backups',
            filename: filename,
            content: state.content,
          );
      state = state.copyWith(syncStatus: SyncStatus.synced);

      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.syncStatus == SyncStatus.synced) {
          state = state.copyWith(syncStatus: SyncStatus.idle);
        }
      });
    } catch (e) {
      state = state.copyWith(syncStatus: SyncStatus.error);
      rethrow;
    }
  }

  void updateContent(String newContent) {
    // Don't allow updates if flow has ended (read-only mode)
    if (state.isFlowEnded) return;

    final wordCount = _calculateWordCount(newContent);
    state = state.copyWith(content: newContent, wordCount: wordCount);

    // If in Flow Mode, just save to local DB (no cloud sync during session)
    if (state.isFlowMode && state.currentEssayId != null) {
      // Cancel any pending sync - we only sync when flow ends
      _syncTimer?.cancel();
    }
  }

  Future<void> _syncToCloudStorage(String content) async {
    state = state.copyWith(syncStatus: SyncStatus.syncing);
    try {
      print('Starting cloud sync for flow_stream.md...');
      await ref
          .read(fileServiceProvider)
          .saveFile(
            subfolder: 'Flows',
            filename: 'flow_stream.md',
            content: content,
          );
      print('Cloud sync completed successfully');
      state = state.copyWith(syncStatus: SyncStatus.synced);

      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.syncStatus == SyncStatus.synced) {
          state = state.copyWith(syncStatus: SyncStatus.idle);
        }
      });
    } catch (e) {
      // Log the error but don't crash - local DB is the source of truth
      print('Cloud sync failed: $e');
      state = state.copyWith(syncStatus: SyncStatus.error);

      // Reset to idle after 5 seconds on error
      Future.delayed(const Duration(seconds: 5), () {
        if (state.syncStatus == SyncStatus.error) {
          state = state.copyWith(syncStatus: SyncStatus.idle);
        }
      });
    }
  }

  void toggleZenMode() {
    state = state.copyWith(isZenMode: !state.isZenMode);
  }

  Future<void> startFlowMode(Duration duration) async {
    _timer?.cancel();

    // 1. Get the Flow Essay (to have the ID for later)
    final flowRepo = ref.read(flowRepositoryProvider);
    final essay = await flowRepo.getOrCreateFlowEssay();

    // 2. Create session timestamp for when we save
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];

    // 3. Start with fresh content - just the session header
    final freshContent = '### Session: $timestamp\n\n';

    // 4. Update State with fresh workspace
    state = state.copyWith(
      isFlowMode: true,
      flowRemaining: duration,
      content: freshContent,
      currentEssayId: essay.id,
      wordCount: 0,
    );

    // 5. Start Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.flowRemaining - const Duration(seconds: 1);
      if (remaining.inSeconds <= 0) {
        stopFlowMode();
      } else {
        state = state.copyWith(flowRemaining: remaining);
      }
    });
  }

  Future<void> stopFlowMode() async {
    _timer?.cancel();
    _syncTimer?.cancel();

    // Get the current session content
    final sessionContent = state.content;

    // Append session content to the Flow Journal
    if (sessionContent.isNotEmpty) {
      final flowRepo = ref.read(flowRepositoryProvider);
      final essay = await flowRepo.getOrCreateFlowEssay();

      // Append the session to existing journal content
      final separator = essay.content.isEmpty ? '' : '\n\n';
      final updatedContent = '${essay.content}$separator$sessionContent';

      // Save to local database
      await flowRepo.updateFlowEssay(updatedContent);

      // Sync to cloud storage
      await _syncToCloudStorage(updatedContent);
    }

    // Keep content visible but mark as read-only (flow ended)
    state = state.copyWith(
      isFlowMode: false,
      isFlowEnded: true,
      flowRemaining: Duration.zero,
    );
  }

  /// Exit flow completely and clear the editor
  void exitFlow() {
    state = state.copyWith(
      isFlowEnded: false,
      content: '',
      currentEssayId: null,
    );
  }

  int _calculateWordCount(String text) {
    if (text.isEmpty) return 0;
    return RegExp(r'\w+').allMatches(text).length;
  }
}

class EditorState {
  final String content;
  final String? currentEssayId;
  final bool isZenMode;
  final bool isFlowMode;
  final bool isFlowEnded;
  final Duration flowRemaining;
  final int wordCount;
  final SyncStatus syncStatus;

  const EditorState({
    this.content = '',
    this.currentEssayId,
    this.isZenMode = false,
    this.isFlowMode = false,
    this.isFlowEnded = false,
    this.flowRemaining = Duration.zero,
    this.wordCount = 0,
    this.syncStatus = SyncStatus.idle,
  });

  EditorState copyWith({
    String? content,
    String? currentEssayId,
    bool? isZenMode,
    bool? isFlowMode,
    bool? isFlowEnded,
    Duration? flowRemaining,
    int? wordCount,
    SyncStatus? syncStatus,
  }) {
    return EditorState(
      content: content ?? this.content,
      currentEssayId: currentEssayId ?? this.currentEssayId,
      isZenMode: isZenMode ?? this.isZenMode,
      isFlowMode: isFlowMode ?? this.isFlowMode,
      isFlowEnded: isFlowEnded ?? this.isFlowEnded,
      flowRemaining: flowRemaining ?? this.flowRemaining,
      wordCount: wordCount ?? this.wordCount,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
