import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// 반응형 디자인 표준화 위젯
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final double? mobileBreakpoint;
  final double? tabletBreakpoint;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.mobileBreakpoint,
    this.tabletBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobileMax = mobileBreakpoint ?? AppConstants.mobileBreakpoint;
        final tabletMax = tabletBreakpoint ?? AppConstants.tabletBreakpoint;

        if (width < mobileMax) {
          return mobile;
        } else if (width < tabletMax) {
          return tablet ?? desktop;
        } else {
          return desktop;
        }
      },
    );
  }

  /// 반응형 값 반환 헬퍼
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
    double? mobileBreakpoint,
    double? tabletBreakpoint,
  }) {
    final width = MediaQuery.of(context).size.width;
    final mobileMax = mobileBreakpoint ?? AppConstants.mobileBreakpoint;
    final tabletMax = tabletBreakpoint ?? AppConstants.tabletBreakpoint;

    if (width < mobileMax) {
      return mobile;
    } else if (width < tabletMax) {
      return tablet ?? desktop;
    } else {
      return desktop;
    }
  }

  /// 현재 디바이스 타입 반환
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < AppConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < AppConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 모바일 여부 확인
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// 태블릿 여부 확인
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// 데스크톱 여부 확인
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// 작은 화면 여부 확인 (모바일 + 태블릿)
  static bool isSmallScreen(BuildContext context) {
    return !isDesktop(context);
  }
}

/// 디바이스 타입 열거형
enum DeviceType { mobile, tablet, desktop }

/// 반응형 패딩 위젯
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({super.key, required this.child, this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveBuilder.responsive<EdgeInsets>(
      context,
      mobile: mobile ?? EdgeInsets.all(AppConstants.smallPadding),
      tablet: tablet ?? EdgeInsets.all(AppConstants.defaultPadding),
      desktop: desktop ?? EdgeInsets.all(AppConstants.defaultPadding),
    );

    return Padding(padding: padding, child: child);
  }
}

/// 반응형 여백 위젯
class ResponsiveMargin extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsiveMargin({super.key, required this.child, this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    final margin = ResponsiveBuilder.responsive<EdgeInsets>(
      context,
      mobile: mobile ?? EdgeInsets.all(AppConstants.smallMargin),
      tablet: tablet ?? EdgeInsets.all(AppConstants.defaultMargin),
      desktop: desktop ?? EdgeInsets.all(AppConstants.defaultMargin),
    );

    return Container(margin: margin, child: child);
  }
}

/// 반응형 폰트 크기 위젯
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveBuilder.responsive<double>(
      context,
      mobile: mobileFontSize ?? AppConstants.mobileFontSize,
      tablet: tabletFontSize ?? AppConstants.tabletFontSize,
      desktop: desktopFontSize ?? AppConstants.desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 반응형 컨테이너 위젯
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveBuilder.responsive<double?>(
      context,
      mobile: mobileWidth,
      tablet: tabletWidth,
      desktop: desktopWidth,
    );

    final height = ResponsiveBuilder.responsive<double?>(
      context,
      mobile: mobileHeight,
      tablet: tabletHeight,
      desktop: desktopHeight,
    );

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}
