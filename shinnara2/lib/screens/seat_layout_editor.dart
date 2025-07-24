import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';
import '../providers/seat_layout_provider.dart';
import '../providers/ui_state_provider.dart';
import '../utils/keyboard_handler.dart';
import '../widgets/common/styled_button_wrapper.dart';
import '../widgets/seat_canvas_widget.dart';
import '../widgets/settings_popup_widget.dart';

class SeatLayoutEditor extends ConsumerStatefulWidget {
  const SeatLayoutEditor({super.key});

  @override
  ConsumerState<SeatLayoutEditor> createState() => _SeatLayoutEditorState();
}

class _SeatLayoutEditorState extends ConsumerState<SeatLayoutEditor> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<SeatCanvasWidgetState> _canvasKey = GlobalKey<SeatCanvasWidgetState>();

  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 포커스를 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 좌석 클릭 핸들러
  void _handleSeatTap(Seat seat) {
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    ref.read(seatLayoutProvider.notifier).selectSeat(seat.id, isCtrlPressed);
    // 좌석 선택 후에도 포커스를 유지
    _focusNode.requestFocus();
  }

  /// 좌석 드래그 핸들러
  void _handleSeatDrag(Seat seat, DragUpdateDetails details) {
    ref.read(seatLayoutProvider.notifier).moveSeat(seat.id, details.delta.dx, details.delta.dy);
  }

  /// 배치도 설정 적용
  void _applyLayoutSettings(double top, double left, double width, double height) {
    ref
        .read(seatLayoutProvider.notifier)
        .updateLayoutSettings(top: top, left: left, width: width, height: height);
  }

  /// 캔버스 위치 리셋
  void _resetCanvasPosition() {
    _canvasKey.currentState?.resetCanvasPosition();
  }

  /// 좌석 생성
  void _addSeats(int start, int end) {
    if (start <= end) {
      ref.read(seatLayoutProvider.notifier).addSeats(start, end);
    }
  }

  /// 선택된 좌석 설정 적용
  void _applySelectedSeatSettings(double? width, double? height, double? rotation) {
    final layoutData = ref.read(seatLayoutProvider);
    final selectedSeats = layoutData.seats.where((seat) => seat.isSelected).toList();

    if (selectedSeats.isNotEmpty) {
      for (final seat in selectedSeats) {
        if (width != null && height != null) {
          ref.read(seatLayoutProvider.notifier).resizeSeat(seat.id, width, height);
        }
        if (rotation != null) {
          ref.read(seatLayoutProvider.notifier).rotateSeat(seat.id, rotation);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutData = ref.watch(seatLayoutProvider);
    final showSettingsPopup = ref.watch(settingsPopupVisibilityProvider);
    final keyboardHandler = ref.watch(keyboardHandlerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: PopScope(
        canPop: true, // 닫기 허용
        child: Stack(
          children: [
            // 전체 화면 캔버스
            Positioned.fill(
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                canRequestFocus: true,
                onKeyEvent: keyboardHandler.handleKeyEvent,
                child: GestureDetector(
                  onTap: () {
                    // 캔버스를 클릭하면 포커스를 다시 요청하고 모든 좌석 선택 해제
                    _focusNode.requestFocus();
                    ref.read(seatLayoutProvider.notifier).clearSelection();
                  },
                  child: SeatCanvasWidget(
                    key: _canvasKey,
                    layoutData: layoutData,
                    onSeatTap: _handleSeatTap,
                    onSeatDrag: _handleSeatDrag,
                  ),
                ),
              ),
            ),
            // 상단 버튼들
            _buildTopButtons(),
            // 설정 팝업
            if (showSettingsPopup) _buildSettingsPopup(),
          ],
        ),
      ),
    );
  }

  /// 상단 버튼들 생성
  Widget _buildTopButtons() {
    return Positioned(
      top: SeatLayoutConstants.topButtonsTop,
      left: SeatLayoutConstants.topButtonsLeft,
      child: Row(
        children: [
          // 돌아가기 버튼
          _buildBackButton(),
          const SizedBox(width: SeatLayoutConstants.buttonSpacing),
          // 설정 버튼
          _buildSettingsButton(),
        ],
      ),
    );
  }

  /// 돌아가기 버튼 생성
  Widget _buildBackButton() {
    return StyledButtonWrapper(
      child: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back),
        tooltip: SeatLayoutConstants.backButtonTooltip,
      ),
    );
  }

  /// 설정 버튼 생성
  Widget _buildSettingsButton() {
    return StyledButtonWrapper(
      child: TextButton(
        onPressed: () {
          ref.read(settingsPopupVisibilityProvider.notifier).update((state) => !state);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: SeatLayoutConstants.buttonPadding,
            vertical: SeatLayoutConstants.buttonVerticalPadding,
          ),
        ),
        child: const Text('설정'),
      ),
    );
  }

  /// 설정 팝업 생성
  Widget _buildSettingsPopup() {
    return SettingsPopupWidget(
      onClose: () {
        ref.read(settingsPopupVisibilityProvider.notifier).state = false;
      },
      onApplyLayoutSettings: _applyLayoutSettings,
      onResetCanvasPosition: _resetCanvasPosition,
      onAddSeats: _addSeats,
      onApplySelectedSeatSettings: _applySelectedSeatSettings,
    );
  }
}
