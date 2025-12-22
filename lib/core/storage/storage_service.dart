import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_service.g.dart';

enum StorageType {
  local,
  pCloud,
  // Future: dropbox, googleDrive
}

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
    
    final booksDir = Directory('${abbeyDir.path}/Books');
    if (!await booksDir.exists()) {
      await booksDir.create();
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
}
