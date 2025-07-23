import 'package:flutter_riverpod/flutter_riverpod.dart';

// 현재 활성화된 화면을 관리하는 프로바이더
final currentScreenProvider = StateNotifierProvider<CurrentScreenNotifier, String>((ref) {
  return CurrentScreenNotifier();
});

class CurrentScreenNotifier extends StateNotifier<String> {
  CurrentScreenNotifier() : super('seat_layout'); // 기본 화면을 좌석 배치도로 설정

  void navigateTo(String screenId) {
    state = screenId;
  }

  void reset() {
    state = 'seat_layout';
  }
}
