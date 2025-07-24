import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';

/// 좌석 배치도 설정 팝업
class SettingsPopupWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(double top, double left, double width, double height) onApplyLayoutSettings;
  final VoidCallback onResetCanvasPosition;
  final void Function(int start, int end) onAddSeats;
  final void Function(double? width, double? height, double? rotation) onApplySelectedSeatSettings;

  const SettingsPopupWidget({
    super.key,
    required this.onClose,
    required this.onApplyLayoutSettings,
    required this.onResetCanvasPosition,
    required this.onAddSeats,
    required this.onApplySelectedSeatSettings,
  });

  @override
  ConsumerState<SettingsPopupWidget> createState() => _SettingsPopupWidgetState();
}

class _SettingsPopupWidgetState extends ConsumerState<SettingsPopupWidget> {
  // 컨트롤러들
  late final TextEditingController _topController;
  late final TextEditingController _leftController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _startSeatController;
  late final TextEditingController _endSeatController;
  late final TextEditingController _seatWidthController;
  late final TextEditingController _seatHeightController;
  late final TextEditingController _rotationController;

  // 드래그 관련 상태
  double _popupX = 16;
  double _popupY = 70;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _topController = TextEditingController(text: SeatLayoutConstants.defaultTop.toString());
    _leftController = TextEditingController(text: SeatLayoutConstants.defaultLeft.toString());
    _widthController = TextEditingController(text: SeatLayoutConstants.defaultWidth.toString());
    _heightController = TextEditingController(text: SeatLayoutConstants.defaultHeight.toString());
    _startSeatController = TextEditingController(text: '1');
    _endSeatController = TextEditingController(text: '10');
    _seatWidthController = TextEditingController(
      text: SeatLayoutConstants.defaultSeatWidth.toString(),
    );
    _seatHeightController = TextEditingController(
      text: SeatLayoutConstants.defaultSeatHeight.toString(),
    );
    _rotationController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _topController.dispose();
    _leftController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _startSeatController.dispose();
    _endSeatController.dispose();
    _seatWidthController.dispose();
    _seatHeightController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _popupY,
      left: _popupX,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _popupX += details.delta.dx;
            _popupY += details.delta.dy;

            // 화면 경계 제한
            final screenSize = MediaQuery.of(context).size;
            const popupWidth = SeatLayoutConstants.popupMaxWidth;
            const popupHeight = SeatLayoutConstants.popupMaxHeight;

            _popupX = _popupX.clamp(0, screenSize.width - popupWidth);
            _popupY = _popupY.clamp(0, screenSize.height - popupHeight);
          });
        },
        child: Container(
          width: SeatLayoutConstants.popupMaxWidth,
          constraints: const BoxConstraints(
            maxWidth: SeatLayoutConstants.popupMaxWidth,
            minWidth: SeatLayoutConstants.popupMinWidth,
            maxHeight: SeatLayoutConstants.popupMaxHeight,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: SeatLayoutConstants.popupShadowColor,
                blurRadius: SeatLayoutConstants.popupShadowBlurRadius,
                offset: SeatLayoutConstants.popupShadowOffset,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildLayoutSettings(),
                const SizedBox(height: 16),
                _buildSeatCreation(),
                const SizedBox(height: 16),
                _buildSelectedSeatSettings(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더 섹션
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.drag_handle, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              const Text('좌석 배치도 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  /// 배치도 설정 섹션
  Widget _buildLayoutSettings() {
    return Row(
      children: [
        const Text('배치도 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 16),
        _buildTextField(_leftController, 'Left'),
        const SizedBox(width: 8),
        _buildTextField(_topController, 'Top'),
        const SizedBox(width: 8),
        _buildTextField(_widthController, 'Width'),
        const SizedBox(width: 8),
        _buildTextField(_heightController, 'Height'),
        const SizedBox(width: 16),
        _buildActionButton('적용', _applyLayoutSettings),
        const SizedBox(width: 8),
        _buildActionButton('초기화', widget.onResetCanvasPosition),
      ],
    );
  }

  /// 좌석 생성 섹션
  Widget _buildSeatCreation() {
    return Row(
      children: [
        const Text('좌석 생성', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 16),
        _buildTextField(_startSeatController, '시작'),
        const SizedBox(width: 8),
        const Text(' ~ '),
        const SizedBox(width: 8),
        _buildTextField(_endSeatController, '끝'),
        const SizedBox(width: 16),
        _buildActionButton('생성', _createSeats),
      ],
    );
  }

  /// 선택된 좌석 설정 섹션
  Widget _buildSelectedSeatSettings() {
    return Row(
      children: [
        const Text('선택 좌석 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 16),
        _buildTextField(_seatWidthController, 'Width'),
        const SizedBox(width: 8),
        _buildTextField(_seatHeightController, 'Height'),
        const SizedBox(width: 8),
        _buildTextField(_rotationController, 'Rotation'),
        const SizedBox(width: 4),
        _buildRotationButton(Icons.rotate_left, -1, '좌회전'),
        const SizedBox(width: 4),
        _buildRotationButton(Icons.rotate_right, 1, '우회전'),
        const SizedBox(width: 16),
        _buildActionButton('적용', _applySelectedSeatSettings),
      ],
    );
  }

  /// 텍스트 필드 생성
  Widget _buildTextField(TextEditingController controller, String label) {
    return SizedBox(
      width: 60, // 120에서 60으로 반으로 줄임
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  /// 액션 버튼 생성
  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text),
    );
  }

  /// 회전 버튼 생성
  Widget _buildRotationButton(IconData icon, int direction, String tooltip) {
    return IconButton(
      onPressed: () => _rotateBy(direction),
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
    );
  }

  /// 배치도 설정 적용
  void _applyLayoutSettings() {
    final top = double.tryParse(topValue) ?? SeatLayoutConstants.defaultTop;
    final left = double.tryParse(leftValue) ?? SeatLayoutConstants.defaultLeft;
    final width = double.tryParse(widthValue) ?? SeatLayoutConstants.defaultWidth;
    final height = double.tryParse(heightValue) ?? SeatLayoutConstants.defaultHeight;
    widget.onApplyLayoutSettings(top, left, width, height);
  }

  /// 좌석 생성
  void _createSeats() {
    final start = int.tryParse(startSeatValue) ?? 1;
    final end = int.tryParse(endSeatValue) ?? 10;
    widget.onAddSeats(start, end);
  }

  /// 선택된 좌석 설정 적용
  void _applySelectedSeatSettings() {
    final width = double.tryParse(seatWidthValue);
    final height = double.tryParse(seatHeightValue);
    final rotation = double.tryParse(rotationValue);
    widget.onApplySelectedSeatSettings(width, height, rotation);
  }

  /// 회전값 변경 (1도씩)
  void _rotateBy(int direction) {
    final currentRotation = double.tryParse(_rotationController.text) ?? 0;
    final newRotation = currentRotation + direction;
    _rotationController.text = newRotation.toString();

    // 즉시 적용
    widget.onApplySelectedSeatSettings(null, null, newRotation);
  }

  // Getter 메서드들
  String get topValue => _topController.text;
  String get leftValue => _leftController.text;
  String get widthValue => _widthController.text;
  String get heightValue => _heightController.text;
  String get startSeatValue => _startSeatController.text;
  String get endSeatValue => _endSeatController.text;
  String get seatWidthValue => _seatWidthController.text;
  String get seatHeightValue => _seatHeightController.text;
  String get rotationValue => _rotationController.text;
}
