import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/flow_repository.dart';

class FlowReaderPage extends ConsumerWidget {
  const FlowReaderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Journal'),
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
          if (essay == null) {
            return const Center(child: Text('No Flow Journal found.'));
          }

          return Markdown(
            data: essay.content,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyLarge,
              h1: Theme.of(context).textTheme.headlineLarge,
              h2: Theme.of(context).textTheme.headlineMedium,
              h3: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        },
      ),
    );
  }
}
