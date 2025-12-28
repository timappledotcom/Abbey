import 'dart:convert';
import 'dart:io';
import 'package:abbey/core/storage/storage_service.dart';
import 'package:abbey/core/storage/file_service.dart';
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
    final storageService = ref.read(storageServiceProvider.notifier);
    var storagePath = await storageService.getStoragePath();

    if (storagePath == null) {
      // Fallback to home directory
      final home = Platform.environment['HOME'] ?? '/tmp';
      storagePath = '$home/Documents';
    }

    final essaysDir = Directory('$storagePath/Abbey/Essays');
    if (!await essaysDir.exists()) {
      await essaysDir.create(recursive: true);
      return [];
    }

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

    // Sort by updated at descending (newest first)
    essays.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return essays;
  }

  /// Get only draft essays
  Future<List<Essay>> getDrafts() async {
    final essays = await future;
    return essays.where((e) => e.status == EssayStatus.draft).toList();
  }

  /// Get only archived essays
  Future<List<Essay>> getArchived() async {
    final essays = await future;
    return essays.where((e) => e.status == EssayStatus.archived).toList();
  }

  /// Get a single essay by ID
  Future<Essay?> getEssay(String id) async {
    final essays = await future;
    try {
      return essays.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEssay(Essay essay) async {
    final storageService = ref.read(storageServiceProvider.notifier);
    final storageType = await storageService.getStorageType();

    String? storagePath;
    if (storageType == StorageType.pCloud) {
      // For pCloud, use a local cache directory as well
      // Essays are saved locally and can be synced to pCloud
      storagePath = await storageService.getStoragePath();
      if (storagePath == null) {
        // Fallback to home directory
        final home = Platform.environment['HOME'] ?? '/tmp';
        storagePath = '$home/Documents';
      }
    } else {
      storagePath = await storageService.getStoragePath();
      if (storagePath == null) {
        // Fallback to home directory
        final home = Platform.environment['HOME'] ?? '/tmp';
        storagePath = '$home/Documents';
      }
    }

    final essaysDir = Directory('$storagePath/Abbey/Essays');
    if (!await essaysDir.exists()) {
      await essaysDir.create(recursive: true);
    }

    final file = File('$storagePath/Abbey/Essays/${essay.id}.json');
    await file.writeAsString(jsonEncode(essay.toJson()));

    // Sync to pCloud if enabled
    await _syncEssayToPCloud(essay);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Syncs an essay to pCloud as a markdown file
  Future<void> _syncEssayToPCloud(Essay essay) async {
    try {
      final storageService = ref.read(storageServiceProvider.notifier);
      final storageType = await storageService.getStorageType();

      if (storageType == StorageType.pCloud) {
        final fileService = ref.read(fileServiceProvider);

        // Create a readable markdown version of the essay
        final markdownContent =
            '''# ${essay.title}

${essay.content}

---
*Last updated: ${essay.updatedAt.toLocal().toString().split('.')[0]}*
''';

        // Sanitize the title for filename
        final sanitizedTitle = essay.title
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_')
            .trim();
        final filename = sanitizedTitle.isEmpty ? essay.id : sanitizedTitle;

        await fileService.saveFile(
          subfolder: 'Essays',
          filename: '$filename.md',
          content: markdownContent,
        );
        print('Essay synced to pCloud: $filename.md');
      }
    } catch (e) {
      // Don't fail the save if pCloud sync fails - local is source of truth
      print('Failed to sync essay to pCloud: $e');
    }
  }

  Future<Essay> createEssay({
    required String title,
    String content = '',
  }) async {
    final now = DateTime.now();
    final essay = Essay(
      id: const Uuid().v4(),
      title: title,
      content: content,
      status: EssayStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    await saveEssay(essay);
    return essay;
  }

  Future<void> updateEssay(Essay essay) async {
    final updated = essay.copyWith(updatedAt: DateTime.now());
    await saveEssay(updated);
  }

  Future<void> renameEssay(String id, String newTitle) async {
    final essay = await getEssay(id);
    if (essay != null) {
      final oldTitle = essay.title;

      // Delete the old pCloud file first (before saving with new title)
      await _deleteOldPCloudFile(oldTitle);

      // Now save with the new title
      await updateEssay(essay.copyWith(title: newTitle));
    }
  }

  /// Deletes the old markdown file from pCloud when renaming
  Future<void> _deleteOldPCloudFile(String oldTitle) async {
    try {
      final storageService = ref.read(storageServiceProvider.notifier);
      final storageType = await storageService.getStorageType();

      if (storageType == StorageType.pCloud) {
        final fileService = ref.read(fileServiceProvider);

        // Reconstruct the old filename
        final sanitizedOldTitle = oldTitle
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_')
            .trim();
        final oldFilename = sanitizedOldTitle.isEmpty
            ? 'untitled'
            : sanitizedOldTitle;

        await fileService.deleteFile(
          subfolder: 'Essays',
          filename: '$oldFilename.md',
        );
        print('Deleted old pCloud file: $oldFilename.md');
      }
    } catch (e) {
      // Don't fail if deletion fails - it might not exist
      print('Could not delete old pCloud file: $e');
    }
  }

  Future<void> archiveEssay(String id) async {
    final essay = await getEssay(id);
    if (essay != null) {
      await updateEssay(essay.copyWith(status: EssayStatus.archived));
    }
  }

  Future<void> unarchiveEssay(String id) async {
    final essay = await getEssay(id);
    if (essay != null) {
      await updateEssay(essay.copyWith(status: EssayStatus.draft));
    }
  }

  Future<void> deleteEssay(String id) async {
    print('=== DELETE ESSAY DEBUG ===');
    print('Deleting essay with id: $id');

    // Get essay first to know the title for pCloud deletion
    final essay = await getEssay(id);
    print('Essay found: ${essay?.title}');

    final storageService = ref.read(storageServiceProvider.notifier);
    var storagePath = await storageService.getStoragePath();

    // Use fallback if storage path is null (same as saveEssay and _loadEssays)
    if (storagePath == null) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      storagePath = '$home/Documents';
    }
    print('Storage path: $storagePath');

    // Delete local JSON file
    final filePath = '$storagePath/Abbey/Essays/$id.json';
    final file = File(filePath);
    print('Looking for file: $filePath');
    print('File exists: ${await file.exists()}');

    if (await file.exists()) {
      await file.delete();
      print('File deleted successfully');
    } else {
      print('WARNING: File not found at expected path');
    }

    // Also delete from pCloud if applicable
    if (essay != null) {
      await _deleteOldPCloudFile(essay.title);
    }

    print('Invalidating provider...');
    ref.invalidateSelf();
    print('=== END DELETE DEBUG ===');
  }
}
