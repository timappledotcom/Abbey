import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_service.g.dart';

enum StorageType {
  local,
  pCloud,
  // Future: dropbox, googleDrive
}

/// Callback for reporting migration progress
typedef MigrationProgressCallback = void Function(String message, double progress);

@Riverpod(keepAlive: true)
class StorageService extends _$StorageService {
  static const String _storagePathKey = 'abbey_storage_path';
  static const String _storageTypeKey = 'abbey_storage_type';

  @override
  Future<void> build() async {
    // Initialize checks if needed
  }

  Future<String?> getStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storagePathKey);
  }
  
  Future<StorageType> getStorageType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_storageTypeKey);
    if (typeStr == StorageType.pCloud.toString()) {
      return StorageType.pCloud;
    }
    return StorageType.local;
  }

  Future<void> setStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storagePathKey, path);
    await prefs.setString(_storageTypeKey, StorageType.local.toString());
    
    // Create the Abbey folder structure if it doesn't exist
    final abbeyDir = Directory('$path/Abbey');
    if (!await abbeyDir.exists()) {
      await abbeyDir.create(recursive: true);
    }
    
    // Create subfolders
    final essaysDir = Directory('${abbeyDir.path}/Essays');
    if (!await essaysDir.exists()) {
      await essaysDir.create();
    }
    
    final flowsDir = Directory('${abbeyDir.path}/Flows');
    if (!await flowsDir.exists()) {
      await flowsDir.create();
    }
    
    final backupsDir = Directory('${abbeyDir.path}/Backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create();
    }
  }
  
  Future<void> setPCloudStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageTypeKey, StorageType.pCloud.toString());
    // We don't set a path for pCloud, as it uses the API
  }
  
  Future<bool> isConfigured() async {
    final type = await getStorageType();
    if (type == StorageType.pCloud) return true;
    
    final path = await getStoragePath();
    return path != null && path.isNotEmpty;
  }
  
  /// Clears all storage settings to reset the app.
  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storagePathKey);
    await prefs.remove(_storageTypeKey);
  }
  
  /// Gets the local Abbey folder path if configured
  Future<String?> getLocalAbbeyPath() async {
    final path = await getStoragePath();
    if (path == null) return null;
    return '$path/Abbey';
  }
  
  /// Lists all files in the local Abbey folder recursively
  Future<List<File>> getLocalFiles() async {
    final abbeyPath = await getLocalAbbeyPath();
    if (abbeyPath == null) return [];
    
    final abbeyDir = Directory(abbeyPath);
    if (!await abbeyDir.exists()) return [];
    
    final files = <File>[];
    await for (final entity in abbeyDir.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }
  
  /// Checks if there are files to migrate from current storage
  Future<bool> hasFilesToMigrate() async {
    final type = await getStorageType();
    if (type == StorageType.local) {
      final files = await getLocalFiles();
      return files.isNotEmpty;
    }
    // TODO: Check pCloud for files
    return false;
  }
}
