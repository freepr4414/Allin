enum SeatStatus {
  available,
  occupied,
  reserved,
  maintenance,
  outOfOrder,
  cleaning;

  String get displayName {
    switch (this) {
      case SeatStatus.available:
        return '사용 가능';
      case SeatStatus.occupied:
        return '사용 중';
      case SeatStatus.reserved:
        return '예약됨';
      case SeatStatus.maintenance:
        return '점검 중';
      case SeatStatus.outOfOrder:
        return '고장';
      case SeatStatus.cleaning:
        return '청소 중';
    }
  }

  String get statusText {
    switch (this) {
      case SeatStatus.available:
        return '사용 가능';
      case SeatStatus.occupied:
        return '사용 중';
      case SeatStatus.reserved:
        return '예약됨';
      case SeatStatus.maintenance:
        return '점검';
      case SeatStatus.outOfOrder:
        return '고장';
      case SeatStatus.cleaning:
        return '청소';
    }
  }
}

enum SeatType {
  standard,
  premium,
  study,
  meeting;

  String get displayName {
    switch (this) {
      case SeatType.standard:
        return '일반석';
      case SeatType.premium:
        return '프리미엄석';
      case SeatType.study:
        return '스터디룸';
      case SeatType.meeting:
        return '회의실';
    }
  }

  String get typeText {
    switch (this) {
      case SeatType.standard:
        return '일반';
      case SeatType.premium:
        return '프리미엄';
      case SeatType.study:
        return '스터디';
      case SeatType.meeting:
        return '회의';
    }
  }
}

class Seat {
  final String id;
  final String number;
  final SeatType type;
  final SeatStatus status;
  final String? userId;
  final String? userName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? remainingMinutes;
  final bool isSelected;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const Seat({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    this.userId,
    this.userName,
    this.startTime,
    this.endTime,
    this.remainingMinutes,
    this.isSelected = false,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 80.0,
    this.height = 80.0,
    this.rotation = 0.0,
  });

  Seat copyWith({
    String? id,
    String? number,
    SeatType? type,
    SeatStatus? status,
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    int? remainingMinutes,
    bool? isSelected,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
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
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isSelected: isSelected ?? this.isSelected,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  String get remainingTimeText {
    if (remainingMinutes == null) return '';

    final hours = remainingMinutes! ~/ 60;
    final minutes = remainingMinutes! % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  @override
  String toString() {
    return 'Seat(id: $id, number: $number, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Seat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
