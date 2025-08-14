import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_constants.dart';
import '../../../models/seat.dart';
import '../../../widgets/seat_widget.dart';

/// 좌석 그리드 표시 위젯
class SeatGridWidget extends ConsumerStatefulWidget {
  final List<Seat> seats;
  final Function(BuildContext, WidgetRef, Seat) onSeatTap;
  final Map<String, double>? layoutSettings;

  const SeatGridWidget({
    super.key,
    required this.seats,
    required this.onSeatTap,
    this.layoutSettings,
  });

  @override
  ConsumerState<SeatGridWidget> createState() => _SeatGridWidgetState();
}

class _SeatGridWidgetState extends ConsumerState<SeatGridWidget> {
  late TransformationController _transformationController;
  Size? _previousScreenSize;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 캔버스 너비 가져오기
  double _getCanvasWidth() {
    return widget.layoutSettings?['width'] ?? 1800.0;
  }

  /// 캔버스 높이 가져오기
  double _getCanvasHeight() {
    return widget.layoutSettings?['height'] ?? 900.0;
  }

  @override
  Widget build(BuildContext context) {
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
        ? screenHeight * 0.6 // 작은 화면에서는 60% 차지
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
              ...widget.seats.map((seat) => _buildPositionedSeat(context, seat)),
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

  Widget _buildPositionedSeat(BuildContext context, Seat seat) {
    return Positioned(
      left: seat.x,
      top: seat.y,
      child: SizedBox(
        width: seat.width,
        height: seat.height,
        child: Material(
          color: Colors.transparent,
          child: _buildSeatWithPopup(context, seat),
        ),
      ),
    );
  }

  Widget _buildSeatWithPopup(BuildContext context, Seat seat) {
    return Builder(
      builder: (BuildContext context) {
        return SeatWidget(
          seat: seat,
          onTap: () => widget.onSeatTap(context, ref, seat),
        );
      },
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
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 가로선 그리기
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
