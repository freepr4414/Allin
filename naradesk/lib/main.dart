import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_layout_responsive.dart';

void main() {
  runApp(const ProviderScope(child: StudyCafeApp()));
}

class StudyCafeApp extends ConsumerWidget {
  const StudyCafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSizeState = ref.watch(fontSizeProvider);
    final currentFontSize = fontSizeState.currentLevel.baseSize;
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final lightTheme = themeNotifier.lightTheme.copyWith(
      // 폰트크기 설정을 테마에 적용 (라이트 모드 색상)
      textTheme: _buildTextTheme(currentFontSize, isDark: false),
    );

    final darkTheme = themeNotifier.darkTheme.copyWith(
      // 폰트크기 설정을 테마에 적용 (다크 모드 색상)
      textTheme: _buildTextTheme(currentFontSize, isDark: true),
    );

    return MaterialApp(
      title: 'Study Cafe Management',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }

  /// 폰트크기 설정에 따른 텍스트 테마 생성
  TextTheme _buildTextTheme(double baseFontSize, {bool isDark = false}) {
    final ratio = baseFontSize / 16.0; // 기본 16px 기준으로 비율 계산
    // Theme.of(context) 사용 불가 (context 외부) -> 밝기 기준 기본 색을 MaterialScheme에 위임
    final baseColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A1A1A);

    // 필요 시 contrast 조정을 위해 밝기별로 색상 한 곳에서 관리
    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * ratio, color: baseColor),
      displayMedium: TextStyle(fontSize: 45 * ratio, color: baseColor),
      displaySmall: TextStyle(fontSize: 36 * ratio, color: baseColor),
      headlineLarge: TextStyle(fontSize: 32 * ratio, color: baseColor),
      headlineMedium: TextStyle(fontSize: 28 * ratio, color: baseColor),
      headlineSmall: TextStyle(fontSize: 24 * ratio, color: baseColor),
      titleLarge: TextStyle(fontSize: 22 * ratio, color: baseColor),
      titleMedium: TextStyle(fontSize: 16 * ratio, color: baseColor),
      titleSmall: TextStyle(fontSize: 14 * ratio, color: baseColor),
      labelLarge: TextStyle(fontSize: 14 * ratio, color: baseColor),
      labelMedium: TextStyle(fontSize: 12 * ratio, color: baseColor),
      labelSmall: TextStyle(fontSize: 11 * ratio, color: baseColor),
      bodyLarge: TextStyle(fontSize: 16 * ratio, color: baseColor),
      bodyMedium: TextStyle(fontSize: 14 * ratio, color: baseColor),
      bodySmall: TextStyle(fontSize: 12 * ratio, color: baseColor),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return const MainLayout();
    } else {
      return const LoginScreen();
    }
  }
}
