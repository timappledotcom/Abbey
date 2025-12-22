import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/flow_repository.dart';

part 'editor_provider.g.dart';

@riverpod
class Editor extends _$Editor {
  Timer? _timer;

  @override
  EditorState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const EditorState();
  }

  void updateContent(String newContent) {
    final wordCount = _calculateWordCount(newContent);
    state = state.copyWith(content: newContent, wordCount: wordCount);
    
    // If in Flow Mode, auto-save to the Flow Essay
    if (state.isFlowMode && state.currentEssayId != null) {
      ref.read(flowRepositoryProvider).updateFlowContent(state.currentEssayId!, newContent);
    }
  }

  void toggleZenMode() {
    state = state.copyWith(isZenMode: !state.isZenMode);
  }

  Future<void> startFlowMode(Duration duration) async {
    _timer?.cancel();
    
    // 1. Get the Flow Essay
    final flowRepo = ref.read(flowRepositoryProvider);
    final essay = await flowRepo.getOrCreateFlowEssay();
    
    // 2. Append Timestamp
    final timestamp = DateTime.now().toLocal().toString().split('.')[0]; 
    final separator = essay.content.isEmpty ? '' : '\n\n';
    final newContent = '${essay.content}$separator### Session: $timestamp\n\n';
    
    // 3. Update State
    state = state.copyWith(
      isFlowMode: true,
      flowRemaining: duration,
      content: newContent,
      currentEssayId: essay.id,
      wordCount: _calculateWordCount(newContent),
    );
    
    // 4. Start Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.flowRemaining - const Duration(seconds: 1);
      if (remaining.inSeconds <= 0) {
        stopFlowMode();
      } else {
        state = state.copyWith(flowRemaining: remaining);
      }
    });
  }

  void stopFlowMode() {
    _timer?.cancel();
    state = state.copyWith(isFlowMode: false, flowRemaining: Duration.zero);
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
  final Duration flowRemaining;
  final int wordCount;

  const EditorState({
    this.content = '',
    this.currentEssayId,
    this.isZenMode = false,
    this.isFlowMode = false,
    this.flowRemaining = Duration.zero,
    this.wordCount = 0,
  });

  EditorState copyWith({
    String? content,
    String? currentEssayId,
    bool? isZenMode,
    bool? isFlowMode,
    Duration? flowRemaining,
    int? wordCount,
  }) {
    return EditorState(
      content: content ?? this.content,
      currentEssayId: currentEssayId ?? this.currentEssayId,
      isZenMode: isZenMode ?? this.isZenMode,
      isFlowMode: isFlowMode ?? this.isFlowMode,
      flowRemaining: flowRemaining ?? this.flowRemaining,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}
