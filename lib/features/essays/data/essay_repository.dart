import 'dart:convert';
import 'dart:io';
import 'package:abbey/core/storage/storage_service.dart';
import 'package:abbey/features/essays/domain/models/essay.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'essay_repository.g.dart';

@Riverpod(keepAlive: true)
class EssayRepository extends _$EssayRepository {
  @override
  Future<List<Essay>> build() async {
    return _loadEssays();
  }

  Future<List<Essay>> _loadEssays() async {
    final storagePath = await ref.read(storageServiceProvider.notifier).getStoragePath();
    if (storagePath == null) return [];

    final essaysDir = Directory('$storagePath/Abbey/Essays');
    if (!await essaysDir.exists()) return [];

    final List<Essay> essays = [];
    await for (final entity in essaysDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content);
          essays.add(Essay.fromJson(json));
        } catch (e) {
          print('Error loading essay ${entity.path}: $e');
        }
      }
    }
    
    // Sort by updated at descending
    essays.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return essays;
  }

  Future<void> saveEssay(Essay essay) async {
    final storagePath = await ref.read(storageServiceProvider.notifier).getStoragePath();
    if (storagePath == null) throw Exception('Storage not configured');

    final file = File('$storagePath/Abbey/Essays/${essay.id}.json');
    await file.writeAsString(jsonEncode(essay.toJson()));
    
    // Refresh the list
    ref.invalidateSelf();
  }

  Future<Essay> createEssay({required String title, required String content}) async {
    final now = DateTime.now();
    final essay = Essay(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await saveEssay(essay);
    return essay;
  }
  
  Future<void> deleteEssay(String id) async {
    final storagePath = await ref.read(storageServiceProvider.notifier).getStoragePath();
    if (storagePath == null) return;

    final file = File('$storagePath/Abbey/Essays/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
    ref.invalidateSelf();
  }
}
