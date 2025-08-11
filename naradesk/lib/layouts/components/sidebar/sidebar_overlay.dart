import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/unified_menu_models.dart';
import '../../../providers/ui_provider.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/side_panel.dart';
import '../../../widgets/unified_menu_widget.dart';

/// 사이드바 오버레이 컴포넌트 (모바일/태블릿용)
class SidebarOverlay extends ConsumerWidget {
  final bool isLeftVisible;
  final bool isRightVisible;
  final VoidCallback onToggleLeft;
  final VoidCallback onToggleRight;

  const SidebarOverlay({
    super.key,
    required this.isLeftVisible,
    required this.isRightVisible,
    required this.onToggleLeft,
    required this.onToggleRight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 왼쪽 사이드바 (네비게이션)
        if (isLeftVisible) _buildLeftSidebarOverlay(context),

        // 오른쪽 사이드바 (설정/알림)
        if (isRightVisible) _buildRightSidebarOverlay(context),
      ],
    );
  }

  Widget _buildLeftSidebarOverlay(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);

    return GestureDetector(
      onTap: onToggleLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: isTablet ? 0.3 : 0.5),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {}, // 사이드바 클릭 시 닫히지 않도록
              child: Container(
                width: isMobile
                    ? MediaQuery.of(context).size.width * 0.85
                    : 320,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: UnifiedMenu(
                  displayType: MenuDisplayType.sidebar,
                  onMenuItemSelected: onToggleLeft,
                ),
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebarOverlay(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);

    return GestureDetector(
      onTap: onToggleRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withValues(alpha: isTablet ? 0.3 : 0.5),
        child: Row(
          children: [
            Expanded(child: Container()),
            Container(
              width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 320,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: SidePanel(
                type: SidePanelType.settings,
                onClose: onToggleRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
