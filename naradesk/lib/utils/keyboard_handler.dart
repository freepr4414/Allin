import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../providers/lock_state_provider.dart';
import '../providers/seat_layout_provider.dart';

/// 키보드 이벤트 핸들러를 제공하는 프로바이더
final keyboardHandlerProvider = Provider<KeyboardHandler>((ref) {
  return KeyboardHandler(ref);
});

/// Ctrl 키 상태를 추적하는 프로바이더
final ctrlKeyStateProvider = StateProvider<bool>((ref) => false);

/// 이동간격을 관리하는 프로바이더
final moveStepProvider = StateProvider<double>((ref) => SeatLayoutConstants.moveStep);

/// 키보드 이벤트 핸들러 클래스
class KeyboardHandler {
  final Ref ref;

  KeyboardHandler(this.ref);

  /// 키보드 이벤트 처리
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    // Ctrl 키 상태 업데이트
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    ref.read(ctrlKeyStateProvider.notifier).state = isCtrlPressed;

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrlPressed && !isShiftPressed) {
      return _handleMoveKeys(event);
    } else if (isShiftPressed && !isCtrlPressed) {
      return _handleResizeKeys(event);
    }

    return KeyEventResult.ignored;
  }

  /// 이동 키 처리 (Ctrl + 방향키)
  KeyEventResult _handleMoveKeys(KeyEvent event) {
    // 좌석 배치 변경 잠금 확인
    final seatEditLock = ref.read(seatEditLockProvider);
    if (seatEditLock) return KeyEventResult.ignored; // 잠금 상태면 무시
    
    final step = ref.read(moveStepProvider); // 설정된 이동간격 사용

    // 배치도는 항상 rotation = 0이므로 단순한 이동 처리
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        ref.read(seatLayoutProvider.notifier).moveSelectedSeats(-step, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        ref.read(seatLayoutProvider.notifier).moveSelectedSeats(step, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        ref.read(seatLayoutProvider.notifier).moveSelectedSeats(0, -step);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        ref.read(seatLayoutProvider.notifier).moveSelectedSeats(0, step);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  /// 크기 조절 키 처리 (Shift + 방향키)
  KeyEventResult _handleResizeKeys(KeyEvent event) {
    // 좌석 배치 변경 잠금 확인
    final seatEditLock = ref.read(seatEditLockProvider);
    if (seatEditLock) return KeyEventResult.ignored; // 잠금 상태면 무시
    
    const step = SeatLayoutConstants.resizeStep;

    // 배치도는 항상 rotation = 0이므로 단순한 크기 조절 처리
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        ref.read(seatLayoutProvider.notifier).resizeSelectedSeats(-step, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        ref.read(seatLayoutProvider.notifier).resizeSelectedSeats(step, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        ref.read(seatLayoutProvider.notifier).resizeSelectedSeats(0, -step);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        ref.read(seatLayoutProvider.notifier).resizeSelectedSeats(0, step);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}
