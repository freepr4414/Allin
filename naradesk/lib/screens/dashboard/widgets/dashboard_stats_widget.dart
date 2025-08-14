import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/dashboard_provider.dart';
import '../../../utils/responsive.dart';
import '../../../utils/responsive_font.dart';

/// 대시보드 통계 카드 섹션 위젯
class DashboardStatsWidget extends ConsumerWidget {
  const DashboardStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardProvider);
    final currencyFormatter = NumberFormat('#,###', 'ko_KR');

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Responsive.getResponsiveValue(
          context,
          mobile: 2,
          tablet: 4,
          desktop: 4,
        ).toInt();

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Responsive.getResponsiveMargin(context),
          mainAxisSpacing: Responsive.getResponsiveMargin(context),
          childAspectRatio: Responsive.getResponsiveValue(
            context,
            mobile: 0.8,
            tablet: 1.0,
            desktop: 1.5,
          ),
          children: [
            _buildStatCard(
              context,
              ref,
              '총 좌석 수',
              '${dashboardStats.totalSeats}석',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              ref,
              '활성 회원',
              '${dashboardStats.activeMembers}명',
              Icons.person,
              Colors.green,
            ),
            _buildStatCard(
              context,
              ref,
              '사용 중 좌석',
              '${dashboardStats.occupiedSeats}/${dashboardStats.totalSeats}',
              Icons.event_seat,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              ref,
              '오늘 수익',
              '${currencyFormatter.format(dashboardStats.todayRevenue)}원',
              Icons.attach_money,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: Responsive.getResponsiveIconSize(context),
              ),
            ),
            SizedBox(height: Responsive.getResponsiveMargin(context)),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: ref.getResponsiveFontSize(context, baseFontSize: 12),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.getResponsiveMargin(context) / 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: ref.getResponsiveFontSize(context, baseFontSize: 16),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
