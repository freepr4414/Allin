import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 설정 팝업의 표시 여부를 관리하는 프로바이더 (로그 추가)
final settingsPopupVisibilityProvider = StateProvider<bool>((ref) {
  print('🎨 [SETTINGS_POPUP_PROVIDER] 초기값 설정: false');
  return false;
});
