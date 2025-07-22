import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seat.dart';

class SeatNotifier extends StateNotifier<List<Seat>> {
  SeatNotifier() : super(_generateInitialSeats());

  static List<Seat> _generateInitialSeats() {
    final seats = <Seat>[];

    // 6x8 좌석 배치 (48개 좌석)
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 8; col++) {
        final seatNumber = row * 8 + col + 1;
        seats.add(
          Seat(
            id: 'seat_$seatNumber',
            number: seatNumber,
            type: _getSeatType(seatNumber),
            status: SeatStatus.available,
            x: col * 120.0 + 60.0, // 좌석 간격 120px
            y: row * 100.0 + 60.0, // 행 간격 100px
          ),
        );
      }
    }

    return seats;
  }

  static SeatType _getSeatType(int seatNumber) {
    if (seatNumber <= 8) return SeatType.premium; // 첫 번째 줄은 프리미엄석
    if (seatNumber >= 41) return SeatType.group; // 마지막 줄은 그룹석
    if (seatNumber % 8 == 1 || seatNumber % 8 == 0) return SeatType.phone; // 양쪽 끝은 폰부스
    return SeatType.standard;
  }

  void updateSeatStatus(
    String seatId,
    SeatStatus newStatus, {
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    state = state.map((seat) {
      if (seat.id == seatId) {
        return seat.copyWith(
          status: newStatus,
          userId: userId,
          userName: userName,
          startTime: startTime,
          endTime: endTime,
        );
      }
      return seat;
    }).toList();
  }

  void checkinSeat(String seatId, String userId, String userName) {
    updateSeatStatus(
      seatId,
      SeatStatus.occupied,
      userId: userId,
      userName: userName,
      startTime: DateTime.now(),
    );
  }

  void checkoutSeat(String seatId) {
    updateSeatStatus(
      seatId,
      SeatStatus.available,
      userId: null,
      userName: null,
      startTime: null,
      endTime: null,
    );
  }

  void setSeatAway(String seatId) {
    updateSeatStatus(seatId, SeatStatus.away);
  }

  void returnFromAway(String seatId) {
    updateSeatStatus(seatId, SeatStatus.occupied);
  }
}

final seatProvider = StateNotifierProvider<SeatNotifier, List<Seat>>((ref) {
  return SeatNotifier();
});
