import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/font_size_provider.dart';
import 'responsive.dart';

/// 폰트 크기를 관리하는 반응형 유틸리티 클래스
class ResponsiveFont {
  /// 폰트 크기 설정을 고려한 반응형 폰트 크기 반환
  static double getResponsiveFontSize(
    BuildContext context,
    WidgetRef ref, {
    required double baseFontSize,
  }) {
    // 기존 반응형 폰트 크기 계산
    final responsiveSize = Responsive.getResponsiveFontSize(
      context,
      baseFontSize: baseFontSize,
    );

    // 사용자 설정 폰트 크기 적용
    final fontSizeNotifier = ref.read(fontSizeProvider.notifier);
    final adjustedSize = fontSizeNotifier.getResponsiveFontSize(responsiveSize);

    return adjustedSize;
  }

  /// 간단한 폰트 크기 반환 (반응형 적용 없이)
  static double getBaseFontSize(WidgetRef ref, {required double baseFontSize}) {
    final fontSizeNotifier = ref.read(fontSizeProvider.notifier);
    return fontSizeNotifier.getResponsiveFontSize(baseFontSize);
  }

  /// 텍스트 스타일에 폰트 크기 적용
  static TextStyle? applyFontSize(
    BuildContext context,
    WidgetRef ref,
    TextStyle? originalStyle, {
    double? baseFontSize,
  }) {
    if (originalStyle == null) return null;

    final fontSize = baseFontSize ?? originalStyle.fontSize ?? 14.0;
    final adjustedSize = getResponsiveFontSize(
      context,
      ref,
      baseFontSize: fontSize,
    );

    return originalStyle.copyWith(fontSize: adjustedSize);
  }
}

/// ConsumerWidget에서 쉽게 사용할 수 있는 폰트 크기 확장
extension ResponsiveFontExtension on WidgetRef {
  /// 반응형 폰트 크기 반환
  double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
  }) {
    return ResponsiveFont.getResponsiveFontSize(
      context,
      this,
      baseFontSize: baseFontSize,
    );
  }

  /// 기본 폰트 크기 반환
  double getBaseFontSize({required double baseFontSize}) {
    return ResponsiveFont.getBaseFontSize(this, baseFontSize: baseFontSize);
  }

  /// 텍스트 스타일에 폰트 크기 적용
  TextStyle? applyFontSize(
    BuildContext context,
    TextStyle? style, {
    double? baseFontSize,
  }) {
    return ResponsiveFont.applyFontSize(
      context,
      this,
      style,
      baseFontSize: baseFontSize,
    );
  }
}
