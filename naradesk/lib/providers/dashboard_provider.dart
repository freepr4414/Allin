import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../models/member.dart';
import '../models/payment_model.dart';
import '../models/seat.dart';
import 'member_provider.dart';
import 'payment_provider.dart';
import 'seat_provider.dart';

final dashboardProvider = Provider<DashboardStats>((ref) {
  final seats = ref.watch(seatProvider);
  final members = ref.watch(memberProvider);
  final payments = ref.watch(paymentProvider);

  // 오늘 수익 계산
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final todayPayments = payments.where(
    (payment) =>
        payment.paymentDate.isAfter(todayStart) &&
        payment.paymentDate.isBefore(todayEnd) &&
        payment.status == PaymentStatus.completed,
  );

  final todayRevenue = todayPayments.fold(0.0, (sum, payment) => sum + payment.amount);

  // 이번 달 수익 계산
  final monthStart = DateTime(today.year, today.month, 1);
  final monthEnd = DateTime(today.year, today.month + 1, 1);

  final monthPayments = payments.where(
    (payment) =>
        payment.paymentDate.isAfter(monthStart) &&
        payment.paymentDate.isBefore(monthEnd) &&
        payment.status == PaymentStatus.completed,
  );

  final monthlyRevenue = monthPayments.fold(0.0, (sum, payment) => sum + payment.amount);

  // 활성 회원 수 계산
  final activeMembers = members.where((member) => member.status == MemberStatus.active).length;

  // 점유된 좌석 수 계산
  final occupiedSeats = seats.where((seat) => seat.status == SeatStatus.occupied).length;

  // 일일 사용량 데이터 (최근 7일)
  final dailyUsageData = List.generate(7, (index) {
    final date = DateTime.now().subtract(Duration(days: 6 - index));
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayPayments = payments.where(
      (payment) =>
          payment.paymentDate.isAfter(dayStart) &&
          payment.paymentDate.isBefore(dayEnd) &&
          payment.status == PaymentStatus.completed,
    );

    return DailyUsage(
      date: date,
      userCount: (15 + (index * 5) + (index.isEven ? 10 : -5)).clamp(10, 50), // 샘플 데이터
      revenue: dayPayments.fold(0.0, (sum, payment) => sum + payment.amount),
    );
  });

  // 시간대별 사용량 데이터
  final hourlyUsageData = List.generate(24, (hour) {
    // 시간대별 사용 패턴 시뮬레이션
    int userCount;
    if (hour >= 9 && hour <= 12) {
      userCount = 25 + (hour - 9) * 5; // 오전 피크
    } else if (hour >= 13 && hour <= 18) {
      userCount = 35 + (hour - 13) * 3; // 오후 피크
    } else if (hour >= 19 && hour <= 22) {
      userCount = 40 + (22 - hour) * 2; // 저녁 피크
    } else {
      userCount = (5 + hour).clamp(1, 15); // 심야/새벽
    }

    return HourlyUsage(hour: hour, userCount: userCount);
  });

  // 좌석 유형별 사용량
  final seatTypeUsage = <String, int>{};
  for (final seat in seats) {
    final typeName = seat.type.displayName;
    seatTypeUsage[typeName] =
        (seatTypeUsage[typeName] ?? 0) + (seat.status == SeatStatus.occupied ? 1 : 0);
  }

  return DashboardStats(
    totalMembers: members.length,
    activeMembers: activeMembers,
    totalSeats: seats.length,
    occupiedSeats: occupiedSeats,
    todayRevenue: todayRevenue,
    monthlyRevenue: monthlyRevenue,
    dailyUsageData: dailyUsageData,
    hourlyUsageData: hourlyUsageData,
    seatTypeUsage: seatTypeUsage,
  );
});
