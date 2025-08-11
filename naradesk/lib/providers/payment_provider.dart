import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_model.dart';

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>((ref) {
  return PaymentNotifier();
});

class PaymentNotifier extends StateNotifier<List<Payment>> {
  PaymentNotifier() : super([]) {
    _loadSampleData();
  }

  void _loadSampleData() {
    final samplePayments = [
      Payment(
        id: '1',
        memberId: '1',
        memberName: '김철수',
        amount: 120000,
        paymentDate: DateTime.now().subtract(const Duration(days: 1)),
        method: PaymentMethod.card,
        type: PaymentType.monthlyPass,
        status: PaymentStatus.completed,
        description: '프리미엄 월정액',
      ),
      Payment(
        id: '2',
        memberId: '2',
        memberName: '박영희',
        amount: 15000,
        paymentDate: DateTime.now().subtract(const Duration(days: 2)),
        method: PaymentMethod.cash,
        type: PaymentType.timePass,
        status: PaymentStatus.completed,
        description: '5시간 이용권',
      ),
      Payment(
        id: '3',
        memberId: '3',
        memberName: '이민수',
        amount: 200000,
        paymentDate: DateTime.now().subtract(const Duration(days: 3)),
        method: PaymentMethod.transfer,
        type: PaymentType.monthlyPass,
        status: PaymentStatus.completed,
        description: 'VIP 월정액',
      ),
      Payment(
        id: '4',
        memberId: '4',
        memberName: '정수연',
        amount: 30000,
        paymentDate: DateTime.now().subtract(const Duration(days: 4)),
        method: PaymentMethod.mobile,
        type: PaymentType.timePass,
        status: PaymentStatus.pending,
        description: '10시간 이용권',
      ),
      Payment(
        id: '5',
        memberId: '1',
        memberName: '김철수',
        amount: 60000,
        paymentDate: DateTime.now().subtract(const Duration(days: 5)),
        method: PaymentMethod.card,
        type: PaymentType.timePass,
        status: PaymentStatus.completed,
        description: '20시간 이용권',
      ),
      Payment(
        id: '6',
        memberId: '5',
        memberName: '최현우',
        amount: 50000,
        paymentDate: DateTime.now().subtract(const Duration(days: 6)),
        method: PaymentMethod.cash,
        type: PaymentType.deposit,
        status: PaymentStatus.completed,
        description: '보증금',
      ),
      Payment(
        id: '7',
        memberId: '2',
        memberName: '박영희',
        amount: 90000,
        paymentDate: DateTime.now().subtract(const Duration(days: 7)),
        method: PaymentMethod.card,
        type: PaymentType.monthlyPass,
        status: PaymentStatus.completed,
        description: '기본 월정액',
      ),
    ];

    state = samplePayments;
  }

  void addPayment(Payment payment) {
    state = [...state, payment];
  }

  void updatePayment(String id, Payment updatedPayment) {
    state = [
      for (final payment in state)
        if (payment.id == id) updatedPayment else payment,
    ];
  }

  void deletePayment(String id) {
    state = state.where((payment) => payment.id != id).toList();
  }

  List<Payment> getRecentPayments({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return state.where((payment) => payment.paymentDate.isAfter(cutoffDate)).toList();
  }

  double getTotalRevenue({DateTime? startDate, DateTime? endDate}) {
    var payments = state.where((payment) => payment.status == PaymentStatus.completed);

    if (startDate != null) {
      payments = payments.where((payment) => payment.paymentDate.isAfter(startDate));
    }

    if (endDate != null) {
      payments = payments.where((payment) => payment.paymentDate.isBefore(endDate));
    }

    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  List<Payment> searchPayments(String query) {
    if (query.isEmpty) return state;

    return state
        .where(
          (payment) =>
              payment.memberName.toLowerCase().contains(query.toLowerCase()) ||
              payment.description?.toLowerCase().contains(query.toLowerCase()) == true ||
              payment.id.contains(query),
        )
        .toList();
  }
}
