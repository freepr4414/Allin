import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../screens/seat_layout_editor.dart';

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

class HorizontalNavigationMenu extends ConsumerStatefulWidget {
  final Function(String?)? onDropdownChanged;
  final Function(Widget?)? onDropdownContentChanged;
  final Function(VoidCallback)? onRegisterCloseCallback;

  const HorizontalNavigationMenu({
    super.key,
    this.onDropdownChanged,
    this.onDropdownContentChanged,
    this.onRegisterCloseCallback,
  });

  @override
  ConsumerState<HorizontalNavigationMenu> createState() =>
      _HorizontalNavigationMenuState();
}

class _HorizontalNavigationMenuState
    extends ConsumerState<HorizontalNavigationMenu> {
  String? _hoveredMenuId;
  String? _openDropdownId;
  final Map<String, GlobalKey> _menuKeys = {};

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
        HorizontalSubMenuItem(id: 'member_logs', title: '회원 로그'),
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
    HorizontalMenuItem(
      id: 'admin',
      title: '관리자 기능',
      icon: Icons.admin_panel_settings,
      children: [
        HorizontalSubMenuItem(id: 'seat_layout_editor', title: '좌석 배치도 편집'),
        HorizontalSubMenuItem(id: 'system_settings', title: '시스템 설정'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 각 메뉴 항목에 대한 GlobalKey 생성
    for (final item in _menuItems) {
      _menuKeys[item.id] = GlobalKey();
    }
    // 부모 위젯에 닫기 콜백 등록
    widget.onRegisterCloseCallback?.call(closeDropdown);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8), // 패딩 줄임
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _menuItems.map((item) {
          return Padding(
            key: _menuKeys[item.id], // GlobalKey 추가
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildHorizontalMenuItem(item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorizontalMenuItem(HorizontalMenuItem item) {
    final isHovered = _hoveredMenuId == item.id;
    final isDropdownOpen = _openDropdownId == item.id;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredMenuId = item.id;
        });
        // 드롭다운이 열린 상태에서 다른 메뉴에 호버하면 자동으로 드롭다운 변경
        if (_openDropdownId != null && _openDropdownId != item.id) {
          _toggleDropdown(item.id);
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredMenuId = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          _toggleDropdown(item.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDropdownOpen
                ? Colors.white.withValues(alpha: 0.1)
                : isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.normal, // 항상 일정한 굵기
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDropdown(String menuId) {
    setState(() {
      if (_openDropdownId == menuId) {
        _openDropdownId = null;
      } else {
        _openDropdownId = menuId;
      }
    });

    // 부모 위젯에 드롭다운 상태 변경 알림
    widget.onDropdownChanged?.call(_openDropdownId);

    // 드롭다운 콘텐츠 전달
    widget.onDropdownContentChanged?.call(getDropdownContent());
  }

  Widget? getDropdownContent() {
    if (_openDropdownId == null) return null;

    final openItem = _menuItems.firstWhere(
      (item) => item.id == _openDropdownId,
      orElse: () => _menuItems.first,
    );

    // 메뉴 위치 계산 - 메뉴 버튼의 왼쪽 모서리에 맞춤
    double leftPosition = 0;
    final menuKey = _menuKeys[_openDropdownId];
    if (menuKey?.currentContext != null) {
      final RenderBox? renderBox =
          menuKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        leftPosition = position.dx; // 메뉴 버튼의 왼쪽 모서리에 맞춤
      }
    }

    return Container(
      width: double.infinity,
      height: 250, // 고정 높이 설정
      decoration: BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          // VSCode 스타일 드롭다운 컨테이너
          Positioned(
            left: leftPosition.clamp(20.0, double.infinity), // 화면 밖으로 나가지 않도록
            top: 0, // 헤더 바로 아래에 붙도록
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // top bar와 같은 색상
                borderRadius: BorderRadius.circular(6),
                // border 제거
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 서브 메뉴 항목들
                  ...openItem.children.map((subItem) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click, // 마우스 커서 변경
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _selectSubMenuItem(openItem.id, subItem.id),
                          hoverColor: Colors.white.withValues(
                            alpha: 0.15,
                          ), // 호버 효과
                          splashColor: Colors.white.withValues(
                            alpha: 0.25,
                          ), // 클릭 효과
                          highlightColor: Colors.white.withValues(
                            alpha: 0.1,
                          ), // 하이라이트 효과
                          borderRadius: BorderRadius.circular(4), // 둥근 모서리
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              subItem.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSubMenuItem(String menuId, String subItemId) {
    setState(() {
      _openDropdownId = null;
    });

    // 부모 위젯에 드롭다운 닫힘 알림
    widget.onDropdownChanged?.call(null);
    widget.onDropdownContentChanged?.call(null);

    // 좌석배치도편집은 전체 화면으로 실행 (Navigator.push 사용)
    if (subItemId == 'seat_layout_editor') {
      // Navigator.push를 사용해 전체화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SeatLayoutEditor(),
          fullscreenDialog: true, // 전체화면 다이얼로그 스타일
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('좌석 배치도 편집 화면으로 이동했습니다'),
          duration: Duration(seconds: 1),
        ),
      );
      return; // 여기서 함수 종료 - 중앙집중 네비게이션 실행 방지
    }

    // 나머지는 기존 중앙집중 방식 (seat_layout_editor가 아닌 경우에만 실행)
    ref.read(currentScreenProvider.notifier).navigateTo(subItemId);

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$subItemId 화면으로 이동했습니다'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void closeDropdown() {
    if (_openDropdownId != null) {
      setState(() {
        _openDropdownId = null;
      });
      widget.onDropdownChanged?.call(null);
      widget.onDropdownContentChanged?.call(null);
    }
  }
}
