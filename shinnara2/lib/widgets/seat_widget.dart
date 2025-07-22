import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../providers/seat_provider.dart';

class SeatWidget extends ConsumerWidget {
  final Seat seat;
  final double size;
  final VoidCallback? onTap;

  const SeatWidget({super.key, required this.seat, this.size = 60.0, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(seatProvider.notifier).selectSeat(seat.id);
        onTap?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getSeatColor(seat.status),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seat.isSelected
                ? Theme.of(context).primaryColor
                : _getSeatBorderColor(seat.status),
            width: seat.isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (seat.isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 좌석 번호
            Text(
              seat.number,
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
                color: _getTextColor(seat.status),
              ),
            ),

            // 좌석 타입 아이콘
            Icon(
              _getSeatTypeIcon(seat.type),
              size: size * 0.2,
              color: _getTextColor(seat.status).withValues(alpha: 0.7),
            ),

            // 남은 시간 (사용 중인 경우)
            if (seat.status == SeatStatus.occupied && seat.remainingMinutes != null)
              Text(
                _formatTime(seat.remainingMinutes!),
                style: TextStyle(
                  fontSize: size * 0.12,
                  color: _getTextColor(seat.status).withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeatColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.green[100]!;
      case SeatStatus.occupied:
        return Colors.red[100]!;
      case SeatStatus.reserved:
        return Colors.blue[100]!;
      case SeatStatus.maintenance:
        return Colors.orange[100]!;
      case SeatStatus.outOfOrder:
        return Colors.grey[300]!;
      case SeatStatus.cleaning:
        return Colors.purple[100]!;
    }
  }

  Color _getSeatBorderColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.green[300]!;
      case SeatStatus.occupied:
        return Colors.red[300]!;
      case SeatStatus.reserved:
        return Colors.blue[300]!;
      case SeatStatus.maintenance:
        return Colors.orange[300]!;
      case SeatStatus.outOfOrder:
        return Colors.grey[500]!;
      case SeatStatus.cleaning:
        return Colors.purple[300]!;
    }
  }

  Color _getTextColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.green[800]!;
      case SeatStatus.occupied:
        return Colors.red[800]!;
      case SeatStatus.reserved:
        return Colors.blue[800]!;
      case SeatStatus.maintenance:
        return Colors.orange[800]!;
      case SeatStatus.outOfOrder:
        return Colors.grey[700]!;
      case SeatStatus.cleaning:
        return Colors.purple[800]!;
    }
  }

  IconData _getSeatTypeIcon(SeatType type) {
    switch (type) {
      case SeatType.standard:
        return Icons.chair;
      case SeatType.premium:
        return Icons.chair_outlined;
      case SeatType.study:
        return Icons.desk;
      case SeatType.meeting:
        return Icons.meeting_room;
    }
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '${hours}h${mins}m';
    } else {
      return '${mins}m';
    }
  }
}
