import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/responsive.dart';
import '../../../utils/responsive_font.dart';

/// 대시보드 헤더 위젯
class DashboardHeaderWidget extends ConsumerWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Icons.dashboard,
            color: Theme.of(context).colorScheme.primary,
            size: Responsive.getResponsiveIconSize(context),
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
    );
  }
}
