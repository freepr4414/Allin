import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../models/seat.dart';
import '../../providers/seat_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/seat_widget.dart';

class SeatLayoutScreen extends ConsumerStatefulWidget {
  const SeatLayoutScreen({super.key});

  @override
  ConsumerState<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends ConsumerState<SeatLayoutScreen> {
  OverlayEntry? _currentPopupEntry;
  String? _currentPopupSeatId;

  // InteractiveViewer 제어를 위한 컨트롤러
  late TransformationController _transformationController;

  // 이전 화면 크기를 추적하기 위한 변수
  Size? _previousScreenSize;

  // 배치도 설정 캐시
  Map<String, double>? _layoutSettings;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
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
    _transformationController.dispose();
    super.dispose();
  }

  void _removeCurrentPopup() {
    _currentPopupEntry?.remove();
    _currentPopupEntry = null;
    _currentPopupSeatId = null;
  }

  /// 캔버스 너비 가져오기
  double _getCanvasWidth() {
    return _layoutSettings?['width'] ?? 1800.0;
  }

  /// 캔버스 높이 가져오기
  double _getCanvasHeight() {
    return _layoutSettings?['height'] ?? 900.0;
  }

  @override
  Widget build(BuildContext context) {
    final seats = ref.watch(seatProvider);
    final seatStats = ref.watch(seatStatisticsProvider);

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
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsivePadding(context),
              vertical: Responsive.getResponsiveMargin(context),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_seat,
                  color: Theme.of(context).colorScheme.primary,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: AppConstants.mobileIconSize,
                    tablet: AppConstants.tabletIconSize,
                    desktop: AppConstants.desktopIconSize,
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Text(
                  '좌석 현황',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Flexible(child: _buildSeatLegend(context, seatStats)),
              ],
            ),
          ),

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
              child: _buildSeatGrid(context, ref, seats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend(BuildContext context, Map<SeatStatus, int> stats) {
    if (Responsive.isMobile(context)) {
            // 모바일에서는 Wrap으로 자동 줄바꿈
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: Responsive.getResponsiveMargin(context),
        runSpacing: Responsive.getResponsiveMargin(context) / 2,
        children: [
          _buildLegendItem(
            context,
            '이용가능',
            Colors.green,
            stats[SeatStatus.available] ?? 0,
          ),
          _buildLegendItem(
            context,
            '사용중',
            Colors.red,
            stats[SeatStatus.occupied] ?? 0,
          ),
          _buildLegendItem(
            context,
            '예약됨',
            Colors.blue,
            stats[SeatStatus.reserved] ?? 0,
          ),
          _buildLegendItem(
            context,
            '점검중',
            Colors.orange,
            stats[SeatStatus.maintenance] ?? 0,
          ),
          _buildLegendItem(
            context,
            '청소중',
            Colors.purple,
            stats[SeatStatus.cleaning] ?? 0,
          ),
          _buildLegendItem(
            context,
            '고장',
            Colors.grey,
            stats[SeatStatus.outOfOrder] ?? 0,
          ),
        ],
      );
    } else {
      // 태블릿/데스크탑에서는 한 줄로 배치
      return Wrap(
        spacing: Responsive.getResponsivePadding(context),
        children: [
          _buildLegendItem(
            context,
            '이용가능',
            Colors.green,
            stats[SeatStatus.available] ?? 0,
          ),
          _buildLegendItem(
            context,
            '사용중',
            Colors.red,
            stats[SeatStatus.occupied] ?? 0,
          ),
          _buildLegendItem(
            context,
            '예약됨',
            Colors.blue,
            stats[SeatStatus.reserved] ?? 0,
          ),
          _buildLegendItem(
            context,
            '점검중',
            Colors.orange,
            stats[SeatStatus.maintenance] ?? 0,
          ),
          _buildLegendItem(
            context,
            '청소중',
            Colors.purple,
            stats[SeatStatus.cleaning] ?? 0,
          ),
          _buildLegendItem(
            context,
            '고장',
            Colors.grey,
            stats[SeatStatus.outOfOrder] ?? 0,
          ),
        ],
      );
    }
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    int count,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          height: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: Responsive.getResponsiveMargin(context) / 4),
        Flexible(
          child: Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: AppConstants.mobileFontSize,
                tablet: AppConstants.tabletFontSize,
                desktop: AppConstants.desktopFontSize,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(BuildContext context, WidgetRef ref, List<Seat> seats) {
    // 화면 크기 가져오기
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentScreenSize = Size(screenWidth, screenHeight);
    final isSmallScreen = screenWidth < AppConstants.smallScreenWidth || 
                         screenHeight < AppConstants.smallScreenHeight;

    // 화면 크기 변화 감지 및 변환 리셋 (큰 변화가 있을 때만)
    if (_previousScreenSize != null) {
      final sizeDifference =
          (currentScreenSize.width - _previousScreenSize!.width).abs() +
          (currentScreenSize.height - _previousScreenSize!.height).abs();

      // 크기 차이가 50픽셀 이상일 때만 리셋 (작은 변화 무시)
      if (sizeDifference > 50) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _transformationController.value = Matrix4.identity();
          }
        });
      }
    }
    _previousScreenSize = currentScreenSize;

    // 화면 크기에 따라 적응적 높이 설정
    final containerHeight = isSmallScreen
        ? screenHeight *
              0.6 // 작은 화면에서는 60% 차지
        : 600.0; // 큰 화면에서는 고정 높이

    return SizedBox(
      width: double.infinity,
      height: containerHeight,
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 1.0, // 고정 스케일 (확대/축소 비활성화)
        maxScale: 1.0, // 고정 스케일 (확대/축소 비활성화)
        panEnabled: true, // 드래그 이동만 활성화
        scaleEnabled: false, // 확대/축소 비활성화
        child: Container(
          // 저장된 배치도에서 캔버스 크기 가져오기 (기본값: 1800x900)
          width: _getCanvasWidth(),
          height: _getCanvasHeight(),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // 배경 그리드 표시 (위치 파악 도움)
              _buildBackgroundGrid(context),
              // 좌석들
              ...seats.map((seat) => _buildPositionedSeat(context, ref, seat)),
            ],
          ),
        ),
      ),
    );
  }

  // 배경 그리드 생성 (위치 파악을 돕기 위함)
  Widget _buildBackgroundGrid(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: GridPainter());
  }

  Widget _buildPositionedSeat(BuildContext context, WidgetRef ref, Seat seat) {
    return Positioned(
      left: seat.x,
      top: seat.y,
      child: SizedBox(
        width: seat.width,
        height: seat.height,
        child: Material(
          color: Colors.transparent,
          child: _buildSeatWithPopup(context, ref, seat),
        ),
      ),
    );
  }

  Widget _buildSeatWithPopup(BuildContext context, WidgetRef ref, Seat seat) {
    return Builder(
      builder: (BuildContext context) {
        return SeatWidget(
          seat: seat,
          // size 파라미터 제거 - SeatWidget에서 seat.width, seat.height 사용
          onTap: () => _showSeatPopupMenu(context, ref, seat),
        );
      },
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

// 배경 그리드를 그리는 CustomPainter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const gridSize = AppConstants.gridSize;

    // 세로선 그리기
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 그리기
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
