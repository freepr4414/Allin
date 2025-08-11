import 'package:flutter/material.dart';

import '../../../models/unified_menu_models.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/hover_icon_button.dart';
import '../../../widgets/unified_menu_widget.dart';

/// 데스크톱용 헤더 컴포넌트
class DesktopHeader extends StatelessWidget {
  final Function(String?) onDropdownChanged;
  final Function(Widget?) onDropdownContentChanged;
  final Function(VoidCallback) onRegisterCloseCallback;
  final Function(double) onDropdownPositionChanged; // 위치 콜백 추가
  final VoidCallback onToggleRightSidebar;

  const DesktopHeader({
    super.key,
    required this.onDropdownChanged,
    required this.onDropdownContentChanged,
    required this.onRegisterCloseCallback,
    required this.onDropdownPositionChanged,
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
          // 로고/타이틀 (호버 효과 추가)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // TODO: 홈페이지로 이동 또는 새로고침
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('홈으로 이동')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Builder(
                    builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final titleColor = isDark ? Colors.black : Colors.white;
                      return Text(
                        'Study Cafe Manager',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            baseFontSize: 20,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 40), // 로고와 메뉴 사이 간격
          // 가로 메뉴 (중앙) - 통합 메뉴 사용
          Expanded(
            child: UnifiedMenu(
              displayType: MenuDisplayType.horizontal,
              onDropdownChanged: onDropdownChanged,
              onDropdownContentChanged: onDropdownContentChanged,
              onRegisterCloseCallback: onRegisterCloseCallback,
              onDropdownPositionChanged: onDropdownPositionChanged, // 위치 콜백 전달
            ),
          ),

          // 우측 액션 버튼들 (호버 효과 추가)
          Row(
            children: [
              HoverIconButton(
                icon: Icons.notifications,
                tooltip: '알림',
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('알림 기능')));
                },
              ),
              HoverIconButton(
                icon: Icons.settings,
                tooltip: '설정',
                onPressed: () {
                  print('🎨 [HEADER_SETTINGS] 헤더 설정 버튼 클릭됨 (사이드바 토글)');
                  onToggleRightSidebar();
                },
              ),
              HoverIconButton(
                icon: Icons.account_circle,
                tooltip: '계정',
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('계정 메뉴')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
