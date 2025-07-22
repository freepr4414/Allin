class Payment {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final PaymentType type;
  final PaymentStatus status;
  final String? description;

  const Payment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.description,
  });

  Payment copyWith({
    String? id,
    String? userId,
    String? userName,
    double? amount,
    DateTime? date,
    PaymentType? type,
    PaymentStatus? status,
    String? description,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}

enum PaymentType {
  timeCharge, // 시간 충전
  membership, // 멤버십
  deposit, // 보증금
  penalty, // 위약금
  refund, // 환불
}

enum PaymentStatus {
  completed, // 완료
  pending, // 대기중
  failed, // 실패
  cancelled, // 취소
  refunded, // 환불됨
}

extension PaymentTypeExtension on PaymentType {
  String get text {
    switch (this) {
      case PaymentType.timeCharge:
        return '시간충전';
      case PaymentType.membership:
        return '멤버십';
      case PaymentType.deposit:
        return '보증금';
      case PaymentType.penalty:
        return '위약금';
      case PaymentType.refund:
        return '환불';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get text {
    switch (this) {
      case PaymentStatus.completed:
        return '완료';
      case PaymentStatus.pending:
        return '대기중';
      case PaymentStatus.failed:
        return '실패';
      case PaymentStatus.cancelled:
        return '취소';
      case PaymentStatus.refunded:
        return '환불됨';
    }
  }
}
