import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

/// 통일된 위젯 테마 시스템
class AppTheme {
  // ============ 라이트 테마 ============
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),

    // 앱바 테마
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppConstants.shadowColor,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // 카드 테마
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: AppConstants.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),

    // 버튼 테마들
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppStyles.primaryButton),

    outlinedButtonTheme: OutlinedButtonThemeData(style: AppStyles.outlineButton),

    textButtonTheme: TextButtonThemeData(style: AppStyles.textButton),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: AppConstants.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
    ),

    // 텍스트 테마
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),

    // 아이콘 테마
    iconTheme: IconThemeData(color: AppConstants.textPrimary, size: AppConstants.iconSizeMedium),

    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),

    // 라디오 테마
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return AppConstants.textSecondary;
      }),
    ),

    // 스위치 테마
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return AppConstants.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor.withValues(alpha: 0.3);
        }
        return AppConstants.textSecondary.withValues(alpha: 0.3);
      }),
    ),

    // 슬라이더 테마
    sliderTheme: SliderThemeData(
      activeTrackColor: AppConstants.primaryColor,
      inactiveTrackColor: AppConstants.primaryColor.withValues(alpha: 0.3),
      thumbColor: AppConstants.primaryColor,
      overlayColor: AppConstants.primaryColor.withValues(alpha: 0.2),
    ),

    // 탭 테마
    tabBarTheme: TabBarThemeData(
      labelColor: AppConstants.primaryColor,
      unselectedLabelColor: AppConstants.textSecondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
    ),

    // 다이얼로그 테마
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      elevation: 8,
      shadowColor: AppConstants.shadowColor,
    ),

    // 스낵바 테마
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppConstants.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      behavior: SnackBarBehavior.floating,
    ),

    // 플로팅 액션 버튼 테마
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),

    // 바텀 네비게이션 바 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppConstants.primaryColor,
      unselectedItemColor: AppConstants.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // 네비게이션 레일 테마
    navigationRailTheme: NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: AppConstants.primaryColor),
      unselectedIconTheme: IconThemeData(color: AppConstants.textSecondary),
      selectedLabelTextStyle: TextStyle(color: AppConstants.primaryColor),
      unselectedLabelTextStyle: TextStyle(color: AppConstants.textSecondary),
    ),

    // 드로어 테마
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: AppConstants.shadowColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    ),

    // 리스트 타일 테마
    listTileTheme: ListTileThemeData(
      selectedTileColor: AppConstants.primaryColor.withValues(alpha: 0.1),
      selectedColor: AppConstants.primaryColor,
      iconColor: AppConstants.textSecondary,
      textColor: AppConstants.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),

    // 칩 테마
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.backgroundSecondary,
      selectedColor: AppConstants.primaryColor,
      disabledColor: AppConstants.textSecondary.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: AppConstants.textPrimary),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),

    // 툴팁 테마
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppConstants.textPrimary,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      textStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // 프로그레스 인디케이터 테마
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppConstants.primaryColor,
      linearTrackColor: AppConstants.primaryColor.withValues(alpha: 0.3),
      circularTrackColor: AppConstants.primaryColor.withValues(alpha: 0.3),
    ),
  );

  // ============ 다크 테마 ============
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    ),

    // 앱바 테마
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black54,
      titleTextStyle: AppStyles.titleLarge.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // 카드 테마
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black54,
      color: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),

    // 버튼 테마들
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppStyles.primaryButton.copyWith(
        backgroundColor: WidgetStateProperty.all(AppConstants.primaryColor),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppStyles.outlineButton.copyWith(
        foregroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.white70)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: AppStyles.textButton.copyWith(foregroundColor: WidgetStateProperty.all(Colors.white)),
    ),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: AppConstants.primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
    ),

    // 텍스트 테마
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: Colors.white),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: Colors.white),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: Colors.white),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
    ),

    // 아이콘 테마
    iconTheme: const IconThemeData(color: Colors.white, size: AppConstants.iconSizeMedium),

    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Colors.white70),
    ),

    // 라디오 테마
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.white70;
      }),
    ),

    // 스위치 테마
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.white70;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor.withValues(alpha: 0.3);
        }
        return Colors.white24;
      }),
    ),

    // 스낵바 테마
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2C2C2C),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      behavior: SnackBarBehavior.floating,
    ),

    // 다이얼로그 테마
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      elevation: 8,
      shadowColor: Colors.black54,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
    ),

    // 바텀 네비게이션 바 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: AppConstants.primaryColor,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // 리스트 타일 테마
    listTileTheme: ListTileThemeData(
      selectedTileColor: AppConstants.primaryColor.withValues(alpha: 0.2),
      selectedColor: AppConstants.primaryColor,
      iconColor: Colors.white70,
      textColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
    ),
  );

  // ============ 테마 상태 확인 ============
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============ 동적 색상 생성 ============
  static Color getContrastColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : Colors.black;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
  }

  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF2C2C2C) : Colors.white;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF2C2C2C) : AppConstants.backgroundSecondary;
  }

  static Color getBorderColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white30 : Colors.black12;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : AppConstants.textPrimary;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white70 : AppConstants.textSecondary;
  }

  static Color getDisabledColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white38 : Colors.black38;
  }
}
