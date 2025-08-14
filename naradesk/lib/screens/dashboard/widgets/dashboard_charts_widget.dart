import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/dashboard_provider.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/charts/bar_chart_widget_animated.dart';
import '../../../widgets/charts/line_chart_widget_animated.dart';
import '../../../widgets/charts/pie_chart_widget_animated.dart';

/// 대시보드 차트 섹션 위젯
class DashboardChartsWidget extends ConsumerWidget {
  const DashboardChartsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardProvider);

    // 반응형 레이아웃에 따른 차트 배치
    if (Responsive.isDesktop(context)) {
      return _buildDesktopCharts(context, dashboardStats);
    } else if (Responsive.isTablet(context)) {
      return _buildTabletCharts(context, dashboardStats);
    } else {
      return _buildMobileCharts(context, dashboardStats);
    }
  }

  Widget _buildDesktopCharts(BuildContext context, dashboardStats) {
    return Column(
      children: [
        // 첫 번째 행 - 라인 차트
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
        // 두 번째 행 - 파이 차트
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
        // 세 번째 행 - 막대 차트
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
        // 첫 번째 행 - 라인 차트
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
        // 두 번째 행 - 파이 차트
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
        // 세 번째 행 - 막대 차트
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
        // 첫 번째 행 - 라인 차트
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
        // 두 번째 행 - 파이 차트
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
        // 세 번째 행 - 막대 차트
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
