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
    final screenWidth = MediaQuery.of(context).size.width;
    final showTitle = screenWidth > 400; // 400px 이하에서 타이틀 숨김
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsivePadding(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 메뉴 버튼 (모바일/태블릿)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onToggleLeftSidebar,
          ),

          if (showTitle) const SizedBox(width: 16),

          // 로고/타이틀 (화면이 충분히 클 때만 표시)
          if (showTitle)
            Text(
              'Study Cafe Manager',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),

          const Spacer(),

          // 우측 액션 버튼들
          Row(
            mainAxisSize: MainAxisSize.min,
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
