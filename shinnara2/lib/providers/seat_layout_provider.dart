import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/seat_layout_constants.dart';
import '../models/seat_layout_models.dart';

/// 좌석 배치도 상태 관리 Provider
final seatLayoutProvider = StateNotifierProvider<SeatLayoutNotifier, SeatLayoutData>((ref) {
  return SeatLayoutNotifier();
});

/// 좌석 배치도 상태 관리 클래스
class SeatLayoutNotifier extends StateNotifier<SeatLayoutData> {
  SeatLayoutNotifier() : super(const SeatLayoutData());

  /// 배치도 설정 업데이트
  void updateLayoutSettings({
    double? top,
    double? left,
    double? width,
    double? height,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    state = state.copyWith(
      top: top ?? state.top,
      left: left ?? state.left,
      width: width ?? state.width,
      height: height ?? state.height,
      backgroundColor: backgroundColor ?? state.backgroundColor,
      borderColor: borderColor ?? state.borderColor,
    );
  }

  /// 좌석 생성
  void addSeats(int startNumber, int endNumber) {
    final newSeats = <Seat>[];

    for (int i = startNumber; i <= endNumber; i++) {
      newSeats.add(
        Seat(
          id: 'seat_$i',
          number: i.toString(),
          x: 100.0 + (i - startNumber) * 60.0,
          y: 100.0,
          width: SeatLayoutConstants.defaultSeatWidth,
          height: SeatLayoutConstants.defaultSeatHeight,
          rotation: 0.0,
          backgroundColor: SeatLayoutConstants.defaultSeatBackgroundColor,
          isSelected: false,
        ),
      );
    }

    state = state.copyWith(seats: [...state.seats, ...newSeats]);
  }

  /// 좌석 선택/해제
  void selectSeat(String seatId, bool isCtrlPressed) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.id == seatId) {
        if (isCtrlPressed) {
          return seat.copyWith(isSelected: !seat.isSelected);
        } else {
          return seat.copyWith(isSelected: true);
        }
      } else if (!isCtrlPressed) {
        return seat.copyWith(isSelected: false);
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 모든 좌석 선택 해제
  void clearSelection() {
    final updatedSeats = state.seats.map((seat) {
      return seat.copyWith(isSelected: false);
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 좌석 이동
  void moveSeat(String seatId, double deltaX, double deltaY) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(x: seat.x + deltaX, y: seat.y + deltaY);
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 선택된 좌석들 이동
  void moveSelectedSeats(double deltaX, double deltaY) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.isSelected) {
        return seat.copyWith(x: seat.x + deltaX, y: seat.y + deltaY);
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 선택된 좌석들 크기 조절
  void resizeSelectedSeats(double deltaWidth, double deltaHeight) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.isSelected) {
        return seat.copyWith(
          width: (seat.width + deltaWidth).clamp(
            SeatLayoutConstants.minSeatSize,
            SeatLayoutConstants.maxSeatSize,
          ),
          height: (seat.height + deltaHeight).clamp(
            SeatLayoutConstants.minSeatSize,
            SeatLayoutConstants.maxSeatSize,
          ),
        );
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 좌석 크기 조절
  void resizeSeat(String seatId, double width, double height) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(
          width: width.clamp(SeatLayoutConstants.minSeatSize, SeatLayoutConstants.maxSeatSize),
          height: height.clamp(SeatLayoutConstants.minSeatSize, SeatLayoutConstants.maxSeatSize),
        );
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 좌석 회전
  void rotateSeat(String seatId, double rotation) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(rotation: rotation);
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 선택된 좌석들 삭제
  void deleteSelectedSeats() {
    final updatedSeats = state.seats.where((seat) => !seat.isSelected).toList();
    state = state.copyWith(seats: updatedSeats);
  }

  /// 좌석 배경색 변경
  void changeSeatBackgroundColor(String seatId, Color color) {
    final updatedSeats = state.seats.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(backgroundColor: color);
      }
      return seat;
    }).toList();

    state = state.copyWith(seats: updatedSeats);
  }

  /// 모든 좌석 삭제
  void clearAllSeats() {
    state = state.copyWith(seats: []);
  }

  /// 배치도 리셋 (기본값으로)
  void resetLayout() {
    state = const SeatLayoutData();
  }
}
