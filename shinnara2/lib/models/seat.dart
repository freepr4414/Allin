class Seat {
  final String id;
  final int number;
  final SeatType type;
  final SeatStatus status;
  final String? userId; // 현재 사용 중인 회원 ID
  final String? userName; // 현재 사용 중인 회원 이름
  final DateTime? startTime; // 입실 시간
  final DateTime? endTime; // 예상 퇴실 시간
  final double x; // 좌석 배치도에서의 X 좌표
  final double y; // 좌석 배치도에서의 Y 좌표

  const Seat({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    this.userId,
    this.userName,
    this.startTime,
    this.endTime,
    required this.x,
    required this.y,
  });

  Seat copyWith({
    String? id,
    int? number,
    SeatType? type,
    SeatStatus? status,
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    double? x,
    double? y,
  }) {
    return Seat(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

enum SeatType { standard, premium, group, phone }

enum SeatStatus {
  available, // 사용 가능
  occupied, // 사용 중
  reserved, // 예약됨
  outOfOrder, // 고장
  cleaning, // 청소 중
  away, // 외출 중
}

extension SeatTypeExtension on SeatType {
  String get displayName {
    switch (this) {
      case SeatType.standard:
        return '일반석';
      case SeatType.premium:
        return '프리미엄석';
      case SeatType.group:
        return '그룹석';
      case SeatType.phone:
        return '폰부스';
    }
  }
}

extension SeatStatusExtension on SeatStatus {
  String get displayName {
    switch (this) {
      case SeatStatus.available:
        return '사용가능';
      case SeatStatus.occupied:
        return '사용중';
      case SeatStatus.reserved:
        return '예약됨';
      case SeatStatus.outOfOrder:
        return '고장';
      case SeatStatus.cleaning:
        return '청소중';
      case SeatStatus.away:
        return '외출중';
    }
  }
}
