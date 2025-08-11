import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../utils/responsive.dart';
import '../../utils/responsive_font.dart';
import '../../widgets/charts/bar_chart_widget_animated.dart';
import '../../widgets/charts/line_chart_widget_animated.dart';
import '../../widgets/charts/pie_chart_widget_animated.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardProvider);
    final currencyFormatter = NumberFormat('#,###', 'ko_KR');

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 페이지 헤더
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getResponsivePadding(context),
                vertical: Responsive.getResponsiveMargin(context),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard,
                    color: Theme.of(context).colorScheme.primary,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveMargin(context)),
                  Text(
                    '대시보드',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ref.getResponsiveFontSize(
                        context,
                        baseFontSize: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(DateTime.now()),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: ref.getResponsiveFontSize(
                        context,
                        baseFontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.getResponsivePadding(context)),

            // 통계 카드들
            _buildStatsCards(context, ref, dashboardStats, currencyFormatter),

            SizedBox(height: Responsive.getResponsivePadding(context)),

            // 차트 섹션
            if (Responsive.isDesktop(context))
              _buildDesktopCharts(context, dashboardStats)
            else if (Responsive.isTablet(context))
              _buildTabletCharts(context, dashboardStats)
            else
              _buildMobileCharts(context, dashboardStats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    WidgetRef ref,
    dashboardStats,
    NumberFormat currencyFormatter,
  ) {
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
            mobile: 1.2,
            tablet: 1.5,
            desktop: 2.0,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28,
              ),
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
    );
  }

  Widget _buildDesktopCharts(BuildContext context, dashboardStats) {
    return Column(
      children: [
        // 첫 번째 행 - 라인 차트만
        Row(
          children: [
            Expanded(
              child: DashboardLineChart(
                data: dashboardStats.dailyUsageData,
                title: '일일 이용자 추이 (최근 7일)',
                lineColor: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 두 번째 행 - 파이 차트만
        Row(
          children: [
            Expanded(
              child: DashboardPieChart(
                data: dashboardStats.seatTypeUsage,
                title: '좌석 유형별 사용률',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 세 번째 행 - 막대 차트만
        Row(
          children: [
            Expanded(
              child: DashboardBarChart(
                data: dashboardStats.hourlyUsageData,
                title: '시간대별 이용 현황',
                barColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletCharts(BuildContext context, dashboardStats) {
    return Column(
      children: [
        // 첫 번째 행 - 라인 차트만
        Row(
          children: [
            Expanded(
              child: DashboardLineChart(
                data: dashboardStats.dailyUsageData,
                title: '일일 이용자 추이 (최근 7일)',
                lineColor: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 두 번째 행 - 파이 차트만
        Row(
          children: [
            Expanded(
              child: DashboardPieChart(
                data: dashboardStats.seatTypeUsage,
                title: '좌석 유형별 사용률',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 세 번째 행 - 막대 차트만
        Row(
          children: [
            Expanded(
              child: DashboardBarChart(
                data: dashboardStats.hourlyUsageData,
                title: '시간대별 이용 현황',
                barColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileCharts(BuildContext context, dashboardStats) {
    return Column(
      children: [
        // 첫 번째 행 - 라인 차트만
        Row(
          children: [
            Expanded(
              child: DashboardLineChart(
                data: dashboardStats.dailyUsageData,
                title: '일일 이용자 추이 (최근 7일)',
                lineColor: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 두 번째 행 - 파이 차트만
        Row(
          children: [
            Expanded(
              child: DashboardPieChart(
                data: dashboardStats.seatTypeUsage,
                title: '좌석 유형별 사용률',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsivePadding(context)),
        // 세 번째 행 - 막대 차트만
        Row(
          children: [
            Expanded(
              child: DashboardBarChart(
                data: dashboardStats.hourlyUsageData,
                title: '시간대별 이용 현황',
                barColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
