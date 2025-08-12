import 'package:flutter/material.dart';

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

  // ============ 레이아웃 상수 ============
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // ============ 사이드바 상수 ============
  static const double sidebarWidth = 300.0;
  static const double collapsedSidebarWidth = 70.0;

  // ============ 위젯 플레이그라운드 상수 ============
  static const double playgroundMinWidth = 800.0;
  static const double propertyPanelWidth = 250.0;
  static const double themePanelWidth = 300.0;
}
