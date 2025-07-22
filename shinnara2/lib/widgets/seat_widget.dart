import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/seat.dart';

class SeatWidget extends StatelessWidget {
  final Seat seat;
  final double size;

  const SeatWidget({super.key, required this.seat, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getSeatColor(),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _getBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 좌석 번호
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  seat.number.toString(),
                  style: TextStyle(
                    fontSize: (size * 0.25).sp,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
                if (seat.userName != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    seat.userName!,
                    style: TextStyle(fontSize: (size * 0.15).sp, color: _getTextColor()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // 좌석 타입 아이콘
          Positioned(
            top: 2.h,
            right: 2.w,
            child: Icon(
              _getSeatTypeIcon(),
              size: (size * 0.2).sp,
              color: _getTextColor().withOpacity(0.7),
            ),
          ),

          // 상태 표시 점
          Positioned(
            top: 2.h,
            left: 2.w,
            child: Container(
              width: (size * 0.15).w,
              height: (size * 0.15).h,
              decoration: BoxDecoration(color: _getStatusDotColor(), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeatColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.green.shade100;
      case SeatStatus.occupied:
        return Colors.red.shade100;
      case SeatStatus.away:
        return Colors.orange.shade100;
      case SeatStatus.reserved:
        return Colors.blue.shade100;
      case SeatStatus.outOfOrder:
        return Colors.grey.shade300;
      case SeatStatus.cleaning:
        return Colors.purple.shade100;
    }
  }

  Color _getBorderColor() {
    switch (seat.type) {
      case SeatType.standard:
        return Colors.blue;
      case SeatType.premium:
        return Colors.purple;
      case SeatType.group:
        return Colors.teal;
      case SeatType.phone:
        return Colors.brown;
    }
  }

  Color _getTextColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.green.shade800;
      case SeatStatus.occupied:
        return Colors.red.shade800;
      case SeatStatus.away:
        return Colors.orange.shade800;
      case SeatStatus.reserved:
        return Colors.blue.shade800;
      case SeatStatus.outOfOrder:
        return Colors.grey.shade600;
      case SeatStatus.cleaning:
        return Colors.purple.shade800;
    }
  }

  Color _getStatusDotColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.green;
      case SeatStatus.occupied:
        return Colors.red;
      case SeatStatus.away:
        return Colors.orange;
      case SeatStatus.reserved:
        return Colors.blue;
      case SeatStatus.outOfOrder:
        return Colors.grey;
      case SeatStatus.cleaning:
        return Colors.purple;
    }
  }

  IconData _getSeatTypeIcon() {
    switch (seat.type) {
      case SeatType.standard:
        return Icons.chair;
      case SeatType.premium:
        return Icons.star;
      case SeatType.group:
        return Icons.group;
      case SeatType.phone:
        return Icons.phone;
    }
  }
}
