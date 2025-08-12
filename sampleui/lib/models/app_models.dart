import 'package:flutter/material.dart';

/// 폰트 크기 레벨 열거형
enum FontSizeLevel {
  small(1, '작게', 0.8),
  normal(2, '보통', 1.0),
  medium(3, '중간', 1.2),
  large(4, '크게', 1.4),
  extraLarge(5, '매우 크게', 1.6);

  const FontSizeLevel(this.level, this.displayName, this.scaleFactor);

  final int level;
  final String displayName;
  final double scaleFactor;

  /// 기본 폰트 크기에 스케일 팩터를 적용
  double getScaledSize(double baseSize) => baseSize * scaleFactor;
}

/// 테마 모드 열거형
enum AppThemeMode {
  light('라이트 모드'),
  dark('다크 모드'),
  system('시스템 설정');

  const AppThemeMode(this.displayName);

  final String displayName;
}

/// 테마 색상 열거형
enum AppThemeColor {
  blue('파란색', 0xFF2196F3),
  purple('보라색', 0xFF9C27B0),
  green('초록색', 0xFF4CAF50),
  orange('주황색', 0xFFFF9800),
  red('빨간색', 0xFFF44336),
  teal('청록색', 0xFF009688),
  indigo('남색', 0xFF3F51B5),
  pink('분홍색', 0xFFE91E63);

  const AppThemeColor(this.displayName, this.colorValue);

  final String displayName;
  final int colorValue;

  /// Color 객체로 변환
  Color get color => Color(colorValue);
}
