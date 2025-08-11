import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../providers/font_size_provider.dart';
import '../providers/seat_provider.dart';

class SeatWidget extends ConsumerWidget {
  final Seat seat;
  final double? size; // nullable로 변경
  final VoidCallback? onTap;

  const SeatWidget({super.key, required this.seat, this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 좌석의 width, height 사용 또는 기본값
    final seatWidth = size ?? seat.width;
    final seatHeight = size ?? seat.height;

    // 폰트크기 설정 가져오기
    final fontSizeRatio =
        ref.watch(currentBaseFontSizeProvider) / 16.0; // 16px를 기준으로 비율 계산

    return GestureDetector(
      onTap: () {
        ref.read(seatProvider.notifier).selectSeat(seat.id);
        onTap?.call();
      },
      child: Container(
        width: seatWidth,
        height: seatHeight,
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
                fontSize: ((seatWidth * 0.25).clamp(10.0, 20.0) * fontSizeRatio)
                    .clamp(8.0, 24.0), // 폰트크기 설정 적용
                fontWeight: FontWeight.bold,
                color: _getTextColor(seat.status),
              ),
            ),

            // 좌석 타입 아이콘
            Icon(
              _getSeatTypeIcon(seat.type),
              size: ((seatWidth * 0.2).clamp(12.0, 24.0) * fontSizeRatio).clamp(
                10.0,
                30.0,
              ), // 아이콘 크기도 폰트크기에 맞춰 조정
              color: _getTextColor(seat.status).withValues(alpha: 0.7),
            ),

            // 남은 시간 (사용 중인 경우)
            if (seat.status == SeatStatus.occupied &&
                seat.remainingMinutes != null)
              Text(
                _formatTime(seat.remainingMinutes!),
                style: TextStyle(
                  fontSize:
                      ((seatWidth * 0.12).clamp(8.0, 14.0) * fontSizeRatio)
                          .clamp(6.0, 16.0), // 시간 텍스트도 폰트크기 설정 적용
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
