import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/setup/presentation/pages/setup_page.dart';

void main() {
  runApp(const ProviderScope(child: AbbeyApp()));
}

class AbbeyApp extends ConsumerWidget {
  const AbbeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Abbey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeMode),
      home: FutureBuilder<bool>(
        future: ref.read(storageServiceProvider.notifier).isConfigured(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.data == true) {
            return const HomePage();
          }
          
          return const SetupPage();
        },
      ),
    );
  }
}
