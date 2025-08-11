import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 폰트 크기 단계 (1-5)
enum FontSizeLevel {
  level1(12.0, '매우 작게'),
  level2(14.0, '작게'),
  level3(16.0, '보통'),
  level4(18.0, '크게'),
  level5(20.0, '매우 크게');

  const FontSizeLevel(this.baseSize, this.displayName);

  final double baseSize;
  final String displayName;
}

/// 폰트 크기 상태 클래스
class FontSizeState {
  final FontSizeLevel currentLevel;

  const FontSizeState({
    this.currentLevel = FontSizeLevel.level2, // 기본값을 2단계로 설정
  });

  FontSizeState copyWith({FontSizeLevel? currentLevel}) {
    return FontSizeState(currentLevel: currentLevel ?? this.currentLevel);
  }
}

/// 폰트 크기 노티파이어
class FontSizeNotifier extends StateNotifier<FontSizeState> {
  FontSizeNotifier() : super(const FontSizeState()) {
    _loadSavedFontSize();
  }

  /// 저장된 폰트 크기 로드
  Future<void> _loadSavedFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt('font_size_level') ?? 2; // 기본값 2단계

      final fontLevel = FontSizeLevel.values.firstWhere(
        (level) => level.index + 1 == savedLevel,
        orElse: () => FontSizeLevel.level2,
      );

      state = state.copyWith(currentLevel: fontLevel);
    } catch (e) {
      // 에러 발생 시 기본값 유지
      state = state.copyWith(currentLevel: FontSizeLevel.level2);
    }
  }

  /// 폰트 크기 변경
  Future<void> setFontSizeLevel(FontSizeLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('font_size_level', level.index + 1);

      state = state.copyWith(currentLevel: level);
    } catch (e) {
      // 에러 처리
      print('폰트 크기 저장 실패: $e');
    }
  }

  /// 현재 기본 폰트 크기 반환
  double get currentBaseSize => state.currentLevel.baseSize;

  /// 반응형 폰트 크기 계산 (기본 크기에 배율 적용)
  double getResponsiveFontSize(double baseFontSize) {
    final ratio =
        currentBaseSize /
        FontSizeLevel.level3.baseSize; // level3(보통)을 기준으로 비율 계산
    return baseFontSize * ratio;
  }
}

/// 폰트 크기 프로바이더
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSizeState>(
  (ref) {
    return FontSizeNotifier();
  },
);

/// 현재 폰트 크기 레벨 프로바이더 (편의용)
final currentFontSizeLevelProvider = Provider<FontSizeLevel>((ref) {
  return ref.watch(fontSizeProvider).currentLevel;
});

/// 현재 기본 폰트 크기 프로바이더 (편의용)
final currentBaseFontSizeProvider = Provider<double>((ref) {
  return ref.watch(
    fontSizeProvider.select((state) => state.currentLevel.baseSize),
  );
});
