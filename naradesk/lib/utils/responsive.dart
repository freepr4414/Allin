import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class ResponsiveBreakpoints {
  static const double mobile = AppConstants.mobileBreakpoint;
  static const double tablet = AppConstants.tabletBreakpoint;
  static const double desktop = AppConstants.desktopBreakpoint;
}

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    return isDesktop(context) ? desktop : (isTablet(context) ? (tablet ?? mobile) : mobile);
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
  }) {
    return responsive<double>(
      context,
      mobile: baseFontSize * 1.0, // 모바일에서는 기본 크기 사용
      tablet: baseFontSize * 1.1, // 태블릿에서 10% 증가
      desktop: baseFontSize * 1.1, // 데스크톱에서 10% 증가
    );
  }

  static double getResponsivePadding(BuildContext context) {
    return responsive<double>(
      context,
      mobile: AppConstants.mobilePadding,
      tablet: AppConstants.tabletPadding,
      desktop: AppConstants.desktopPadding,
    );
  }

  static double getResponsiveMargin(BuildContext context) {
    return responsive<double>(
      context, 
      mobile: AppConstants.mobileMargin, 
      tablet: AppConstants.tabletMargin, 
      desktop: AppConstants.desktopMargin,
    );
  }

  static int getSeatGridCount(BuildContext context) {
    return responsive<int>(context, mobile: 4, tablet: 6, desktop: 8);
  }

  static double getSeatSize(BuildContext context) {
    return responsive<double>(
      context,
      mobile: 60.0,
      tablet: 70.0,
      desktop: 80.0,
    );
  }
}
