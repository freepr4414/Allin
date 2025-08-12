import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

/// 테마 모드 상태 관리
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light);

  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }
}

/// 테마 색상 상태 관리
class ThemeColorNotifier extends StateNotifier<AppThemeColor> {
  ThemeColorNotifier() : super(AppThemeColor.blue);

  void setThemeColor(AppThemeColor color) {
    state = color;
  }
}

/// 테마 모드 Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
      (ref) => ThemeModeNotifier(),
    );

/// 테마 색상 Provider
final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, AppThemeColor>(
      (ref) => ThemeColorNotifier(),
    );

/// 현재 테마 모드 Provider
final currentThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeModeProvider);
});

/// 현재 테마 색상 Provider
final currentThemeColorProvider = Provider<AppThemeColor>((ref) {
  return ref.watch(themeColorProvider);
});
