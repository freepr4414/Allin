import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../providers/seat_layout_provider.dart';

/// 키보드 이벤트 핸들러를 제공하는 프로바이더
final keyboardHandlerProvider = Provider<KeyboardHandler>((ref) {
  return KeyboardHandler(ref);
});

/// 키보드 이벤트 핸들러 클래스
class KeyboardHandler {
  final Ref ref;

  KeyboardHandler(this.ref);

  /// 키보드 이벤트 처리
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
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
    const step = SeatLayoutConstants.moveStep;

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
    const step = SeatLayoutConstants.resizeStep;

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
