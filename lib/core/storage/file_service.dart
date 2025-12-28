import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'storage_service.dart';
import 'pcloud_service.dart';

part 'file_service.g.dart';

/// Unified file service that handles saving/loading files
/// to either local storage or pCloud based on user settings.
@riverpod
FileService fileService(Ref ref) {
  return FileService(ref);
}

class FileService {
  final Ref _ref;

  FileService(this._ref);

  /// Saves content to the appropriate storage location
  Future<void> saveFile({
    required String subfolder,
    required String filename,
    required String content,
  }) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final storageType = await storageService.getStorageType();

    print(
      'FileService.saveFile: storageType=$storageType, subfolder=$subfolder, filename=$filename',
    );

    if (storageType == StorageType.pCloud) {
      print('Saving to pCloud...');
      await _saveToPCloud(subfolder, filename, content);
    } else {
      print('Saving to local storage...');
      await _saveToLocal(subfolder, filename, content);
    }
  }

  /// Saves Flow content specifically
  Future<void> saveFlowContent(String content) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    final filename = 'flow_$timestamp.md';
    await saveFile(subfolder: 'Flows', filename: filename, content: content);
  }

  /// Saves Essay content
  Future<void> saveEssay(String title, String content) async {
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final filename = '$sanitizedTitle.md';
    await saveFile(subfolder: 'Essays', filename: filename, content: content);
  }

  Future<void> _saveToPCloud(
    String subfolder,
    String filename,
    String content,
  ) async {
    final pCloudService = _ref.read(pCloudServiceProvider.notifier);

    final isAuth = await pCloudService.isAuthenticated();
    if (!isAuth) {
      throw Exception('Not authenticated with pCloud');
    }

    await pCloudService.uploadFile(subfolder, filename, content);
  }

  Future<void> _saveToLocal(
    String subfolder,
    String filename,
    String content,
  ) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final abbeyPath = await storageService.getLocalAbbeyPath();

    if (abbeyPath == null) {
      throw Exception('Local storage not configured');
    }

    final folderPath = '$abbeyPath/$subfolder';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final file = File('$folderPath/$filename');
    await file.writeAsString(content);
  }

  /// Deletes a file from the appropriate storage location
  Future<void> deleteFile({
    required String subfolder,
    required String filename,
  }) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final storageType = await storageService.getStorageType();

    print(
      'FileService.deleteFile: storageType=$storageType, subfolder=$subfolder, filename=$filename',
    );

    if (storageType == StorageType.pCloud) {
      print('Deleting from pCloud...');
      await _deleteFromPCloud(subfolder, filename);
    } else {
      print('Deleting from local storage...');
      await _deleteFromLocal(subfolder, filename);
    }
  }

  Future<void> _deleteFromPCloud(String subfolder, String filename) async {
    final pCloudService = _ref.read(pCloudServiceProvider.notifier);

    final isAuth = await pCloudService.isAuthenticated();
    if (!isAuth) {
      throw Exception('Not authenticated with pCloud');
    }

    await pCloudService.deleteFile(subfolder, filename);
  }

  Future<void> _deleteFromLocal(String subfolder, String filename) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final abbeyPath = await storageService.getLocalAbbeyPath();

    if (abbeyPath == null) {
      throw Exception('Local storage not configured');
    }

    final file = File('$abbeyPath/$subfolder/$filename');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Reads a file from the appropriate storage location
  Future<String?> readFile({
    required String subfolder,
    required String filename,
  }) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final storageType = await storageService.getStorageType();

    if (storageType == StorageType.pCloud) {
      return await _readFromPCloud(subfolder, filename);
    } else {
      return await _readFromLocal(subfolder, filename);
    }
  }

  Future<String?> _readFromPCloud(String subfolder, String filename) async {
    // TODO: Implement pCloud file reading
    return null;
  }

  Future<String?> _readFromLocal(String subfolder, String filename) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final abbeyPath = await storageService.getLocalAbbeyPath();

    if (abbeyPath == null) return null;

    final file = File('$abbeyPath/$subfolder/$filename');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Lists files in a subfolder
  Future<List<String>> listFiles(String subfolder) async {
    final storageService = _ref.read(storageServiceProvider.notifier);
    final storageType = await storageService.getStorageType();

    if (storageType == StorageType.pCloud) {
      final pCloudService = _ref.read(pCloudServiceProvider.notifier);
      final files = await pCloudService.listFiles(subfolder);
      return files.map((f) => f['name'] as String).toList();
    } else {
      final abbeyPath = await storageService.getLocalAbbeyPath();
      if (abbeyPath == null) return [];

      final folder = Directory('$abbeyPath/$subfolder');
      if (!await folder.exists()) return [];

      final files = <String>[];
      await for (final entity in folder.list()) {
        if (entity is File) {
          files.add(entity.path.split('/').last);
        }
      }
      return files;
    }
  }
}
