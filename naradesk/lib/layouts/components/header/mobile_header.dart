import 'package:flutter/material.dart';

import '../../../utils/responsive.dart';

/// 모바일/태블릿용 헤더 컴포넌트
class MobileHeader extends StatelessWidget {
  final VoidCallback onToggleLeftSidebar;
  final VoidCallback onToggleRightSidebar;

  const MobileHeader({
    super.key,
    required this.onToggleLeftSidebar,
    required this.onToggleRightSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsivePadding(context),
      ),
      child: Row(
        children: [
          // 메뉴 버튼 (모바일/태블릿)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onToggleLeftSidebar,
          ),

          const SizedBox(width: 16),

          // 로고/타이틀
          Text(
            'Study Cafe Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.getResponsiveFontSize(
                context,
                baseFontSize: 20,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // 우측 액션 버튼들
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  onToggleRightSidebar();
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
