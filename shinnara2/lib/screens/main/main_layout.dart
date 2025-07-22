import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../../widgets/side_panel.dart';
import '../seat/seat_layout_screen.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final selectedSidePanel = ref.watch(selectedSidePanelProvider);
    final showNavigationMenu = ref.watch(showNavigationMenuProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // 네비게이션 메뉴
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: showNavigationMenu ? 300 : 0,
            child: showNavigationMenu ? _buildNavigationMenu(context, ref) : null,
          ),

          // 메인 콘텐츠
          Expanded(
            child: Column(
              children: [
                // 상단 앱바
                _buildTopAppBar(context, ref, authState),

                // 메인 영역
                Expanded(
                  child: Row(
                    children: [
                      // 좌석 레이아웃
                      const Expanded(flex: 3, child: SeatLayoutScreen()),

                      // 사이드 패널
                      if (selectedSidePanel != null)
                        Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: SidePanel(type: selectedSidePanel),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, AuthState authState) {
    final notificationCount = ref.watch(notificationCountProvider);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 메뉴 버튼
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                ref.read(showNavigationMenuProvider.notifier).update((state) => !state);
              },
            ),

            // 로고 및 제목
            const SizedBox(width: 8),
            Icon(Icons.local_cafe, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 8),
            Text(
              'Study Cafe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const Spacer(),

            // 빠른 액션 버튼들
            _buildQuickActionButton(
              context,
              ref,
              icon: Icons.dashboard,
              label: '대시보드',
              onPressed: () =>
                  ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.dashboard,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              context,
              ref,
              icon: Icons.people,
              label: '회원',
              onPressed: () =>
                  ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.members,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              context,
              ref,
              icon: Icons.payment,
              label: '결제',
              onPressed: () =>
                  ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.payments,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              context,
              ref,
              icon: Icons.bar_chart,
              label: '통계',
              onPressed: () =>
                  ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.statistics,
            ),

            const SizedBox(width: 16),

            // 알림 버튼
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // 알림 패널 토글
                  },
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),

            // 사용자 프로필
            PopupMenuButton<String>(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      authState.user?.name.substring(0, 1) ?? 'U',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user?.name ?? '사용자',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        authState.user?.type.displayName ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('프로필'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('설정'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('로그아웃', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    // 프로필 페이지로 이동
                    break;
                  case 'settings':
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.settings;
                    break;
                  case 'logout':
                    ref.read(authProvider.notifier).logout();
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final selectedMenuItem = ref.watch(selectedMenuItemProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 사용자 정보 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    authState.user?.name.substring(0, 1) ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user?.name ?? '사용자',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.user?.type.displayName ?? '',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 항목들
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.dashboard,
                  icon: Icons.dashboard,
                  title: '대시보드',
                  isSelected: selectedMenuItem == MenuItemType.dashboard,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.dashboard;
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.dashboard;
                  },
                ),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.seatManagement,
                  icon: Icons.event_seat,
                  title: '좌석 관리',
                  isSelected: selectedMenuItem == MenuItemType.seatManagement,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.seatManagement;
                    ref.read(selectedSidePanelProvider.notifier).state = null;
                  },
                ),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.userManagement,
                  icon: Icons.people,
                  title: '회원 관리',
                  isSelected: selectedMenuItem == MenuItemType.userManagement,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.userManagement;
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.members;
                  },
                ),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.paymentManagement,
                  icon: Icons.payment,
                  title: '결제 관리',
                  isSelected: selectedMenuItem == MenuItemType.paymentManagement,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state =
                        MenuItemType.paymentManagement;
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.payments;
                  },
                ),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.statistics,
                  icon: Icons.bar_chart,
                  title: '통계',
                  isSelected: selectedMenuItem == MenuItemType.statistics,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.statistics;
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.statistics;
                  },
                ),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.settings,
                  icon: Icons.settings,
                  title: '설정',
                  isSelected: selectedMenuItem == MenuItemType.settings,
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.settings;
                    ref.read(selectedSidePanelProvider.notifier).state = SidePanelType.settings;
                  },
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context,
                  ref,
                  type: MenuItemType.notifications,
                  icon: Icons.notifications,
                  title: '알림',
                  isSelected: selectedMenuItem == MenuItemType.notifications,
                  badge: ref.watch(notificationCountProvider).toString(),
                  onTap: () {
                    ref.read(selectedMenuItemProvider.notifier).state = MenuItemType.notifications;
                  },
                ),
              ],
            ),
          ),

          // 하단 로그아웃 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    WidgetRef ref, {
    required MenuItemType type,
    required IconData icon,
    required String title,
    required bool isSelected,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
