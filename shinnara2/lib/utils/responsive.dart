import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  static T responsive<T>(BuildContext context, {required T mobile, T? tablet, required T desktop}) {
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
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static double getResponsiveFontSize(BuildContext context, {required double baseFontSize}) {
    return responsive<double>(
      context,
      mobile: baseFontSize * 1.35, // 50% 증가 (기존 0.9 * 1.5)
      tablet: baseFontSize * 1.5, // 50% 증가
      desktop: baseFontSize * 1.1,
    );
  }

  static double getResponsivePadding(BuildContext context) {
    return responsive<double>(context, mobile: 8.0, tablet: 16.0, desktop: 24.0);
  }

  static double getResponsiveMargin(BuildContext context) {
    return responsive<double>(context, mobile: 4.0, tablet: 8.0, desktop: 16.0);
  }

  static int getSeatGridCount(BuildContext context) {
    return responsive<int>(context, mobile: 4, tablet: 6, desktop: 8);
  }

  static double getSeatSize(BuildContext context) {
    return responsive<double>(context, mobile: 60.0, tablet: 70.0, desktop: 80.0);
  }
}
