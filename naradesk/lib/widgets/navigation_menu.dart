import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';

class NavigationMenu extends ConsumerStatefulWidget {
  final VoidCallback? onMenuItemSelected;

  // ignore: prefer_const_constructors_in_immutables
  NavigationMenu({super.key, this.onMenuItemSelected});

  @override
  ConsumerState<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends ConsumerState<NavigationMenu> {
  String? _expandedMenuId;

  final List<MenuGroup> _menuGroups = [
    MenuGroup(
      id: 'dashboard',
      title: '대시보드',
      icon: Icons.dashboard,
      children: [
        MenuItem(id: 'overview', title: '전체 현황', icon: Icons.analytics),
        MenuItem(id: 'reports', title: '리포트', icon: Icons.assessment),
      ],
    ),
    MenuGroup(
      id: 'seats',
      title: '좌석 관리',
      icon: Icons.event_seat,
      children: [
        MenuItem(id: 'seat_layout', title: '좌석 배치도', icon: Icons.grid_view),
        MenuItem(id: 'seat_status', title: '좌석 현황', icon: Icons.list_alt),
        MenuItem(id: 'seat_history', title: '이용 내역', icon: Icons.history),
      ],
    ),
    MenuGroup(
      id: 'members',
      title: '회원 관리',
      icon: Icons.people,
      children: [
        MenuItem(id: 'member_list', title: '회원 목록', icon: Icons.person),
        MenuItem(id: 'member_register', title: '회원 등록', icon: Icons.person_add),
        MenuItem(id: 'member_payments', title: '결제 내역', icon: Icons.payment),
        MenuItem(id: 'member_logs', title: '회원 로그', icon: Icons.list_alt),
      ],
    ),
    MenuGroup(
      id: 'settings',
      title: '설정',
      icon: Icons.settings,
      children: [
        MenuItem(id: 'general', title: '일반 설정', icon: Icons.tune),
        MenuItem(id: 'seat_config', title: '좌석 설정', icon: Icons.event_seat),
        MenuItem(id: 'notification', title: '알림 설정', icon: Icons.notifications),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        children: [
          // 메뉴 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              '메뉴',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(),

          // 메뉴 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _menuGroups.length,
              itemBuilder: (context, index) {
                final group = _menuGroups[index];
                return _buildMenuGroup(group);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(MenuGroup group) {
    final isExpanded = _expandedMenuId == group.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isExpanded
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              group.icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              group.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onTap: () {
              setState(() {
                _expandedMenuId = isExpanded ? null : group.id;
              });
            },
          ),

          // 서브 메뉴
          if (isExpanded)
            Column(
              children: group.children.map((item) {
                return _buildMenuItem(item);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Icon(
        item.icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(item.title, style: Theme.of(context).textTheme.bodySmall),
      onTap: () {
        // 권한 기반 네비게이션 실행
        final authState = ref.read(authProvider);
        final userLevel =
            authState.user?.permissionLevel ?? PermissionLevel.level5;
        ref
            .read(currentScreenProvider.notifier)
            .navigateWithPermission(item.id, userLevel);

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} 화면으로 이동했습니다'),
            duration: const Duration(seconds: 1),
          ),
        );

        // 메뉴 선택 시 콜백 호출 (사이드바 닫기용)
        widget.onMenuItemSelected?.call();
      },
    );
  }
}

class MenuGroup {
  final String id;
  final String title;
  final IconData icon;
  final List<MenuItem> children;

  MenuGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.children,
  });
}

class MenuItem {
  final String id;
  final String title;
  final IconData icon;

  MenuItem({required this.id, required this.title, required this.icon});
}
