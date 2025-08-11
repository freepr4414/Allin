import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// 앱 전체 스타일 시스템
class AppStyles {
  // ============ 색상 팔레트 ============
  static const Color primaryColor = Colors.deepPurple;
  static const Color secondaryColor = Colors.deepPurpleAccent;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color infoColor = Colors.blue;

  // ============ 텍스트 스타일 ============
  static TextStyle get titleLarge =>
      const TextStyle(fontSize: AppConstants.titleFontSize, fontWeight: FontWeight.bold);

  static TextStyle get titleMedium =>
      const TextStyle(fontSize: AppConstants.extraLargeFontSize, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      const TextStyle(fontSize: AppConstants.largeFontSize, fontWeight: FontWeight.w500);

  static TextStyle get bodyLarge =>
      const TextStyle(fontSize: AppConstants.mediumFontSize, fontWeight: FontWeight.normal);

  static TextStyle get bodyMedium =>
      const TextStyle(fontSize: AppConstants.normalFontSize, fontWeight: FontWeight.normal);

  static TextStyle get bodySmall =>
      const TextStyle(fontSize: AppConstants.smallFontSize, fontWeight: FontWeight.normal);

  static TextStyle get labelLarge =>
      const TextStyle(fontSize: AppConstants.normalFontSize, fontWeight: FontWeight.w500);

  static TextStyle get labelMedium =>
      const TextStyle(fontSize: AppConstants.smallFontSize, fontWeight: FontWeight.w500);

  // ============ 컨테이너 스타일 ============
  static BoxDecoration get cardDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: AppConstants.cardElevation * 2,
        offset: const Offset(0, AppConstants.cardElevation),
      ),
    ],
  );

  static BoxDecoration get modalDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: AppConstants.modalElevation * 2,
        offset: const Offset(0, AppConstants.modalElevation),
      ),
    ],
  );

  static BoxDecoration cardDecorationWithColor(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: AppConstants.cardElevation * 2,
        offset: const Offset(0, AppConstants.cardElevation),
      ),
    ],
  );

  // ============ 버튼 스타일 ============
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.defaultPadding,
      vertical: AppConstants.smallPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
    ),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.defaultPadding,
      vertical: AppConstants.smallPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
    ),
  );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.defaultPadding,
      vertical: AppConstants.smallPadding,
    ),
  );

  // 테마에서 참조할 수 있는 getter들 추가
  static ButtonStyle get primaryButton => primaryButtonStyle;
  static ButtonStyle get outlineButton => secondaryButtonStyle;
  static ButtonStyle get textButton => textButtonStyle;

  static ButtonStyle get iconButtonStyle =>
      IconButton.styleFrom(padding: const EdgeInsets.all(AppConstants.smallPadding));

  // ============ 입력 필드 스타일 ============
  static InputDecoration get inputDecoration => InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius)),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppConstants.defaultPadding,
      vertical: AppConstants.smallPadding,
    ),
  );

  static InputDecoration inputDecorationWithLabel(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius)),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppConstants.defaultPadding,
      vertical: AppConstants.smallPadding,
    ),
  );

  // ============ 그림자 ============
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ============ 여백 ============
  static EdgeInsets get defaultPadding => const EdgeInsets.all(AppConstants.defaultPadding);
  static EdgeInsets get smallPadding => const EdgeInsets.all(AppConstants.smallPadding);
  static EdgeInsets get largePadding => const EdgeInsets.all(AppConstants.largePadding);

  static EdgeInsets get horizontalPadding =>
      const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding);

  static EdgeInsets get verticalPadding =>
      const EdgeInsets.symmetric(vertical: AppConstants.defaultPadding);

  // ============ 테마별 스타일 헬퍼 ============
  static TextStyle titleTextStyle(BuildContext context) =>
      titleMedium.copyWith(color: Theme.of(context).colorScheme.onSurface);

  static TextStyle bodyTextStyle(BuildContext context) =>
      bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface);

  static TextStyle captionTextStyle(BuildContext context) =>
      bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7));

  static BoxDecoration cardDecorationWithTheme(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
    boxShadow: defaultShadow,
  );
}
