import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 테마 모드 (라이트/다크)
enum AppThemeMode {
  light('light', '라이트 모드', Icons.light_mode),
  dark('dark', '다크 모드', Icons.dark_mode);

  const AppThemeMode(this.name, this.displayName, this.icon);

  final String name;
  final String displayName;
  final IconData icon;
}

/// 앱 테마 컬러 (8가지)
enum AppThemeColor {
  blue('blue', '블루', Colors.blue),
  green('green', '그린', Colors.green),
  orange('orange', '오렌지', Colors.orange),
  red('red', '레드', Colors.red),
  purple('purple', '퍼플', Colors.purple),
  teal('teal', '틸', Colors.teal),
  pink('pink', '핑크', Colors.pink),
  indigo('indigo', '인디고', Colors.indigo);

  const AppThemeColor(this.name, this.displayName, this.color);

  final String name;
  final String displayName;
  final Color color;
}

/// 테마 상태 클래스
class ThemeState {
  final AppThemeMode themeMode;
  final AppThemeColor themeColor;

  const ThemeState({
    this.themeMode = AppThemeMode.light,
    this.themeColor = AppThemeColor.blue,
  });

  ThemeState copyWith({AppThemeMode? themeMode, AppThemeColor? themeColor}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

/// 테마 노티파이어
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadSavedTheme();
  }

  /// 저장된 테마 설정 로드
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 테마 모드 로드
      final savedMode = prefs.getString('theme_mode') ?? 'light';
      final themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => AppThemeMode.light,
      );

      // 테마 컬러 로드
      final savedColor = prefs.getString('theme_color') ?? 'blue';
      final themeColor = AppThemeColor.values.firstWhere(
        (color) => color.name == savedColor,
        orElse: () => AppThemeColor.blue,
      );

      state = state.copyWith(themeMode: themeMode, themeColor: themeColor);
    } catch (e) {
      // 에러 발생 시 기본값 유지
      state = const ThemeState();
    }
  }

  /// 테마 모드 변경
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
      state = state.copyWith(themeMode: mode);
    } catch (e) {
      // 테마 모드 저장 실패 시 에러 처리
    }
  }

  /// 테마 컬러 변경
  Future<void> setThemeColor(AppThemeColor color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_color', color.name);
      state = state.copyWith(themeColor: color);
    } catch (e) {
      // 테마 컬러 저장 실패 시 에러 처리
    }
  }

  /// 현재 테마 데이터 생성
  ThemeData get lightTheme {
    // 커스텀 ColorScheme으로 텍스트 색상 강제 설정
    final colorScheme = ColorScheme.light(
      primary: state.themeColor.color,
      secondary: state.themeColor.color.withValues(alpha: 0.7),
      surface: Colors.white, // 더 밝은 surface로 배경과 대비
      surfaceContainer: Colors.grey[100], // 설정 패널 일반 배경
      surfaceContainerLow: Colors.grey[50], // 설정 패널 낮은 강조 배경
      surfaceContainerHigh: Colors.grey[200], // 설정 패널 높은 강조 배경
      surfaceContainerHighest: Colors.grey[300], // 설정 패널 최고 강조 배경 (하단바 등)
      // 텍스트 색상을 명시적으로 검은색으로 강제 설정
      onSurface: Colors.black87,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      // 모든 텍스트 관련 색상을 검은색으로 설정
      onError: Colors.black87,
      onTertiary: Colors.black87,
      tertiary: state.themeColor.color.withValues(alpha: 0.5),
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[350], // 더 어두운 배경색으로 변경하여 구분성 향상
      // 텍스트 테마: 기본 M3 값 사용 (개별 위젯에서 colorScheme.onSurface 활용)
      // 앱바 테마 설정
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
      // 기타 컴포넌트 테마
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        backgroundColor: colorScheme.surface,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );

    // (디버그 로그 제거됨)

    return theme;
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: state.themeColor.color,  // 원본 색상 그대로 사용
      secondary: state.themeColor.color.withValues(alpha: 0.7),
      tertiary: state.themeColor.color.withValues(alpha: 0.5),
      surface: Colors.grey[850]!,
      surfaceContainer: Colors.grey[850]!, // 설정 패널 일반 배경
      surfaceContainerLow: Colors.grey[900]!, // 설정 패널 낮은 강조 배경
      surfaceContainerHigh: Colors.grey[800]!, // 설정 패널 높은 강조 배경
      surfaceContainerHighest: Colors.grey[700]!, // 설정 패널 최고 강조 배경 (하단바 등)
      onSurface: Colors.white70,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white70,
      onTertiary: Colors.white70,
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[900], // 다크 모드용 어두운 배경색
      // 텍스트 테마: 기본 M3 사용
      // 앱바 테마 설정
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
    );

    // (디버그 로그 제거됨)

    return theme;
  }
}

/// 테마 프로바이더
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

/// 현재 테마 모드 프로바이더 (편의용)
final currentThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// 현재 테마 컬러 프로바이더 (편의용)
final currentThemeColorProvider = Provider<AppThemeColor>((ref) {
  return ref.watch(themeProvider).themeColor;
});
