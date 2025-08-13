import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_layout_responsive.dart';
import 'utils/font_theme_utils.dart';
import 'utils/responsive.dart';

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
      textTheme: FontThemeUtils.buildTextTheme(currentFontSize, isDark: false),
    );

    final darkTheme = themeNotifier.darkTheme.copyWith(
      // 폰트크기 설정을 테마에 적용 (다크 모드 색상)
      textTheme: FontThemeUtils.buildTextTheme(currentFontSize, isDark: true),
    );

    return MaterialApp(
      title: 'Study Cafe Manager',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 통합된 화면 크기 로그
        Responsive.logScreenSize(context, 'MaterialApp Builder');
        
        // 강력한 최소 크기 제약 적용
        return Container(
          constraints: const BoxConstraints(
            minWidth: AppConstants.minAppWidth,
            minHeight: AppConstants.minAppHeight,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 제약 조건이 최소 크기보다 작으면 강제로 최소 크기 적용
              final width = constraints.maxWidth < AppConstants.minAppWidth 
                  ? AppConstants.minAppWidth 
                  : constraints.maxWidth;
              final height = constraints.maxHeight < AppConstants.minAppHeight 
                  ? AppConstants.minAppHeight 
                  : constraints.maxHeight;
              
              return SizedBox(
                width: width,
                height: height,
                child: child,
              );
            },
          ),
        );
      },
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
