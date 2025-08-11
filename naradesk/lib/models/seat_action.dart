import 'seat.dart';

enum SeatAction {
  registerMember,
  lightOn,
  lightOff,
  checkin,
  checkout,
  returnSeat,
  goOut,
  moveSeat,
}

extension SeatActionExtension on SeatAction {
  String get displayName {
    switch (this) {
      case SeatAction.registerMember:
        return '회원등록';
      case SeatAction.lightOn:
        return '점등';
      case SeatAction.lightOff:
        return '소등';
      case SeatAction.checkin:
        return '입실';
      case SeatAction.checkout:
        return '퇴실';
      case SeatAction.returnSeat:
        return '복귀';
      case SeatAction.goOut:
        return '외출';
      case SeatAction.moveSeat:
        return '좌석이동';
    }
  }

  bool isAvailableFor(SeatStatus status) {
    switch (this) {
      case SeatAction.registerMember:
        return status == SeatStatus.available;
      case SeatAction.checkin:
        return status == SeatStatus.available;
      case SeatAction.checkout:
        return status == SeatStatus.occupied;
      case SeatAction.goOut:
        return status == SeatStatus.occupied;
      case SeatAction.returnSeat:
        return status == SeatStatus.reserved;
      case SeatAction.moveSeat:
        return status == SeatStatus.occupied || status == SeatStatus.reserved;
      case SeatAction.lightOn:
      case SeatAction.lightOff:
        return status == SeatStatus.occupied;
    }
  }
}
