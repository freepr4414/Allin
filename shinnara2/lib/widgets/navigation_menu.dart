import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/main/main_layout.dart';

class NavigationMenu extends StatelessWidget {
  final bool isCollapsed;
  final Function(SidePanelType?) onMenuSelected;

  const NavigationMenu({super.key, required this.isCollapsed, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          if (!isCollapsed) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Icons.local_cafe, color: Theme.of(context).colorScheme.primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '관리 메뉴',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h),
          ],

          // 메뉴 항목들
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildMenuItem(context, SidePanelType.dashboard, Icons.dashboard, '대시보드'),
                _buildMenuItem(context, SidePanelType.members, Icons.people, '회원 관리'),
                _buildMenuItem(context, SidePanelType.payments, Icons.payment, '결제 관리'),
                _buildMenuItem(context, SidePanelType.statistics, Icons.bar_chart, '통계'),
                _buildMenuItem(context, SidePanelType.settings, Icons.settings, '설정'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    SidePanelType sidePanelType,
    IconData icon,
    String title,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCollapsed ? 8.w : 12.w, vertical: 2.h),
      child: InkWell(
        onTap: () => onMenuSelected(sidePanelType),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8.w : 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
              if (!isCollapsed) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
