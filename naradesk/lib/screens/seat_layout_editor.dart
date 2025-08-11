import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/saved_seat_layout.dart';
import '../models/seat_layout_models.dart';
import '../providers/lock_state_provider.dart';
import '../providers/save_state_provider.dart';
import '../providers/seat_layout_provider.dart';
import '../providers/seat_provider.dart';
import '../providers/ui_state_provider.dart';
import '../services/seat_layout_storage_service.dart';
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
  final GlobalKey<SeatCanvasWidgetState> _canvasKey =
      GlobalKey<SeatCanvasWidgetState>();

  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 포커스를 요청하고 저장된 배치도 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadSavedLayout();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 저장된 좌석 배치도 로드
  Future<void> _loadSavedLayout() async {
    try {
      final savedLayout = await SeatLayoutStorageService.loadSeatLayout();

      if (savedLayout != null) {
        // 저장된 좌석 데이터를 편집기 모델로 변환
        final List<Seat> seats = savedLayout.seats.map((seatData) {
          return Seat(
            id: seatData.id,
            x: seatData.x,
            y: seatData.y,
            width: seatData.width,
            height: seatData.height,
            number: seatData.number,
            backgroundColor: Color(seatData.colorValue),
            isSelected: false,
          );
        }).toList();

        // 레이아웃 설정도 복원
        final layoutSettings = savedLayout.layoutSettings;

        // 편집기 상태에 로드된 데이터 적용
        ref
            .read(seatLayoutProvider.notifier)
            .loadSavedLayout(
              seats: seats,
              top: layoutSettings.top,
              left: layoutSettings.left,
              width: layoutSettings.width,
              height: layoutSettings.height,
              rotation: layoutSettings.rotation,
              backgroundColor: Color(layoutSettings.backgroundColorValue),
              borderColor: Color(layoutSettings.borderColorValue),
            );
      }
    } catch (e) {
      debugPrint('저장된 배치도 로드 실패: $e');
      // 에러가 발생해도 편집기는 정상적으로 시작되도록 함
    }
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
    // 좌석 배치 변경 잠금 확인
    final seatEditLock = ref.read(seatEditLockProvider);
    if (seatEditLock) return; // 잠금 상태면 드래그 무시

    ref
        .read(seatLayoutProvider.notifier)
        .moveSeat(seat.id, details.delta.dx, details.delta.dy);
  }

  /// 배치도 설정 적용
  void _applyLayoutSettings(
    double top,
    double left,
    double width,
    double height,
  ) {
    ref
        .read(seatLayoutProvider.notifier)
        .updateLayoutSettings(
          top: top,
          left: left,
          width: width,
          height: height,
        );

    // 메인 화면의 배치도 설정도 업데이트
    ref.read(seatProvider.notifier).notifyLayoutSettingsChanged();
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
  void _applySelectedSeatSettings(double? width, double? height) {
    // 좌석 배치 변경 잠금 확인
    final seatEditLock = ref.read(seatEditLockProvider);
    if (seatEditLock) return; // 잠금 상태면 설정 적용 무시

    final layoutData = ref.read(seatLayoutProvider);
    final selectedSeats = layoutData.seats
        .where((seat) => seat.isSelected)
        .toList();

    if (selectedSeats.isNotEmpty) {
      for (final seat in selectedSeats) {
        if (width != null && height != null) {
          ref
              .read(seatLayoutProvider.notifier)
              .resizeSeat(seat.id, width, height);
        }
        // rotation 관련 코드 제거 - 개별 좌석 회전 기능 없음
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
          // 저장 버튼
          _buildSaveButton(),
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
          print('🎨 [SETTINGS_BUTTON] 설정 버튼 클릭됨');
          final currentState = ref.read(settingsPopupVisibilityProvider);
          print('🎨 [SETTINGS_BUTTON] 현재 팝업 상태: $currentState');
          ref
              .read(settingsPopupVisibilityProvider.notifier)
              .update((state) => !state);
          final newState = ref.read(settingsPopupVisibilityProvider);
          print('🎨 [SETTINGS_BUTTON] 변경된 팝업 상태: $newState');
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

  /// 저장 버튼 생성
  Widget _buildSaveButton() {
    final saveState = ref.watch(saveStateProvider);
    final isLoading = saveState.status == SaveStatus.saving;

    return StyledButtonWrapper(
      child: TextButton(
        onPressed: isLoading
            ? null
            : () {
                _saveSeatLayout();
              },
        style: TextButton.styleFrom(
          backgroundColor: isLoading ? Colors.grey : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: SeatLayoutConstants.buttonPadding,
            vertical: SeatLayoutConstants.buttonVerticalPadding,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.save, size: 16),
            const SizedBox(width: 4),
            Text(isLoading ? '저장중...' : '저장'),
          ],
        ),
      ),
    );
  }

  /// 좌석 배치도 저장
  Future<void> _saveSeatLayout() async {
    try {
      // 현재 좌석 레이아웃 데이터 가져오기
      final layoutData = ref.read(seatLayoutProvider);

      // 좌석 데이터 변환
      final List<SeatData> seatDataList = layoutData.seats.map((seat) {
        return SeatData(
          id: seat.id,
          x: seat.x,
          y: seat.y,
          width: seat.width,
          height: seat.height,
          number: seat.number,
          colorValue: seat.backgroundColor.toARGB32(),
        );
      }).toList();

      // 레이아웃 설정 변환
      final layoutSettings = LayoutSettings(
        top: layoutData.top,
        left: layoutData.left,
        width: layoutData.width,
        height: layoutData.height,
        backgroundColorValue: layoutData.backgroundColor.toARGB32(),
        borderColorValue: layoutData.borderColor.toARGB32(),
        rotation: layoutData.rotation,
      );

      // 저장할 데이터 생성
      final savedLayout = SavedSeatLayout(
        seats: seatDataList,
        layoutSettings: layoutSettings,
        savedAt: DateTime.now(),
      );

      // 실제 저장 수행 (context 전달)
      final success = await ref
          .read(saveStateProvider.notifier)
          .saveSeatLayout(savedLayout, context: context);

      // mounted 체크 추가
      if (!mounted) return;

      if (success) {
        // 메인화면에 변경사항 알림 (글로벌 상태 업데이트)
        _notifyMainScreenUpdate();
      }
      // 실패 시에는 팝업이 이미 표시되므로 별도 메시지 불필요
    } catch (e) {
      // mounted 체크 추가
      if (!mounted) return;

      // 심각한 에러는 여전히 SnackBar로 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('저장 중 오류가 발생했습니다: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 메인화면에 업데이트 알림
  void _notifyMainScreenUpdate() {
    // 메인화면 좌석 Provider에 저장된 배치도 적용 요청
    ref.read(seatProvider.notifier).applySavedLayout();
    // 배치도 설정 변경 알림 (캔버스 크기 업데이트를 위해)
    ref.read(seatProvider.notifier).notifyLayoutSettingsChanged();
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
      onRotateLayout: _rotateLayout,
    );
  }

  /// 배치도 회전 핸들러
  void _rotateLayout(bool clockwise) {
    ref.read(seatLayoutProvider.notifier).rotateLayout(clockwise);
  }
}
