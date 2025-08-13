import 'package:flutter/material.dart';

import '../models/unified_menu_models.dart';

/// 앱 전체 상수 관리
class AppConstants {
  // ============ 디자인 상수 ============
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultMargin = 16.0;
  static const double smallMargin = 8.0;
  static const double largeMargin = 24.0;

  static const double cardElevation = 2.0;
  static const double modalElevation = 8.0;

  static const double borderRadius = 12.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  static const double iconSizeMedium = 24.0;
  static const double defaultIconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;

  // ============ 색상 상수 ============
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color shadowColor = Color(0x1A000000);

  // ============ 애니메이션 상수 ============
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceInCurve = Curves.bounceIn;
  static const Curve bounceOutCurve = Curves.bounceOut;

  // ============ 반응형 브레이크포인트 ============
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  // ============ 앱 최소/최대 크기 ============
  static const double minAppWidth = 800.0;
  static const double minAppHeight = 600.0;
  static const double defaultAppWidth = 1200.0;
  static const double defaultAppHeight = 800.0;

  // ============ 레이아웃 상수 ============
  static const double headerHeight = 60.0;
  static const double sidebarWidth = 450.0;
  static const double footerHeight = 40.0;
  static const double dropdownWidth = 220.0;

  // ============ 폰트 크기 ============
  static const double smallFontSize = 12.0;
  static const double normalFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 24.0;
  static const double titleFontSize = 32.0;

  // ============ 반응형 폰트 크기 ============
  static const double mobileFontSize = 10.0;
  static const double tabletFontSize = 12.0;
  static const double desktopFontSize = 14.0;

  // ============ 반응형 패딩 ============
  static const double mobilePadding = 8.0;
  static const double tabletPadding = 16.0;
  static const double desktopPadding = 24.0;

  // ============ 반응형 마진 ============
  static const double mobileMargin = 4.0;
  static const double tabletMargin = 8.0;
  static const double desktopMargin = 16.0;

  // ============ 반응형 아이콘 크기 ============
  static const double mobileIconSize = 20.0;
  static const double tabletIconSize = 24.0;
  static const double desktopIconSize = 28.0;

  // ============ 그리드 및 배치 ============
  static const double gridSize = 50.0;
  static const double popupWidth = 200.0;
  static const double popupHeight = 432.0;

  // ============ 화면 크기 임계값 ============
  static const double smallScreenWidth = 800.0;
  static const double smallScreenHeight = 600.0;

  // ============ 권한 레벨 표시명 ============
  static const Map<PermissionLevel, String> permissionNames = {
    PermissionLevel.level1: '최고관리자',
    PermissionLevel.level2: '상급관리자',
    PermissionLevel.level3: '중급관리자',
    PermissionLevel.level4: '일반직원',
    PermissionLevel.level5: '제한된직원',
  };

  static const Map<PermissionLevel, Color> permissionColors = {
    PermissionLevel.level1: Colors.red,
    PermissionLevel.level2: Colors.orange,
    PermissionLevel.level3: Colors.blue,
    PermissionLevel.level4: Colors.green,
    PermissionLevel.level5: Colors.grey,
  };

  // ============ 메시지 상수 ============
  static const int snackBarDuration = 3; // 초
  static const int shortSnackBarDuration = 1; // 초
  static const int longSnackBarDuration = 5; // 초

  // ============ 네트워크 상수 ============
  static const int apiTimeoutSeconds = 30;
  static const int retryAttempts = 3;

  // ============ 로컬 스토리지 키 ============
  static const String userPrefsKey = 'user_preferences';
  static const String themePrefsKey = 'theme_preferences';
  static const String languagePrefsKey = 'language_preferences';

  // ============ 테이블 설정 ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============ 차트 설정 ============
  static const double chartHeight = 300.0;
  static const double smallChartHeight = 200.0;
  static const double largeChartHeight = 400.0;
}
