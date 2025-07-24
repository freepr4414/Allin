import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';

/// 개별 좌석 렌더링 위젯
class SeatRenderWidget extends ConsumerWidget {
  final Seat seat;
  final VoidCallback? onTap;
  final void Function(DragUpdateDetails)? onPanUpdate;

  const SeatRenderWidget({super.key, required this.seat, this.onTap, this.onPanUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: seat.x,
      top: seat.y,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: onPanUpdate,
        child: Transform.rotate(
          angle: seat.rotation * (3.14159 / 180),
          child: Container(
            width: seat.width,
            height: seat.height,
            decoration: BoxDecoration(
              color: seat.backgroundColor,
              border: Border.all(
                color: seat.isSelected ? Colors.blue.shade800 : Colors.black,
                width: seat.isSelected ? SeatLayoutConstants.selectedBorderWidth : 1,
              ),
            ),
            child: Center(
              child: Text(
                seat.number,
                style: const TextStyle(
                  color: SeatLayoutConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
