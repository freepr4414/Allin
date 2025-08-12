import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

/// 폰트 크기 상태 관리
class FontSizeNotifier extends StateNotifier<FontSizeLevel> {
  FontSizeNotifier() : super(FontSizeLevel.normal);

  void setFontSizeLevel(FontSizeLevel level) {
    state = level;
  }

  /// 현재 폰트 크기 레벨 가져오기
  FontSizeLevel get currentLevel => state;

  /// 스케일된 폰트 크기 계산
  double getScaledFontSize(double baseSize) {
    return state.getScaledSize(baseSize);
  }
}

/// 폰트 크기 Provider
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSizeLevel>(
  (ref) => FontSizeNotifier(),
);

/// 현재 폰트 크기 레벨 Provider
final currentFontSizeLevelProvider = Provider<FontSizeLevel>((ref) {
  return ref.watch(fontSizeProvider);
});

/// 반응형 폰트 크기 계산 Provider
final responsiveFontSizeProvider = Provider.family<double, double>((
  ref,
  baseSize,
) {
  final fontSizeLevel = ref.watch(fontSizeProvider);
  return fontSizeLevel.getScaledSize(baseSize);
});

/// 반응형 폰트 크기 확장 메서드를 위한 헬퍼
extension ResponsiveFontSize on WidgetRef {
  double getResponsiveFontSize(double baseSize) {
    return read(responsiveFontSizeProvider(baseSize));
  }
}
