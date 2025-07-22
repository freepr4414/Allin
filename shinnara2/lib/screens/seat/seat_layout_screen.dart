import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/seat.dart';
import '../../providers/seat_provider.dart';
import '../../widgets/seat_widget.dart';

class SeatLayoutScreen extends ConsumerWidget {
  const SeatLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(seatProvider);
    final seatStats = ref.watch(seatStatisticsProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌석 배치 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_seat, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12.0),
                const Text('좌석 현황', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildSeatLegend(context, seatStats),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // 좌석 그리드
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: _buildSeatGrid(context, ref, seats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend(BuildContext context, Map<SeatStatus, int> stats) {
    return Wrap(
      spacing: 16.0,
      children: [
        _buildLegendItem(context, '이용가능', Colors.green, stats[SeatStatus.available] ?? 0),
        _buildLegendItem(context, '사용중', Colors.red, stats[SeatStatus.occupied] ?? 0),
        _buildLegendItem(context, '예약됨', Colors.blue, stats[SeatStatus.reserved] ?? 0),
        _buildLegendItem(context, '점검중', Colors.orange, stats[SeatStatus.maintenance] ?? 0),
        _buildLegendItem(context, '청소중', Colors.purple, stats[SeatStatus.cleaning] ?? 0),
        _buildLegendItem(context, '고장', Colors.grey, stats[SeatStatus.outOfOrder] ?? 0),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4.0),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12.0,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(BuildContext context, WidgetRef ref, List<Seat> seats) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: seats.length,
      itemBuilder: (context, index) {
        final seat = seats[index];
        return SeatWidget(seat: seat, size: 80.0, onTap: () => _showSeatMenu(context, seat));
      },
    );
  }

  void _showSeatMenu(BuildContext context, Seat seat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('좌석 ${seat.number}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('좌석 타입: ${seat.type.displayName}'),
            Text('상태: ${seat.status.displayName}'),
            if (seat.userName != null) Text('이용자: ${seat.userName}'),
            if (seat.remainingTimeText.isNotEmpty) Text('남은 시간: ${seat.remainingTimeText}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
        ],
      ),
    );
  }
}
