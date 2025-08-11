import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../providers/font_size_provider.dart';
import '../providers/seat_provider.dart';

class SeatPopupMenu extends ConsumerStatefulWidget {
  final Seat seat;

  const SeatPopupMenu({super.key, required this.seat});

  @override
  ConsumerState<SeatPopupMenu> createState() => _SeatPopupMenuState();
}

class _SeatPopupMenuState extends ConsumerState<SeatPopupMenu> {
  final _userNameController = TextEditingController();
  int _selectedHours = 2;

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeatColor(widget.seat.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSeatTypeIcon(widget.seat.type),
                    color: _getTextColor(widget.seat.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '좌석 ${widget.seat.number}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.seat.type.displayName} • ${widget.seat.status.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 현재 상태 정보
            if (widget.seat.status == SeatStatus.occupied) ...[
              _buildInfoCard(),
              const SizedBox(height: 16),
            ],

            // 액션 버튼들
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 이용 정보',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('이용자: ${widget.seat.userName ?? '알 수 없음'}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('시작 시간: ${_formatDateTime(widget.seat.startTime)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('종료 예정: ${_formatDateTime(widget.seat.endTime)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('남은 시간: ${widget.seat.remainingTimeText}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isOccupied = widget.seat.status == SeatStatus.occupied;
    final isAvailable = widget.seat.status == SeatStatus.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAvailable) ...[
          // 체크인 섹션
          Text(
            '새 이용자 체크인',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: '이용자 이름',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('이용 시간: ', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int>(
                  value: _selectedHours,
                  isExpanded: true,
                  items: [1, 2, 3, 4, 5, 6, 8, 10, 12].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours시간'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedHours = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _checkIn(),
            icon: const Icon(Icons.login),
            label: const Text('체크인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],

        if (isOccupied) ...[
          // 체크아웃 버튼
          ElevatedButton.icon(
            onPressed: () => _checkOut(),
            icon: const Icon(Icons.logout),
            label: const Text('체크아웃'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // 시간 연장 버튼들
          Text(
            '시간 연장',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _extendTime(30),
                  child: const Text('30분'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _extendTime(60),
                  child: const Text('1시간'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _extendTime(120),
                  child: const Text('2시간'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // 상태 변경 버튼들
        Text(
          '좌석 상태 변경',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (widget.seat.status != SeatStatus.available)
              _buildStatusButton('사용 가능', SeatStatus.available, Colors.green),
            if (widget.seat.status != SeatStatus.maintenance)
              _buildStatusButton('점검 중', SeatStatus.maintenance, Colors.orange),
            if (widget.seat.status != SeatStatus.cleaning)
              _buildStatusButton('청소 중', SeatStatus.cleaning, Colors.purple),
            if (widget.seat.status != SeatStatus.outOfOrder)
              _buildStatusButton('고장', SeatStatus.outOfOrder, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusButton(String label, SeatStatus status, Color color) {
    final fontSizeRatio = ref.watch(currentBaseFontSizeProvider) / 16.0;

    return OutlinedButton(
      onPressed: () => _changeStatus(status),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: (14.0 * fontSizeRatio).clamp(12.0, 18.0), // 폰트크기 설정 적용
        ),
      ),
    );
  }

  void _checkIn() {
    if (_userNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이용자 이름을 입력해주세요')));
      return;
    }

    ref
        .read(seatProvider.notifier)
        .checkInSeat(
          widget.seat.id,
          'user_${DateTime.now().millisecondsSinceEpoch}',
          _userNameController.text.trim(),
          _selectedHours,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('좌석 ${widget.seat.number}에 체크인되었습니다')),
    );
  }

  void _checkOut() {
    ref.read(seatProvider.notifier).checkOutSeat(widget.seat.id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('좌석 ${widget.seat.number}에서 체크아웃되었습니다')),
    );
  }

  void _extendTime(int minutes) {
    ref.read(seatProvider.notifier).extendTime(widget.seat.id, minutes);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$minutes분 연장되었습니다')));
  }

  void _changeStatus(SeatStatus status) {
    ref.read(seatProvider.notifier).updateSeatStatus(widget.seat.id, status);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('좌석 ${widget.seat.number} 상태가 변경되었습니다')),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '알 수 없음';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
}
