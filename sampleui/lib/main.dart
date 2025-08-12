import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_models.dart';
import 'providers/theme_provider.dart';
import 'screens/widget_playground_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SampleUIApp()));
}

class SampleUIApp extends ConsumerWidget {
  const SampleUIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return MaterialApp(
      title: 'Sample UI Playground',
      theme: AppTheme.lightTheme(themeColor.color),
      darkTheme: AppTheme.darkTheme(themeColor.color),
      themeMode: _convertToThemeMode(themeMode),
      home: const WidgetPlaygroundScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeMode _convertToThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
