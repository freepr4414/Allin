class DashboardStats {
  final int totalMembers;
  final int activeMembers;
  final int totalSeats;
  final int occupiedSeats;
  final double todayRevenue;
  final double monthlyRevenue;
  final List<DailyUsage> dailyUsageData;
  final List<HourlyUsage> hourlyUsageData;
  final Map<String, int> seatTypeUsage;

  DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.dailyUsageData,
    required this.hourlyUsageData,
    required this.seatTypeUsage,
  });
}

class DailyUsage {
  final DateTime date;
  final int userCount;
  final double revenue;

  DailyUsage({required this.date, required this.userCount, required this.revenue});
}

class HourlyUsage {
  final int hour;
  final int userCount;

  HourlyUsage({required this.hour, required this.userCount});
}

class MonthlyRevenue {
  final int month;
  final double revenue;

  MonthlyRevenue({required this.month, required this.revenue});
}
