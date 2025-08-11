import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';
import '../providers/lock_state_provider.dart';
import '../providers/seat_layout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/keyboard_handler.dart';

/// 좌석 배치도 설정 팝업
class SettingsPopupWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(double top, double left, double width, double height)
  onApplyLayoutSettings;
  final VoidCallback onResetCanvasPosition;
  final void Function(int start, int end) onAddSeats;
  final void Function(double? width, double? height)
  onApplySelectedSeatSettings;
  final void Function(bool clockwise) onRotateLayout; // 배치도 회전 콜백 추가

  const SettingsPopupWidget({
    super.key,
    required this.onClose,
    required this.onApplyLayoutSettings,
    required this.onResetCanvasPosition,
    required this.onAddSeats,
    required this.onApplySelectedSeatSettings,
    required this.onRotateLayout,
  });

  @override
  ConsumerState<SettingsPopupWidget> createState() =>
      _SettingsPopupWidgetState();
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
  late final TextEditingController _moveStepController; // 이동간격 컨트롤러 추가

  // 포커스 노드들
  late final FocusNode _topFocusNode;
  late final FocusNode _leftFocusNode;
  late final FocusNode _widthFocusNode;
  late final FocusNode _heightFocusNode;

  // 팝업 위치
  double _popupX = 100.0;
  double _popupY = 100.0;

  // 팝업 크기 측정을 위한 GlobalKey
  final GlobalKey _popupKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    print('🎨 [SETTINGS_POPUP] ===== 설정 팝업 위젯 초기화 시작 =====');
    _initializeControllers();
    _initializeFocusNodes();
    print('🎨 [SETTINGS_POPUP] ===== 설정 팝업 위젯 초기화 완료 =====');
  }

  void _initializeControllers() {
    _topController = TextEditingController(
      text: SeatLayoutConstants.defaultTop.toString(),
    );
    _leftController = TextEditingController(
      text: SeatLayoutConstants.defaultLeft.toString(),
    );
    _widthController = TextEditingController(
      text: SeatLayoutConstants.defaultWidth.toString(),
    );
    _heightController = TextEditingController(
      text: SeatLayoutConstants.defaultHeight.toString(),
    );
    _startSeatController = TextEditingController(text: '1');
    _endSeatController = TextEditingController(text: '10');
    _seatWidthController = TextEditingController(
      text: SeatLayoutConstants.defaultSeatWidth.toString(),
    );
    _seatHeightController = TextEditingController(
      text: SeatLayoutConstants.defaultSeatHeight.toString(),
    );
    _moveStepController = TextEditingController(
      text: SeatLayoutConstants.moveStep.toString(),
    );
  }

  void _initializeFocusNodes() {
    _topFocusNode = FocusNode();
    _leftFocusNode = FocusNode();
    _widthFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
  }

  /// 현재 레이아웃 값으로 컨트롤러 업데이트
  void _updateControllersWithCurrentValues(SeatLayoutData layoutData) {
    // 텍스트 필드가 포커스를 가지고 있지 않을 때만 업데이트 (사용자가 편집 중이 아닐 때)
    if (!_topFocusNode.hasFocus) {
      _topController.text = layoutData.top.toString();
    }
    if (!_leftFocusNode.hasFocus) {
      _leftController.text = layoutData.left.toString();
    }
    if (!_widthFocusNode.hasFocus) {
      _widthController.text = layoutData.width.toString();
    }
    if (!_heightFocusNode.hasFocus) {
      _heightController.text = layoutData.height.toString();
    }
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
    _moveStepController.dispose();

    _topFocusNode.dispose();
    _leftFocusNode.dispose();
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [SETTINGS_POPUP] ===== BUILD 메소드 호출됨 =====');

    // Provider에서 현재 테마 모드 가져오기
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final isDarkMode = currentThemeMode == AppThemeMode.dark;

    // 테마 디버깅 로그
    final theme = Theme.of(context);
    print(
      '🎨 [SETTINGS_POPUP] Provider 테마 모드: ${currentThemeMode.displayName}',
    );
    print('🎨 [SETTINGS_POPUP] Provider 다크 모드: $isDarkMode');
    print('🎨 [SETTINGS_POPUP] 현재 테마 brightness: ${theme.brightness}');
    print(
      '🎨 [SETTINGS_POPUP] 컨테이너 배경색: ${theme.colorScheme.surfaceContainer}',
    );
    print('🎨 [SETTINGS_POPUP] onSurface 색상: ${theme.colorScheme.onSurface}');
    print(
      '🎨 [SETTINGS_POPUP] bodyLarge 색상: ${theme.textTheme.bodyLarge?.color}',
    );
    print(
      '🎨 [SETTINGS_POPUP] bodyMedium 색상: ${theme.textTheme.bodyMedium?.color}',
    );
    print(
      '🎨 [SETTINGS_POPUP] labelLarge 색상: ${theme.textTheme.labelLarge?.color}',
    );

    // 현재 시간도 추가해서 언제 호출되는지 확인
    print('🎨 [SETTINGS_POPUP] 현재 시간: ${DateTime.now()}');

    // 현재 레이아웃 데이터를 가져와서 텍스트 필드에 반영
    final layoutData = ref.watch(seatLayoutProvider);
    _updateControllersWithCurrentValues(layoutData);

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

            // 실제 렌더링된 높이를 사용하거나 보다 작은 예상 높이 사용
            double popupHeight = SeatLayoutConstants.popupMaxHeight;

            // RenderBox를 통해 실제 높이 확인 시도
            if (_popupKey.currentContext != null) {
              final RenderBox? renderBox =
                  _popupKey.currentContext!.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                popupHeight = renderBox.size.height;
              }
            }

            // 만약 실제 높이를 못 구했다면, 가로 배치로 인한 예상 높이 사용 (더 작은 값)
            if (popupHeight == SeatLayoutConstants.popupMaxHeight) {
              popupHeight = 200.0; // 가로 배치로 인해 훨씬 작을 것으로 예상
            }

            _popupX = _popupX.clamp(0, screenSize.width - popupWidth);
            _popupY = _popupY.clamp(0, screenSize.height - popupHeight);
          });
        },
        child: Container(
          key: _popupKey,
          width: SeatLayoutConstants.popupMaxWidth,
          constraints: const BoxConstraints(
            maxWidth: SeatLayoutConstants.popupMaxWidth,
            minWidth: SeatLayoutConstants.popupMinWidth,
            maxHeight: SeatLayoutConstants.popupMaxHeight,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
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
                _buildLayoutRotation(), // 배치도 회전 섹션 추가
                const SizedBox(height: 16),
                _buildSeatCreation(),
                const SizedBox(height: 16),
                _buildMoveSettings(), // 이동간격 설정 추가
                const SizedBox(height: 16),
                _buildLockSettings(), // 잠금 설정 추가
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '좌석 배치도 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: null, // 테마의 기본 텍스트 색상 사용
                ),
              ),
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
        Text(
          '배치도 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        _buildTextField(_leftController, 'Left', focusNode: _leftFocusNode),
        const SizedBox(width: 8),
        _buildTextField(_topController, 'Top', focusNode: _topFocusNode),
        const SizedBox(width: 8),
        _buildTextField(_widthController, 'Width', focusNode: _widthFocusNode),
        const SizedBox(width: 8),
        _buildTextField(
          _heightController,
          'Height',
          focusNode: _heightFocusNode,
        ),
        const SizedBox(width: 16),
        _buildActionButton('적용', _applyLayoutSettings),
        const SizedBox(width: 8),
        _buildActionButton('위치리셋', widget.onResetCanvasPosition),
      ],
    );
  }

  /// 배치도 회전 섹션
  Widget _buildLayoutRotation() {
    final layoutData = ref.watch(seatLayoutProvider);
    return Row(
      children: [
        Text(
          '배치도 회전',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Text(
          '현재: ${layoutData.rotation.toInt()}°',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 16),
        _buildActionButton('좌로회전', () => widget.onRotateLayout(false)),
        const SizedBox(width: 8),
        _buildActionButton('우로회전', () => widget.onRotateLayout(true)),
      ],
    );
  }

  /// 좌석 생성 섹션
  Widget _buildSeatCreation() {
    return Row(
      children: [
        Text(
          '좌석 생성',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
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

  /// 이동간격 설정 섹션
  Widget _buildMoveSettings() {
    return Row(
      children: [
        Text(
          '이동간격 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        _buildTextField(_moveStepController, '간격(px)'),
        const SizedBox(width: 16),
        _buildActionButton('적용', _applyMoveSettings),
      ],
    );
  }

  /// 선택된 좌석 설정 섹션
  Widget _buildSelectedSeatSettings() {
    return Row(
      children: [
        Text(
          '선택 좌석 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        _buildTextField(_seatWidthController, 'Width'),
        const SizedBox(width: 8),
        _buildTextField(_seatHeightController, 'Height'),
        const SizedBox(width: 16),
        _buildActionButton('적용', _applySelectedSeatSettings),
      ],
    );
  }

  /// 텍스트 필드 생성
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
  }) {
    return SizedBox(
      width: 60, // 120에서 60으로 반으로 줄임
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
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

  /// 배치도 설정 적용
  void _applyLayoutSettings() {
    final top = double.tryParse(topValue) ?? SeatLayoutConstants.defaultTop;
    final left = double.tryParse(leftValue) ?? SeatLayoutConstants.defaultLeft;
    final width =
        double.tryParse(widthValue) ?? SeatLayoutConstants.defaultWidth;
    final height =
        double.tryParse(heightValue) ?? SeatLayoutConstants.defaultHeight;
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
    widget.onApplySelectedSeatSettings(width, height);
  }

  /// 이동간격 설정 적용
  void _applyMoveSettings() {
    final moveStep =
        double.tryParse(moveStepValue) ?? SeatLayoutConstants.moveStep;
    // Provider를 통해 이동간격을 업데이트
    ref.read(moveStepProvider.notifier).state = moveStep;
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
  String get moveStepValue => _moveStepController.text; // 이동간격 getter 추가

  /// 잠금 설정 섹션
  Widget _buildLockSettings() {
    final layoutMoveLock = ref.watch(layoutMoveLockProvider);
    final seatEditLock = ref.watch(seatEditLockProvider);

    return Row(
      children: [
        Text(
          '잠금 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        // 배치도 이동 잠금 체크박스
        Row(
          children: [
            Checkbox(
              value: layoutMoveLock,
              onChanged: (value) {
                ref.read(layoutMoveLockProvider.notifier).state = value ?? true;
              },
            ),
            Text(
              '배치도 이동 잠금',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // 좌석 배치 변경 잠금 체크박스
        Row(
          children: [
            Checkbox(
              value: seatEditLock,
              onChanged: (value) {
                ref.read(seatEditLockProvider.notifier).state = value ?? true;
              },
            ),
            Text(
              '좌석 배치 변경 잠금',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}
