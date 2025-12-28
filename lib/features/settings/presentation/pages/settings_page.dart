import 'package:abbey/core/storage/pcloud_service.dart';
import 'package:abbey/core/storage/storage_service.dart';
import 'package:abbey/core/theme/app_theme.dart';
import 'package:abbey/features/editor/presentation/providers/editor_provider.dart';
import 'package:abbey/features/setup/presentation/pages/setup_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  StorageType? _currentStorageType;
  String? _currentStoragePath;
  bool _isPCloudAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final storageService = ref.read(storageServiceProvider.notifier);
    final pCloudService = ref.read(pCloudServiceProvider.notifier);

    final type = await storageService.getStorageType();
    final path = await storageService.getStoragePath();
    final pCloudAuth = await pCloudService.isAuthenticated();

    if (mounted) {
      setState(() {
        _currentStorageType = type;
        _currentStoragePath = path;
        _isPCloudAuthenticated = pCloudAuth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAppearanceSection(),
                const SizedBox(height: 8),
                _buildStorageSection(),
                const SizedBox(height: 8),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildAppearanceSection() {
    final currentTheme = ref.watch(themeProvider);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.palette),
        title: const Text('Appearance'),
        subtitle: Text(AppTheme.getThemeName(currentTheme)),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppThemeMode.values.map((mode) {
                final isSelected = currentTheme == mode;
                return InkWell(
                  onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppTheme.getThemeIcon(mode),
                          size: 28,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTheme.getThemeName(mode),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    String storageInfo;
    IconData storageIcon;

    switch (_currentStorageType) {
      case StorageType.pCloud:
        storageInfo = _isPCloudAuthenticated ? 'pCloud (Connected)' : 'pCloud (Not authenticated)';
        storageIcon = Icons.cloud;
        break;
      case StorageType.local:
      default:
        storageInfo = _currentStoragePath != null ? 'Local: ${_currentStoragePath!.split('/').last}' : 'Not configured';
        storageIcon = Icons.folder;
        break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(storageIcon),
        title: const Text('Storage'),
        subtitle: Text(storageInfo),
        initiallyExpanded: false,
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Local Folder'),
            subtitle: const Text('Store files on this device'),
            trailing: _currentStorageType == StorageType.local
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: _selectLocalFolder,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('pCloud'),
            subtitle: Text(_isPCloudAuthenticated
                ? 'Connected - Tap to reconnect'
                : 'Connect your pCloud account'),
            trailing: _currentStorageType == StorageType.pCloud
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: _connectPCloud,
          ),
          if (_currentStorageType == StorageType.pCloud && _isPCloudAuthenticated) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Disconnect pCloud'),
              subtitle: const Text('Remove pCloud connection'),
              onTap: _disconnectPCloud,
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder_shared),
            title: const Text('Synced Folder'),
            subtitle: const Text('Dropbox, Google Drive, etc.'),
            trailing: _currentStorageType == StorageType.local &&
                    _currentStoragePath != null &&
                    (_currentStoragePath!.contains('Dropbox') ||
                        _currentStoragePath!.contains('Google'))
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: _selectLocalFolder,
          ),
          // pCloud actions when connected
          if (_currentStorageType == StorageType.pCloud && _isPCloudAuthenticated) ...[
            const Divider(height: 1, thickness: 2),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Setup Folder Structure'),
              subtitle: const Text('Create Essays, Flows, Backups folders'),
              onTap: _createPCloudFolder,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Now'),
              subtitle: const Text('Save current content to Backups folder'),
              onTap: _backupNow,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Upload Local Files'),
              subtitle: const Text('Migrate files from local storage'),
              onTap: _migrateLocalToPCloud,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clean Up Duplicates'),
              subtitle: const Text('Remove duplicate Abbey folder'),
              onTap: _cleanupDuplicateFolders,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About'),
        subtitle: const Text('Abbey v0.1.0'),
        initiallyExpanded: false,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset App'),
            subtitle: const Text('Go back to setup wizard'),
            onTap: _resetApp,
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocalFolder() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      await ref.read(storageServiceProvider.notifier).setStoragePath(selectedDirectory);
      await _loadStorageInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage set to: $selectedDirectory')),
        );
      }
    }
  }

  Future<void> _connectPCloud() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening browser for pCloud login...')),
        );
      }
      
      final success = await ref.read(pCloudServiceProvider.notifier).startLogin();
      
      if (success) {
        await ref.read(storageServiceProvider.notifier).setPCloudStorage();
        await _loadStorageInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully connected to pCloud!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('pCloud login was cancelled or failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _disconnectPCloud() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect pCloud?'),
        content: const Text(
          'This will remove your pCloud connection. Your files will remain in pCloud but Abbey will no longer sync with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(pCloudServiceProvider.notifier).logout();
      await _loadStorageInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('pCloud disconnected')),
        );
      }
    }
  }
  
  Future<void> _createPCloudFolder() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting up folder structure in pCloud...')),
        );
      }
      
      await ref.read(pCloudServiceProvider.notifier).ensureAbbeyFolderExists();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder structure created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating folders: $e')),
        );
      }
    }
  }
  
  Future<void> _backupNow() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating backup...')),
        );
      }
      
      await ref.read(editorProvider.notifier).manualBackup();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }
  
  Future<void> _cleanupDuplicateFolders() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Up Duplicate Folders?'),
        content: const Text(
          'This will delete any duplicate "Abbey" folder inside your pCloud app folder. '
          'Make sure to backup any important files first!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleaning up duplicate folders...')),
        );
      }
      
      final deleted = await ref.read(pCloudServiceProvider.notifier).cleanupDuplicateAbbeyFolder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleted 
                ? 'Duplicate folder removed!' 
                : 'No duplicate folders found'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  Future<void> _migrateLocalToPCloud() async {
    // Check if there are local files to migrate
    final localFiles = await ref.read(storageServiceProvider.notifier).getLocalFiles();
    
    if (localFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No local files to migrate')),
        );
      }
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Files to pCloud?'),
        content: Text(
          'This will upload ${localFiles.length} file(s) from your local Abbey folder to pCloud. '
          'The local files will remain in place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting migration...')),
        );
      }
      
      final pCloudService = ref.read(pCloudServiceProvider.notifier);
      final localAbbeyPath = await ref.read(storageServiceProvider.notifier).getLocalAbbeyPath();
      
      int successCount = 0;
      int failCount = 0;
      
      for (final file in localFiles) {
        try {
          // Get relative path from Abbey folder
          final relativePath = file.path.replaceFirst('$localAbbeyPath/', '');
          final parts = relativePath.split('/');
          final subfolder = parts.length > 1 ? parts.first : '';
          final filename = parts.last;
          
          final content = await file.readAsString();
          await pCloudService.uploadFile(subfolder, filename, content);
          successCount++;
        } catch (e) {
          failCount++;
          print('Failed to upload ${file.path}: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration complete: $successCount uploaded, $failCount failed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration error: $e')),
        );
      }
    }
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will clear all settings and take you back to the setup wizard. Your files will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(storageServiceProvider.notifier).clearStorage();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SetupPage()),
          (route) => false,
        );
      }
    }
  }
}
