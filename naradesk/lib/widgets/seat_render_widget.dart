import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';
import '../providers/font_size_provider.dart';
import '../providers/lock_state_provider.dart';
import '../utils/keyboard_handler.dart';

/// 개별 좌석 렌더링 위젯
class SeatRenderWidget extends ConsumerWidget {
  final Seat seat;
  final VoidCallback? onTap;
  final void Function(DragUpdateDetails)? onPanUpdate;

  const SeatRenderWidget({
    super.key,
    required this.seat,
    this.onTap,
    this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCtrlPressed = ref.watch(ctrlKeyStateProvider);
    final seatEditLock = ref.watch(seatEditLockProvider);
    final fontSizeRatio =
        ref.watch(currentBaseFontSizeProvider) / 16.0; // 폰트크기 비율 계산

    return Positioned(
      left: seat.x,
      top: seat.y,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (isCtrlPressed && !seatEditLock)
            ? onPanUpdate
            : null, // Ctrl 키가 눌리고 잠금이 해제된 경우에만 드래그 허용
        child: Container(
          width: seat.width,
          height: seat.height,
          decoration: BoxDecoration(
            color: seat.backgroundColor,
            border: Border.all(
              color: seat.isSelected ? Colors.blue.shade800 : Colors.black,
              width: seat.isSelected
                  ? SeatLayoutConstants.selectedBorderWidth
                  : 1,
            ),
          ),
          child: Center(
            child: Text(
              seat.number,
              style: TextStyle(
                color: SeatLayoutConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: (14.0 * fontSizeRatio).clamp(
                  10.0,
                  20.0,
                ), // 폰트크기 설정 적용
              ),
            ),
          ),
        ),
      ),
    );
  }
}
