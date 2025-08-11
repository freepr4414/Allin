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
    double? rotation,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    // 새로운 배치도 크기
    final newWidth = width ?? state.width;
    final newHeight = height ?? state.height;
    
    // 배치도 크기가 줄어들 때 좌석들이 범위를 벗어나는지 확인하고 조정
    final adjustedSeats = state.seats.map((seat) {
      // 좌석이 새로운 배치도 범위를 벗어나는지 확인
      final seatRight = seat.x + seat.width;
      final seatBottom = seat.y + seat.height;
      
      bool needsAdjustment = false;
      double newX = seat.x;
      double newY = seat.y;
      
      // 좌석이 새로운 배치도 경계를 벗어나는 경우
      if (seat.x < 0 || seat.y < 0 || seatRight > newWidth || seatBottom > newHeight) {
        needsAdjustment = true;
        newX = 0.0; // 좌측 코너
        newY = 0.0; // 상단 코너
      }
      
      if (needsAdjustment) {
        return seat.copyWith(x: newX, y: newY);
      }
      
      return seat;
    }).toList();

    state = state.copyWith(
      top: top ?? state.top,
      left: left ?? state.left,
      width: newWidth,
      height: newHeight,
      rotation: rotation ?? state.rotation,
      backgroundColor: backgroundColor ?? state.backgroundColor,
      borderColor: borderColor ?? state.borderColor,
      seats: adjustedSeats, // 조정된 좌석 목록 적용
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
          x: 0.0, // 모든 좌석을 left 0에 생성
          y: 0.0, // 모든 좌석을 top 0에 생성
          width: SeatLayoutConstants.defaultSeatWidth,
          height: SeatLayoutConstants.defaultSeatHeight,
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

    // 선택된 좌석을 최상위로 올리기
    bringToFront(seatId);
  }

  /// 좌석을 최상위로 올리기
  void bringToFront(String seatId) {
    final seatIndex = state.seats.indexWhere((seat) => seat.id == seatId);
    if (seatIndex == -1 || seatIndex == state.seats.length - 1) {
      return; // 좌석을 찾을 수 없거나 이미 최상위에 있는 경우
    }

    final seat = state.seats[seatIndex];
    final newSeats = List<Seat>.from(state.seats);
    newSeats.removeAt(seatIndex);
    newSeats.add(seat); // 리스트 끝에 추가하여 최상위로 만들기

    state = state.copyWith(seats: newSeats);
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

  /// 저장된 좌석 배치도 로드
  void loadSavedLayout({
    required List<Seat> seats,
    required double top,
    required double left,
    required double width,
    required double height,
    double rotation = 0,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    state = SeatLayoutData(
      seats: seats,
      top: top,
      left: left,
      width: width,
      height: height,
      rotation: rotation,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }

  /// 배치도 회전 (90도 단위, 실제 데이터 변환)
  void rotateLayout(bool clockwise) {
    final currentData = state;
    
    // 배치도 크기 변환 (width <-> height)
    final newWidth = currentData.height;
    final newHeight = currentData.width;
    
    // 모든 좌석의 좌표와 크기 변환
    final transformedSeats = currentData.seats.map((seat) {
      if (clockwise) {
        // 시계방향 90도 회전: (x, y) -> (height - y - seatHeight, x)
        final newX = currentData.height - seat.y - seat.height;
        final newY = seat.x;
        return seat.copyWith(
          x: newX,
          y: newY,
          width: seat.height, // 좌석 크기도 회전
          height: seat.width,
        );
      } else {
        // 반시계방향 90도 회전: (x, y) -> (y, width - x - seatWidth)
        final newX = seat.y;
        final newY = currentData.width - seat.x - seat.width;
        return seat.copyWith(
          x: newX,
          y: newY,
          width: seat.height, // 좌석 크기도 회전
          height: seat.width,
        );
      }
    }).toList();
    
    // 새로운 배치도 데이터 생성 (rotation은 항상 0으로 유지)
    state = currentData.copyWith(
      width: newWidth,
      height: newHeight,
      rotation: 0, // 항상 0으로 유지하여 단순화
      seats: transformedSeats,
    );
  }
}
