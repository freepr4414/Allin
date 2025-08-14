import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/responsive.dart';
import 'widgets/dashboard_charts_widget.dart';
import 'widgets/dashboard_header_widget.dart';
import 'widgets/dashboard_stats_widget.dart';

/// 대시보드 메인 화면 - 위젯들로 구성된 간소화된 화면
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 페이지 헤더
            const DashboardHeaderWidget(),

            SizedBox(height: Responsive.getResponsivePadding(context)),

            // 통계 카드들
            const DashboardStatsWidget(),

            SizedBox(height: Responsive.getResponsivePadding(context)),

            // 차트 섹션
            const DashboardChartsWidget(),
          ],
        ),
      ),
    );
  }
}
