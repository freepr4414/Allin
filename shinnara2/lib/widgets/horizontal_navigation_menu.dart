import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HorizontalNavigationMenu extends ConsumerStatefulWidget {
  const HorizontalNavigationMenu({super.key});

  @override
  ConsumerState<HorizontalNavigationMenu> createState() => _HorizontalNavigationMenuState();
}

class _HorizontalNavigationMenuState extends ConsumerState<HorizontalNavigationMenu> {
  String? _hoveredMenuId;
  String? _selectedMenuId = 'seats'; // 기본 선택

  final List<HorizontalMenuItem> _menuItems = [
    HorizontalMenuItem(
      id: 'dashboard',
      title: '대시보드',
      icon: Icons.dashboard,
      children: [
        HorizontalSubMenuItem(id: 'overview', title: '전체 현황'),
        HorizontalSubMenuItem(id: 'reports', title: '리포트'),
      ],
    ),
    HorizontalMenuItem(
      id: 'seats',
      title: '좌석 관리',
      icon: Icons.event_seat,
      children: [
        HorizontalSubMenuItem(id: 'seat_layout', title: '좌석 배치도'),
        HorizontalSubMenuItem(id: 'seat_status', title: '좌석 현황'),
        HorizontalSubMenuItem(id: 'seat_history', title: '이용 내역'),
      ],
    ),
    HorizontalMenuItem(
      id: 'members',
      title: '회원 관리',
      icon: Icons.people,
      children: [
        HorizontalSubMenuItem(id: 'member_list', title: '회원 목록'),
        HorizontalSubMenuItem(id: 'member_register', title: '회원 등록'),
        HorizontalSubMenuItem(id: 'member_payments', title: '결제 내역'),
      ],
    ),
    HorizontalMenuItem(
      id: 'settings',
      title: '설정',
      icon: Icons.settings,
      children: [
        HorizontalSubMenuItem(id: 'general', title: '일반 설정'),
        HorizontalSubMenuItem(id: 'seat_config', title: '좌석 설정'),
        HorizontalSubMenuItem(id: 'notification', title: '알림 설정'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8), // 패딩 줄임
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _menuItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildHorizontalMenuItem(item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorizontalMenuItem(HorizontalMenuItem item) {
    final isSelected = _selectedMenuId == item.id;
    final isHovered = _hoveredMenuId == item.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredMenuId = item.id),
      onExit: (_) => setState(() => _hoveredMenuId = null),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 0),
        tooltip: '',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : isHovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
            ],
          ),
        ),
        itemBuilder: (context) {
          return item.children.map((subItem) {
            return PopupMenuItem<String>(
              value: subItem.id,
              child: Row(children: [const SizedBox(width: 8), Text(subItem.title)]),
            );
          }).toList();
        },
        onSelected: (value) {
          setState(() {
            _selectedMenuId = item.id;
          });
          // TODO: 페이지 네비게이션 구현
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value 선택됨')));
        },
      ),
    );
  }
}

class HorizontalMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final List<HorizontalSubMenuItem> children;

  HorizontalMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.children,
  });
}

class HorizontalSubMenuItem {
  final String id;
  final String title;

  HorizontalSubMenuItem({required this.id, required this.title});
}
