import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../models/seat.dart';
import '../../providers/seat_provider.dart';
import '../../utils/responsive.dart';
import 'widgets/seat_grid_widget.dart';
import 'widgets/seat_layout_header_widget.dart';

/// 좌석 배치 화면 - 위젯들로 구성된 간소화된 화면
class SeatLayoutScreen extends ConsumerStatefulWidget {
  const SeatLayoutScreen({super.key});

  @override
  ConsumerState<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends ConsumerState<SeatLayoutScreen> {
  OverlayEntry? _currentPopupEntry;
  String? _currentPopupSeatId;

  // 배치도 설정 캐시
  Map<String, double>? _layoutSettings;

  @override
  void initState() {
    super.initState();
    _loadLayoutSettings();
  }

  /// 배치도 설정 로드
  Future<void> _loadLayoutSettings() async {
    if (mounted) {
      final settings = await ref
          .read(seatProvider.notifier)
          .getLayoutSettings();
      if (mounted) {
        setState(() {
          _layoutSettings = settings;
        });
      }
    }
  }

  @override
  void dispose() {
    _removeCurrentPopup();
    super.dispose();
  }

  void _removeCurrentPopup() {
    _currentPopupEntry?.remove();
    _currentPopupEntry = null;
    _currentPopupSeatId = null;
  }

  @override
  Widget build(BuildContext context) {
    final seats = ref.watch(seatProvider);

    // 좌석이 변경될 때마다 배치도 설정도 다시 로드
    ref.listen(seatProvider, (previous, next) {
      if (previous != next) {
        _loadLayoutSettings();
      }
    });

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌석 배치 헤더
          const SeatLayoutHeaderWidget(),

          SizedBox(height: Responsive.getResponsivePadding(context)),

          // 좌석 그리드
          Expanded(
            child: Container(
              padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: SeatGridWidget(
                seats: seats,
                layoutSettings: _layoutSettings,
                onSeatTap: _showSeatPopupMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeatPopupMenu(BuildContext context, WidgetRef ref, Seat seat) {
    // 같은 좌석을 다시 클릭한 경우 팝업만 닫기
    if (_currentPopupSeatId == seat.id) {
      _removeCurrentPopup();
      return;
    }

    // 기존 팝업이 있으면 제거
    if (_currentPopupEntry != null) {
      _removeCurrentPopup();
    }

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    _currentPopupSeatId = seat.id;

    // 팝업 메뉴 크기
    const double popupWidth = AppConstants.popupWidth;
    const double popupHeight = AppConstants.popupHeight;

    // 버튼 중앙 기준으로 팝업 중앙이 오도록 계산
    final double popupLeft =
        buttonPosition.dx + (button.size.width / 2) - (popupWidth / 2);
    final double popupTop =
        buttonPosition.dy + (button.size.height / 2) - (popupHeight / 2);

    _currentPopupEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: popupLeft,
        top: popupTop,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupMenuItem(
                  context,
                  Icons.person_add,
                  '회원등록',
                  () => _handleSeatAction(context, ref, seat, 'register'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.lightbulb,
                  '점등',
                  () => _handleSeatAction(context, ref, seat, 'light_on'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.lightbulb_outline,
                  '소등',
                  () => _handleSeatAction(context, ref, seat, 'light_off'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.login,
                  '입실',
                  () => _handleSeatAction(context, ref, seat, 'check_in'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.logout,
                  '퇴실',
                  () => _handleSeatAction(context, ref, seat, 'check_out'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.keyboard_return,
                  '복귀',
                  () => _handleSeatAction(context, ref, seat, 'return'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.directions_walk,
                  '외출',
                  () => _handleSeatAction(context, ref, seat, 'away'),
                ),
                _buildPopupMenuItem(
                  context,
                  Icons.swap_horiz,
                  '좌석이동',
                  () => _handleSeatAction(context, ref, seat, 'move'),
                ),
                const Divider(height: 1),
                _buildPopupMenuItem(
                  context,
                  Icons.close,
                  '닫기',
                  () => _removeCurrentPopup(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentPopupEntry!);
  }

  Widget _buildPopupMenuItem(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        if (text == '닫기') {
          _removeCurrentPopup();
        } else {
          _removeCurrentPopup();
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }

  void _handleSeatAction(
    BuildContext context,
    WidgetRef ref,
    Seat seat,
    String action,
  ) {
    final seatNotifier = ref.read(seatProvider.notifier);

    switch (action) {
      case 'register':
        _showRegisterDialog(context, ref, seat);
        break;
      case 'light_on':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number} 조명을 켰습니다')));
        break;
      case 'light_off':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number} 조명을 껐습니다')));
        break;
      case 'check_in':
        if (seat.status == SeatStatus.available) {
          seatNotifier.checkInSeat(
            seat.id,
            'user${seat.number}',
            '사용자${seat.number}',
            2,
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number}에 입실했습니다')));
        }
        break;
      case 'check_out':
        if (seat.status == SeatStatus.occupied) {
          seatNotifier.checkOutSeat(seat.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number}에서 퇴실했습니다')));
        }
        break;
      case 'return':
        if (seat.status == SeatStatus.reserved) {
          seatNotifier.updateSeatStatus(seat.id, SeatStatus.occupied);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number}로 복귀했습니다')));
        }
        break;
      case 'away':
        if (seat.status == SeatStatus.occupied) {
          seatNotifier.updateSeatStatus(seat.id, SeatStatus.reserved);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('좌석 ${seat.number}에서 외출했습니다')));
        }
        break;
      case 'move':
        _showSeatMoveDialog(context, ref, seat);
        break;
    }
  }

  void _showRegisterDialog(BuildContext context, WidgetRef ref, Seat seat) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('좌석 ${seat.number} 회원등록'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '회원명',
            hintText: '등록할 회원명을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref
                    .read(seatProvider.notifier)
                    .checkInSeat(
                      seat.id,
                      'user${seat.number}',
                      nameController.text,
                      2,
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${nameController.text}님이 좌석 ${seat.number}에 등록되었습니다',
                    ),
                  ),
                );
              }
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  void _showSeatMoveDialog(BuildContext context, WidgetRef ref, Seat seat) {
    final seats = ref.read(seatProvider);
    final availableSeats = seats
        .where((s) => s.status == SeatStatus.available && s.id != seat.id)
        .toList();

    if (availableSeats.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이동 가능한 좌석이 없습니다')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('좌석 ${seat.number}에서 이동'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이동할 좌석을 선택하세요:'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: availableSeats.length,
                itemBuilder: (context, index) {
                  final targetSeat = availableSeats[index];
                  return InkWell(
                    onTap: () {
                      _moveSeat(context, ref, seat, targetSeat);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 20,
                            child: Text(
                              targetSeat.number.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '좌석 ${targetSeat.number}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  targetSeat.type.displayName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _moveSeat(
    BuildContext context,
    WidgetRef ref,
    Seat fromSeat,
    Seat toSeat,
  ) {
    final seatNotifier = ref.read(seatProvider.notifier);
    final userName = fromSeat.userName ?? '사용자';
    final userId = fromSeat.userId ?? 'user${toSeat.number}';

    // 기존 좌석 체크아웃
    seatNotifier.checkOutSeat(fromSeat.id);

    // 새 좌석 체크인 (2시간으로 설정)
    seatNotifier.checkInSeat(toSeat.id, userId, userName, 2);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('좌석 ${fromSeat.number}에서 좌석 ${toSeat.number}로 이동했습니다'),
      ),
    );
  }
}
