import 'package:flutter/material.dart';

/// 폰트 및 테마 관련 유틸리티
class FontThemeUtils {
  /// 폰트크기 설정에 따른 텍스트 테마 생성
  static TextTheme buildTextTheme(double baseFontSize, {bool isDark = false}) {
    final ratio = baseFontSize / 16.0; // 기본 16px 기준으로 비율 계산
    
    // 밝기 기준 기본 색을 Material Design에 맞게 설정
    final baseColor = isDark
        ? const Color(0xFFFFFFFF) // 다크 모드: 흰색
        : const Color(0xFF1A1A1A); // 라이트 모드: 진한 회색

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

  /// 테마 모드에 따른 기본 텍스트 색상 반환
  static Color getBaseTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A1A1A);
  }

  /// 테마 모드에 따른 보조 텍스트 색상 반환
  static Color getSecondaryTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF757575);
  }

  /// 반응형 폰트 크기 계산
  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double mobileMultiplier = 1.0,
    double tabletMultiplier = 1.1,
    double desktopMultiplier = 1.1,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return baseFontSize * mobileMultiplier;
    } else if (screenWidth < 1200) {
      return baseFontSize * tabletMultiplier;
    } else {
      return baseFontSize * desktopMultiplier;
    }
  }
}
