class Payment {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod method;
  final PaymentType type;
  final PaymentStatus status;
  final String? description;

  Payment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.paymentDate,
    required this.method,
    required this.type,
    required this.status,
    this.description,
  });

  Payment copyWith({
    String? id,
    String? memberId,
    String? memberName,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? method,
    PaymentType? type,
    PaymentStatus? status,
    String? description,
  }) {
    return Payment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}

enum PaymentMethod {
  cash('현금'),
  card('카드'),
  transfer('계좌이체'),
  mobile('모바일결제');

  const PaymentMethod(this.displayName);
  final String displayName;
}

enum PaymentType {
  timePass('시간권'),
  monthlyPass('월정액'),
  deposit('보증금'),
  refund('환불');

  const PaymentType(this.displayName);
  final String displayName;
}

enum PaymentStatus {
  completed('완료'),
  pending('대기'),
  cancelled('취소'),
  failed('실패');

  const PaymentStatus(this.displayName);
  final String displayName;
}
