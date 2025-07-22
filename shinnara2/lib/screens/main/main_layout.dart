import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/navigation_menu.dart';
import '../../widgets/side_panel.dart';
import '../seat/seat_layout_screen.dart';

enum SidePanelType { dashboard, members, payments, statistics, settings }

extension SidePanelTypeExtension on SidePanelType {
  String get title {
    switch (this) {
      case SidePanelType.dashboard:
        return '대시보드';
      case SidePanelType.members:
        return '회원 관리';
      case SidePanelType.payments:
        return '결제 관리';
      case SidePanelType.statistics:
        return '통계';
      case SidePanelType.settings:
        return '설정';
    }
  }

  IconData get icon {
    switch (this) {
      case SidePanelType.dashboard:
        return Icons.dashboard;
      case SidePanelType.members:
        return Icons.people;
      case SidePanelType.payments:
        return Icons.payment;
      case SidePanelType.statistics:
        return Icons.bar_chart;
      case SidePanelType.settings:
        return Icons.settings;
    }
  }
}

final selectedSidePanelProvider = StateProvider<SidePanelType?>((ref) => null);

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isLeftSidebarCollapsed = false;
  bool _isRightSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final selectedSidePanel = ref.watch(selectedSidePanelProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // 상단 네비게이션 바
          _buildTopNavigationBar(context, isMobile),

          // 메인 콘텐츠 영역
          Expanded(
            child: Row(
              children: [
                // 좌측 사이드바 (메뉴)
                if (!isMobile)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isLeftSidebarCollapsed ? 70.w : 250.w,
                    child: _buildLeftSidebar(context),
                  ),

                // 중앙 좌석 배치도 (항상 표시)
                Expanded(
                  flex: isMobile ? 1 : (isTablet ? 2 : 3),
                  child: Container(
                    margin: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: const SeatLayoutScreen(),
                    ),
                  ),
                ),

                // 우측 사이드바 (선택된 메뉴에 따른 패널)
                if (!isMobile && _isRightSidebarVisible && selectedSidePanel != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 350.w,
                    child: _buildRightSidebar(context, selectedSidePanel),
                  ),
              ],
            ),
          ),
        ],
      ),

      // 모바일용 드로어
      drawer: isMobile ? _buildMobileDrawer(context) : null,

      // 모바일용 우측 드로어
      endDrawer: isMobile && selectedSidePanel != null
          ? _buildMobileEndDrawer(context, selectedSidePanel)
          : null,
    );
  }

  Widget _buildTopNavigationBar(BuildContext context, bool isMobile) {
    final user = ref.watch(authProvider).user;

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            // 햄버거 메뉴 (모바일) 또는 사이드바 토글 (데스크톱)
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            else
              IconButton(
                icon: Icon(
                  _isLeftSidebarCollapsed ? Icons.menu_open : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isLeftSidebarCollapsed = !_isLeftSidebarCollapsed;
                  });
                },
              ),

            SizedBox(width: 12.w),

            // 로고 및 타이틀
            Icon(Icons.local_cafe, color: Colors.white, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              '스터디카페 관리',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16.sp : 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            // 우측 사이드바 토글 (데스크톱)
            if (!isMobile) ...[
              IconButton(
                icon: Icon(
                  _isRightSidebarVisible ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isRightSidebarVisible = !_isRightSidebarVisible;
                  });
                },
              ),
              SizedBox(width: 12.w),
            ],

            // 사용자 정보
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    user?.name.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  SizedBox(width: 8.w),
                  Text(
                    user?.name ?? '사용자',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ],
                SizedBox(width: 8.w),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(children: [Icon(Icons.person), SizedBox(width: 8), Text('프로필')]),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [Icon(Icons.logout), SizedBox(width: 8), Text('로그아웃')]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context) {
    return NavigationMenu(
      isCollapsed: _isLeftSidebarCollapsed,
      onMenuSelected: (sidePanelType) {
        ref.read(selectedSidePanelProvider.notifier).state = sidePanelType;
      },
    );
  }

  Widget _buildRightSidebar(BuildContext context, SidePanelType sidePanelType) {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SidePanel(sidePanelType: sidePanelType),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: NavigationMenu(
        isCollapsed: false,
        onMenuSelected: (sidePanelType) {
          ref.read(selectedSidePanelProvider.notifier).state = sidePanelType;
          Navigator.of(context).pop();
          if (sidePanelType != null) {
            Scaffold.of(context).openEndDrawer();
          }
        },
      ),
    );
  }

  Widget _buildMobileEndDrawer(BuildContext context, SidePanelType sidePanelType) {
    return Drawer(child: SidePanel(sidePanelType: sidePanelType));
  }
}
