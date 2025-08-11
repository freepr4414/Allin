import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';
import '../providers/lock_state_provider.dart';
import 'seat_render_widget.dart';

/// 좌석 배치도 캔버스 위젯
class SeatCanvasWidget extends ConsumerStatefulWidget {
  final SeatLayoutData layoutData;
  final void Function(Seat) onSeatTap;
  final void Function(Seat, DragUpdateDetails) onSeatDrag;

  const SeatCanvasWidget({
    super.key,
    required this.layoutData,
    required this.onSeatTap,
    required this.onSeatDrag,
  });

  @override
  ConsumerState<SeatCanvasWidget> createState() => SeatCanvasWidgetState();
}

class SeatCanvasWidgetState extends ConsumerState<SeatCanvasWidget> {
  double _canvasOffsetX = 0;
  double _canvasOffsetY = 0;
  bool _isDraggingCanvas = false;
  Offset? _lastPanPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // 배치도 영역
          Positioned(
            top: widget.layoutData.top + _canvasOffsetY,
            left: widget.layoutData.left + _canvasOffsetX,
            child: Container(
              width: widget.layoutData.width,
              height: widget.layoutData.height,
              decoration: BoxDecoration(
                color: widget.layoutData.backgroundColor,
                border: Border.all(
                  color: widget.layoutData.borderColor,
                  width: SeatLayoutConstants.borderWidth,
                ),
              ),
              child: Stack(
                children: widget.layoutData.seats.map((seat) => _buildSeatWidget(seat)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 팬 시작 처리
  void _handlePanStart(DragStartDetails details) {
    // 배치도 이동 잠금 확인
    final layoutMoveLock = ref.read(layoutMoveLockProvider);
    if (layoutMoveLock) return; // 잠금 상태면 배치도 드래그 무시
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset local = box.globalToLocal(details.globalPosition);
    bool hitSeat = false;

    for (final seat in widget.layoutData.seats) {
      final seatRect = Rect.fromLTWH(
        widget.layoutData.left + _canvasOffsetX + seat.x,
        widget.layoutData.top + _canvasOffsetY + seat.y,
        seat.width,
        seat.height,
      );
      if (seatRect.contains(local)) {
        hitSeat = true;
        break;
      }
    }

    if (!hitSeat) {
      _isDraggingCanvas = true;
      _lastPanPosition = local;
    }
  }

  /// 팬 업데이트 처리
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDraggingCanvas && _lastPanPosition != null) {
      setState(() {
        _canvasOffsetX += details.delta.dx;
        _canvasOffsetY += details.delta.dy;
      });
    }
  }

  /// 팬 종료 처리
  void _handlePanEnd(DragEndDetails details) {
    _isDraggingCanvas = false;
    _lastPanPosition = null;
  }

  /// 좌석 위젯 생성
  Widget _buildSeatWidget(Seat seat) {
    return SeatRenderWidget(
      seat: seat,
      onTap: () => widget.onSeatTap(seat),
      onPanUpdate: (details) => widget.onSeatDrag(seat, details),
    );
  }

  /// 캔버스 위치 리셋
  void resetCanvasPosition() {
    setState(() {
      _canvasOffsetX = 0;
      _canvasOffsetY = 0;
    });
  }
}
