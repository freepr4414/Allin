import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';
import '../services/seat_layout_storage_service.dart';

class SeatNotifier extends StateNotifier<List<Seat>> {
  SeatNotifier() : super([]);  // 빈 리스트로 시작

  static List<Seat> _generateInitialSeats() {
    // 8x6 그리드 형태로 초기 좌석 배치 (기본 위치 설정)
    final seats = List.generate(48, (index) {
      final seatNumber = (index + 1).toString().padLeft(2, '0');
      final seatType = index < 16
          ? SeatType.standard
          : index < 32
          ? SeatType.premium
          : index < 40
          ? SeatType.study
          : SeatType.meeting;

      // 일부 좌석을 사용 중으로 설정
      final isOccupied = [2, 5, 8, 12, 15, 20, 25, 30].contains(index + 1);

      // 8x6 그리드 배치 계산
      final row = index ~/ 8;
      final col = index % 8;
      final x = 50.0 + col * 100.0; // 좌석 간격 100px
      final y = 50.0 + row * 100.0;

      final seat = Seat(
        id: 'seat_$seatNumber',
        number: seatNumber,
        type: seatType,
        status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
        userId: isOccupied ? 'user_${index + 1}' : null,
        userName: isOccupied ? '사용자 ${index + 1}' : null,
        startTime: isOccupied ? DateTime.now().subtract(Duration(minutes: index * 10)) : null,
        endTime: isOccupied ? DateTime.now().add(Duration(hours: 2 + index % 4)) : null,
        remainingMinutes: isOccupied ? (120 + index * 30) % 300 : null,
        x: x,
        y: y,
        width: 80.0,
        height: 80.0,
        rotation: 0.0,
      );
      
      return seat;
    });
    
    return seats;
  }

  void updateSeatStatus(String seatId, SeatStatus status) {
    state = state.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(status: status);
      }
      return seat;
    }).toList();
  }

  void selectSeat(String seatId) {
    state = state.map((seat) {
      return seat.copyWith(isSelected: seat.id == seatId);
    }).toList();
  }

  void clearSelection() {
    state = state.map((seat) {
      return seat.copyWith(isSelected: false);
    }).toList();
  }

  void checkInSeat(String seatId, String userId, String userName, int hours) {
    final now = DateTime.now();
    state = state.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(
          status: SeatStatus.occupied,
          userId: userId,
          userName: userName,
          startTime: now,
          endTime: now.add(Duration(hours: hours)),
          remainingMinutes: hours * 60,
        );
      }
      return seat;
    }).toList();
  }

  void checkOutSeat(String seatId) {
    state = state.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(
          status: SeatStatus.available,
          userId: null,
          userName: null,
          startTime: null,
          endTime: null,
          remainingMinutes: null,
        );
      }
      return seat;
    }).toList();
  }

  void extendTime(String seatId, int additionalMinutes) {
    state = state.map((seat) {
      if (seat.id == seatId && seat.remainingMinutes != null) {
        final newRemainingMinutes = seat.remainingMinutes! + additionalMinutes;
        final newEndTime = seat.endTime?.add(Duration(minutes: additionalMinutes));
        return seat.copyWith(remainingMinutes: newRemainingMinutes, endTime: newEndTime);
      }
      return seat;
    }).toList();
  }

  Map<SeatStatus, int> getSeatStatistics() {
    final stats = <SeatStatus, int>{};
    for (final status in SeatStatus.values) {
      stats[status] = state.where((seat) => seat.status == status).length;
    }
    return stats;
  }

  List<Seat> getOccupiedSeats() {
    return state.where((seat) => seat.status == SeatStatus.occupied).toList();
  }

  Seat? getSeatById(String seatId) {
    try {
      return state.firstWhere((seat) => seat.id == seatId);
    } catch (e) {
      return null;
    }
  }

  /// 현재 배치도 설정 가져오기
  Future<Map<String, double>> getLayoutSettings() async {
    try {
      final savedLayout = await SeatLayoutStorageService.loadSeatLayout();
      if (savedLayout != null) {
        return {
          'left': savedLayout.layoutSettings.left,
          'top': savedLayout.layoutSettings.top,
          'width': savedLayout.layoutSettings.width,
          'height': savedLayout.layoutSettings.height,
        };
      }
    } catch (e) {
      debugPrint('배치도 설정 로드 실패: $e');
    }
    
    // 기본값 반환
    return {
      'left': 0.0,
      'top': 0.0,
      'width': 1800.0,
      'height': 900.0,
    };
  }

  /// 저장된 좌석 배치도를 메인화면에 적용
  Future<void> applySavedLayout() async {
    try {
      final savedLayout = await SeatLayoutStorageService.loadSeatLayout();
      if (savedLayout == null) return;

      // 현재 좌석 상태(사용중, 예약 등)를 유지하면서 위치/크기만 업데이트
      final Map<String, Seat> currentSeatsMap = {
        for (final seat in state) seat.id: seat
      };

      final List<Seat> updatedSeats = [];

      for (final savedSeat in savedLayout.seats) {
        final currentSeat = currentSeatsMap[savedSeat.id];
        if (currentSeat != null) {
          // 기존 좌석 상태는 유지하고 위치/크기만 저장된 값으로 업데이트
          final updatedSeat = currentSeat.copyWith(
            x: savedSeat.x,
            y: savedSeat.y,
            width: savedSeat.width,
            height: savedSeat.height,
            number: savedSeat.number, // 좌석 번호도 업데이트
          );
          
          updatedSeats.add(updatedSeat);
        } else {
          // 새로운 좌석이면 기본 상태로 추가 (편집기에서 새로 생성된 좌석)
          updatedSeats.add(Seat(
            id: savedSeat.id,
            number: savedSeat.number,
            type: SeatType.standard,
            status: SeatStatus.available,
            x: savedSeat.x,
            y: savedSeat.y,
            width: savedSeat.width,
            height: savedSeat.height,
          ));
        }
      }

      state = updatedSeats;
    } catch (e) {
      debugPrint('저장된 배치도 적용 실패: $e');
    }
  }

  /// 앱 시작 시 저장된 배치도 자동 로드
  Future<void> initializeWithSavedLayout() async {
    try {
      final savedLayout = await SeatLayoutStorageService.loadSeatLayout();
      
      if (savedLayout != null) {
        // 기본 좌석 데이터를 먼저 생성 (사용중 상태와 시간 정보 포함)
        final defaultSeats = _generateInitialSeats();
        final defaultSeatsMap = {for (final seat in defaultSeats) seat.id: seat};
        
        // 저장된 배치도의 위치/크기와 기본 좌석의 상태 정보를 결합
        final List<Seat> seats = [];
        
        for (final savedSeat in savedLayout.seats) {
          final defaultSeat = defaultSeatsMap[savedSeat.id];
          
          if (defaultSeat != null) {
            // 기본 좌석 상태 정보는 유지하고 위치/크기만 저장된 값 사용
            seats.add(defaultSeat.copyWith(
              x: savedSeat.x,
              y: savedSeat.y,
              width: savedSeat.width,
              height: savedSeat.height,
              number: savedSeat.number,
            ));
          } else {
            // 새로운 좌석이면 기본 상태로 추가
            seats.add(Seat(
              id: savedSeat.id,
              number: savedSeat.number,
              type: SeatType.standard,
              status: SeatStatus.available,
              x: savedSeat.x,
              y: savedSeat.y,
              width: savedSeat.width,
              height: savedSeat.height,
            ));
          }
        }
        
        state = seats;
      } else {
        // 저장된 배치도가 없으면 기본 좌석 생성
        final defaultSeats = _generateInitialSeats();
        state = defaultSeats;
      }
    } catch (e) {
      debugPrint('저장된 배치도 초기화 실패: $e');
      // 에러 발생 시 기본 좌석으로 폴백
      final fallbackSeats = _generateInitialSeats();
      state = fallbackSeats;
    }
  }

  /// 배치도 설정이 변경되었음을 알리는 메서드 (UI 갱신용)
  void notifyLayoutSettingsChanged() {
    // state를 동일한 값으로 다시 할당하여 리스너들에게 변경을 알림
    state = [...state];
  }
}

final seatProvider = StateNotifierProvider<SeatNotifier, List<Seat>>((ref) {
  return SeatNotifier();
});

final selectedSeatProvider = Provider<Seat?>((ref) {
  final seats = ref.watch(seatProvider);
  try {
    return seats.firstWhere((seat) => seat.isSelected);
  } catch (e) {
    return null;
  }
});

final seatStatisticsProvider = Provider<Map<SeatStatus, int>>((ref) {
  return ref.read(seatProvider.notifier).getSeatStatistics();
});

final occupiedSeatsProvider = Provider<List<Seat>>((ref) {
  return ref.read(seatProvider.notifier).getOccupiedSeats();
});
