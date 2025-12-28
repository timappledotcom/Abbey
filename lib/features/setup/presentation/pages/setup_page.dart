import 'package:abbey/core/storage/pcloud_service.dart';
import 'package:abbey/core/storage/storage_service.dart';
import 'package:abbey/features/editor/presentation/pages/editor_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Abbey',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose where you want to keep your writings. Abbey will create a dedicated folder for your essays and books.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 48),
              _StorageOption(
                icon: Icons.computer,
                title: 'Local File System',
                description: 'Save files directly to your device',
                onTap: () async {
                  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                  
                  if (selectedDirectory != null) {
                    await ref.read(storageServiceProvider.notifier).setStoragePath(selectedDirectory);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const EditorPage()),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _StorageOption(
                icon: Icons.cloud_outlined,
                title: 'pCloud',
                description: 'Sync directly with your pCloud account',
                onTap: () async {
                  try {
                    // Show a loading indicator
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening browser for pCloud login...')),
                      );
                    }
                    
                    // Start login - this will block until OAuth completes
                    final success = await ref.read(pCloudServiceProvider.notifier).startLogin();
                    
                    if (success) {
                      await ref.read(storageServiceProvider.notifier).setPCloudStorage();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully connected to pCloud!')),
                        );
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const EditorPage()),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('pCloud login was cancelled or failed')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _StorageOption(
                icon: Icons.folder_shared,
                title: 'Dropbox / Google Drive',
                description: 'Select your synced folder on this device',
                onTap: () async {
                   // For now, this behaves the same as local file system on desktop
                   // because cloud providers usually mount as folders.
                   // We can add specific instructions or API integrations later.
                  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                  
                  if (selectedDirectory != null) {
                    await ref.read(storageServiceProvider.notifier).setStoragePath(selectedDirectory);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const EditorPage()),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _StorageOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.black87),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
