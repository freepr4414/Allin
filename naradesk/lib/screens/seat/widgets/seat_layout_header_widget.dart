import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_constants.dart';
import '../../../models/seat.dart';
import '../../../providers/seat_provider.dart';
import '../../../utils/responsive.dart';

/// 좌석 배치 화면 헤더 위젯
class SeatLayoutHeaderWidget extends ConsumerWidget {
  const SeatLayoutHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatStats = ref.watch(seatStatisticsProvider);

    return Container(
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
            Icons.event_seat,
            color: Theme.of(context).colorScheme.primary,
            size: Responsive.getResponsiveIconSize(context),
          ),
          SizedBox(width: Responsive.getResponsiveMargin(context)),
          Text(
            '좌석 현황',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Flexible(child: SeatLegendWidget(stats: seatStats)),
        ],
      ),
    );
  }
}

/// 좌석 상태 범례 위젯
class SeatLegendWidget extends StatelessWidget {
  final Map<SeatStatus, int> stats;

  const SeatLegendWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // 모바일에서는 Wrap으로 자동 줄바꿈
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: Responsive.getResponsiveMargin(context),
        runSpacing: Responsive.getResponsiveMargin(context) / 2,
        children: _buildLegendItems(context),
      );
    } else {
      // 태블릿/데스크탑에서는 한 줄로 배치
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: Responsive.getResponsiveMargin(context),
        children: _buildLegendItems(context),
      );
    }
  }

  List<Widget> _buildLegendItems(BuildContext context) {
    return [
      _buildLegendItem(
        context,
        '이용가능',
        Colors.green,
        stats[SeatStatus.available] ?? 0,
      ),
      _buildLegendItem(
        context,
        '사용중',
        Colors.red,
        stats[SeatStatus.occupied] ?? 0,
      ),
      _buildLegendItem(
        context,
        '예약됨',
        Colors.blue,
        stats[SeatStatus.reserved] ?? 0,
      ),
      _buildLegendItem(
        context,
        '점검중',
        Colors.orange,
        stats[SeatStatus.maintenance] ?? 0,
      ),
      _buildLegendItem(
        context,
        '청소중',
        Colors.purple,
        stats[SeatStatus.cleaning] ?? 0,
      ),
      _buildLegendItem(
        context,
        '고장',
        Colors.grey,
        stats[SeatStatus.outOfOrder] ?? 0,
      ),
    ];
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    int count,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          height: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: Responsive.getResponsiveMargin(context) / 4),
        Flexible(
          child: Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: AppConstants.mobileFontSize,
                tablet: AppConstants.tabletFontSize,
                desktop: AppConstants.desktopFontSize,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
