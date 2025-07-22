import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';

class SeatNotifier extends StateNotifier<List<Seat>> {
  SeatNotifier() : super(_generateInitialSeats());

  static List<Seat> _generateInitialSeats() {
    return List.generate(48, (index) {
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

      return Seat(
        id: 'seat_$seatNumber',
        number: seatNumber,
        type: seatType,
        status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
        userId: isOccupied ? 'user_${index + 1}' : null,
        userName: isOccupied ? '사용자 ${index + 1}' : null,
        startTime: isOccupied ? DateTime.now().subtract(Duration(minutes: index * 10)) : null,
        endTime: isOccupied ? DateTime.now().add(Duration(hours: 2 + index % 4)) : null,
        remainingMinutes: isOccupied ? (120 + index * 30) % 300 : null,
      );
    });
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
