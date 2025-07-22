import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/seat.dart';
import '../models/seat_action.dart';

class SeatPopupMenu extends StatelessWidget {
  final Seat seat;
  final Offset position;
  final VoidCallback onDismiss;
  final Function(SeatAction) onAction;

  const SeatPopupMenu({
    super.key,
    required this.seat,
    required this.position,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final availableActions = SeatAction.values
        .where((action) => action.isAvailableFor(seat.status))
        .toList();

    return Stack(
      children: [
        // 배경 터치시 닫기
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),

        // 팝업 메뉴
        Positioned(
          left: _getMenuLeft(context),
          top: _getMenuTop(context),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 200.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 좌석 정보 헤더
                  _buildSeatInfoHeader(context),
                  Divider(height: 16.h),

                  // 액션 버튼들
                  ...availableActions.map((action) => _buildActionButton(context, action)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatInfoHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: _getSeatStatusColor(),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Center(
                  child: Text(
                    seat.number.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${seat.number}번 좌석 (${seat.type.displayName})',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      seat.status.displayName,
                      style: TextStyle(fontSize: 12.sp, color: _getSeatStatusColor()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (seat.userName != null) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 4.w),
                Text(
                  seat.userName!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (seat.startTime != null) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${seat.startTime!.hour.toString().padLeft(2, '0')}:${seat.startTime!.minute.toString().padLeft(2, '0')}부터',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, SeatAction action) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: InkWell(
        onTap: () => onAction(action),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(_getActionIcon(action), size: 18.sp, color: _getActionColor(action)),
              SizedBox(width: 8.w),
              Text(
                action.displayName,
                style: TextStyle(fontSize: 14.sp, color: _getActionColor(action)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMenuLeft(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = 200.w;

    double left = position.dx - menuWidth / 2;

    // 화면 경계 체크
    if (left < 20) left = 20;
    if (left + menuWidth > screenWidth - 20) left = screenWidth - menuWidth - 20;

    return left;
  }

  double _getMenuTop(BuildContext context) {
    double top = position.dy - 50;

    // 화면 상단 경계 체크
    if (top < 100) top = position.dy + 50;

    return top;
  }

  Color _getSeatStatusColor() {
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

  IconData _getActionIcon(SeatAction action) {
    switch (action) {
      case SeatAction.registerMember:
        return Icons.person_add;
      case SeatAction.lightOn:
        return Icons.lightbulb;
      case SeatAction.lightOff:
        return Icons.lightbulb_outline;
      case SeatAction.checkin:
        return Icons.login;
      case SeatAction.checkout:
        return Icons.logout;
      case SeatAction.returnSeat:
        return Icons.keyboard_return;
      case SeatAction.goOut:
        return Icons.exit_to_app;
      case SeatAction.moveSeat:
        return Icons.swap_horiz;
    }
  }

  Color _getActionColor(SeatAction action) {
    switch (action) {
      case SeatAction.registerMember:
        return Colors.blue;
      case SeatAction.lightOn:
        return Colors.amber;
      case SeatAction.lightOff:
        return Colors.grey;
      case SeatAction.checkin:
        return Colors.green;
      case SeatAction.checkout:
        return Colors.red;
      case SeatAction.returnSeat:
        return Colors.teal;
      case SeatAction.goOut:
        return Colors.orange;
      case SeatAction.moveSeat:
        return Colors.purple;
    }
  }
}
