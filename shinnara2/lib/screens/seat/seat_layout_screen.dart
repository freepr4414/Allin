import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../models/seat.dart';
import '../../models/seat_action.dart';
import '../../providers/seat_provider.dart';
import '../../widgets/seat_popup_menu.dart';
import '../../widgets/seat_widget.dart';

class SeatLayoutScreen extends ConsumerStatefulWidget {
  const SeatLayoutScreen({super.key});

  @override
  ConsumerState<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends ConsumerState<SeatLayoutScreen> {
  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    final seats = ref.watch(seatProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          '좌석 배치도',
          style: TextStyle(fontSize: isMobile ? 16.sp : 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 범례 버튼
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegendDialog(context),
          ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 좌석 상태 새로고침 로직
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 요약 바
          _buildStatusSummary(context, seats, isMobile),

          // 좌석 배치도
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              constrained: false,
              child: Container(
                width: isMobile ? 600.w : (isTablet ? 800.w : 1000.w),
                height: isMobile ? 400.h : (isTablet ? 500.h : 600.h),
                padding: EdgeInsets.all(20.w),
                child: CustomPaint(
                  painter: SeatLayoutPainter(),
                  child: Stack(
                    children: seats.map((seat) {
                      return Positioned(
                        left: seat.x * (isMobile ? 0.8 : 1.0),
                        top: seat.y * (isMobile ? 0.8 : 1.0),
                        child: GestureDetector(
                          onTapDown: (details) => _onSeatTap(context, seat, details.globalPosition),
                          child: SeatWidget(seat: seat, size: isMobile ? 60.w : 80.w),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(BuildContext context, List<Seat> seats, bool isMobile) {
    final available = seats.where((s) => s.status == SeatStatus.available).length;
    final occupied = seats.where((s) => s.status == SeatStatus.occupied).length;
    final away = seats.where((s) => s.status == SeatStatus.away).length;
    final total = seats.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(
            context,
            '전체',
            total.toString(),
            Theme.of(context).colorScheme.onSurface,
            isMobile,
          ),
          _buildStatusItem(context, '사용가능', available.toString(), Colors.green, isMobile),
          _buildStatusItem(context, '사용중', occupied.toString(), Colors.red, isMobile),
          _buildStatusItem(context, '외출중', away.toString(), Colors.orange, isMobile),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String count,
    Color color,
    bool isMobile,
  ) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: isMobile ? 18.sp : 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10.sp : 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _onSeatTap(BuildContext context, Seat seat, Offset globalPosition) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => SeatPopupMenu(
        seat: seat,
        position: globalPosition,
        onDismiss: _removeOverlay,
        onAction: (action) {
          _handleSeatAction(seat, action);
          _removeOverlay();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleSeatAction(Seat seat, SeatAction action) {
    final seatNotifier = ref.read(seatProvider.notifier);

    switch (action) {
      case SeatAction.checkin:
        // 실제 구현시에는 회원 선택 다이얼로그 표시
        seatNotifier.checkinSeat(seat.id, 'user123', '김회원');
        break;
      case SeatAction.checkout:
        seatNotifier.checkoutSeat(seat.id);
        break;
      case SeatAction.lightOn:
        // 조명 ON 로직
        break;
      case SeatAction.lightOff:
        // 조명 OFF 로직
        break;
      case SeatAction.goOut:
        seatNotifier.setSeatAway(seat.id);
        break;
      case SeatAction.returnSeat:
        seatNotifier.returnFromAway(seat.id);
        break;
      case SeatAction.moveSeat:
        // 좌석 이동 로직
        break;
      case SeatAction.registerMember:
        // 회원 등록 로직
        break;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('좌석 상태 범례'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(context, Colors.green, '사용 가능'),
            _buildLegendItem(context, Colors.red, '사용 중'),
            _buildLegendItem(context, Colors.orange, '외출 중'),
            _buildLegendItem(context, Colors.grey, '사용 불가'),
            const SizedBox(height: 16),
            _buildLegendItem(context, Colors.blue, '일반석'),
            _buildLegendItem(context, Colors.purple, '프리미엄석'),
            _buildLegendItem(context, Colors.teal, '그룹석'),
            _buildLegendItem(context, Colors.brown, '폰부스'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}

class SeatLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // 격자 그리기
    for (int i = 0; i <= 8; i++) {
      final x = i * 120.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= 6; i++) {
      final y = i * 100.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
