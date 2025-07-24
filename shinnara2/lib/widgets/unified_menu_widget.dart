import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/unified_menu_provider.dart';
import '../screens/seat_layout_editor.dart';
import '../utils/responsive.dart';

/// 통합 메뉴 위젯 - 권한 기반 메뉴 표시
class UnifiedMenu extends ConsumerStatefulWidget {
  final MenuDisplayType displayType;
  final VoidCallback? onMenuItemSelected;
  final Function(String?)? onDropdownChanged;
  final Function(Widget?)? onDropdownContentChanged;
  final Function(VoidCallback)? onRegisterCloseCallback;
  final Function(double)? onDropdownPositionChanged; // 위치 콜백 추가

  const UnifiedMenu({
    super.key,
    required this.displayType,
    this.onMenuItemSelected,
    this.onDropdownChanged,
    this.onDropdownContentChanged,
    this.onRegisterCloseCallback,
    this.onDropdownPositionChanged,
  });

  @override
  ConsumerState<UnifiedMenu> createState() => _UnifiedMenuState();
}

class _UnifiedMenuState extends ConsumerState<UnifiedMenu> {
  String? _hoveredMenuId;
  String? _expandedMenuId;
  String? _openDropdownId;
  String? _hoveredSubMenuId; // 서브메뉴 호버 상태 추가
  final Map<String, GlobalKey> _menuKeys = {};
  final Map<String, double> _menuPositions = {}; // 메뉴 위치 캐시

  @override
  void initState() {
    super.initState();
    // 드롭다운 닫기 콜백 등록
    if (widget.onRegisterCloseCallback != null) {
      widget.onRegisterCloseCallback!(() {
        if (mounted) {
          setState(() {
            _openDropdownId = null;
          });
          widget.onDropdownChanged?.call(null);
          widget.onDropdownContentChanged?.call(null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenus = ref.watch(permissionFilteredMenusProvider);
    final userPermissionLevel = ref.watch(currentPermissionLevelProvider);

    switch (widget.displayType) {
      case MenuDisplayType.horizontal:
        return _buildHorizontalMenu(filteredMenus, userPermissionLevel);
      case MenuDisplayType.sidebar:
        return _buildSidebarMenu(filteredMenus, userPermissionLevel);
      case MenuDisplayType.mobile:
        return _buildMobileMenu(filteredMenus, userPermissionLevel);
    }
  }

  /// 상단 가로 메뉴 구성
  Widget _buildHorizontalMenu(List<UnifiedMenuItem> menus, PermissionLevel userLevel) {
    return Row(children: menus.map((menu) => _buildHorizontalMenuItem(menu, userLevel)).toList());
  }

  /// 상단 메뉴 아이템
  Widget _buildHorizontalMenuItem(UnifiedMenuItem menu, PermissionLevel userLevel) {
    final isHovered = _hoveredMenuId == menu.id;
    final isOpen = _openDropdownId == menu.id;
    final hasAccessibleChildren = menu.getAccessibleChildren(userLevel).isNotEmpty;

    if (!_menuKeys.containsKey(menu.id)) {
      _menuKeys[menu.id] = GlobalKey();
    }

    final menuWidget = MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredMenuId = menu.id);
        // 호버 시 서브메뉴 자동 전환 (서브메뉴가 있는 경우)
        if (hasAccessibleChildren && _openDropdownId != null) {
          _showDropdownOnHover(menu, userLevel);
        }
      },
      onExit: (_) => setState(() => _hoveredMenuId = null),
      child: GestureDetector(
        key: _menuKeys[menu.id],
        onTap: hasAccessibleChildren
            ? () => _toggleDropdown(menu, userLevel)
            : () => _navigateToMenu(menu.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered || isOpen ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(menu.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                menu.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasAccessibleChildren) ...[
                const SizedBox(width: 4),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );

    // 서브메뉴가 있는 경우 툴팁 비활성화
    if (hasAccessibleChildren) {
      return menuWidget;
    } else {
      // 서브메뉴가 없는 경우에만 툴팁 표시
      return Tooltip(message: menu.tooltip ?? menu.title, child: menuWidget);
    }
  }

  /// 사이드바 메뉴 구성
  Widget _buildSidebarMenu(List<UnifiedMenuItem> menus, PermissionLevel userLevel) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        children: [
          // 메뉴 헤더
          _buildSidebarHeader(userLevel),
          const Divider(),
          // 메뉴 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: menus.length,
              itemBuilder: (context, index) => _buildSidebarMenuItem(menus[index], userLevel),
            ),
          ),
        ],
      ),
    );
  }

  /// 사이드바 헤더 (권한 정보 표시)
  Widget _buildSidebarHeader(PermissionLevel userLevel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text(
            '메뉴',
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 18),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPermissionColor(userLevel).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getPermissionColor(userLevel).withValues(alpha: 0.3)),
            ),
            child: Text(
              userLevel.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _getPermissionColor(userLevel),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사이드바 메뉴 아이템
  Widget _buildSidebarMenuItem(UnifiedMenuItem menu, PermissionLevel userLevel) {
    final isExpanded = _expandedMenuId == menu.id;
    final accessibleChildren = menu.getAccessibleChildren(userLevel);
    final hasAccessibleChildren = accessibleChildren.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isExpanded
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: Column(
        children: [
          ListTile(
            leading: Icon(menu.icon, size: 24, color: Theme.of(context).colorScheme.primary),
            title: Text(
              menu.title,
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: hasAccessibleChildren
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                : null,
            onTap: hasAccessibleChildren
                ? () => setState(() => _expandedMenuId = isExpanded ? null : menu.id)
                : () => _navigateToMenu(menu.id),
          ),
          // 서브 메뉴
          if (isExpanded && hasAccessibleChildren)
            Column(
              children: accessibleChildren.map((child) => _buildSidebarSubMenuItem(child)).toList(),
            ),
        ],
      ),
    );
  }

  /// 사이드바 서브 메뉴 아이템
  Widget _buildSidebarSubMenuItem(UnifiedMenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Icon(
        item.subIcon ?? item.icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        item.title,
        style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseFontSize: 13)),
      ),
      onTap: () => _navigateToMenu(item.id),
    );
  }

  /// 모바일 메뉴 구성
  Widget _buildMobileMenu(List<UnifiedMenuItem> menus, PermissionLevel userLevel) {
    return _buildSidebarMenu(menus, userLevel); // 모바일은 사이드바와 동일
  }

  /// 드롭다운 토글
  void _toggleDropdown(UnifiedMenuItem menu, PermissionLevel userLevel) {
    final accessibleChildren = menu.getAccessibleChildren(userLevel);

    if (accessibleChildren.isEmpty) {
      _navigateToMenu(menu.id);
      return;
    }

    setState(() {
      _openDropdownId = _openDropdownId == menu.id ? null : menu.id;
    });

    widget.onDropdownChanged?.call(_openDropdownId);

    if (_openDropdownId != null) {
      _calculateAndSetDropdownPosition(menu);
      widget.onDropdownContentChanged?.call(_buildDropdownContent(menu, accessibleChildren));
    } else {
      widget.onDropdownContentChanged?.call(null);
    }
  }

  /// 호버 시 서브메뉴 표시
  void _showDropdownOnHover(UnifiedMenuItem menu, PermissionLevel userLevel) {
    final accessibleChildren = menu.getAccessibleChildren(userLevel);

    if (accessibleChildren.isEmpty) return;

    setState(() {
      _openDropdownId = menu.id;
    });

    widget.onDropdownChanged?.call(_openDropdownId);
    _calculateAndSetDropdownPosition(menu);
    widget.onDropdownContentChanged?.call(_buildDropdownContent(menu, accessibleChildren));
  }

  /// 드롭다운 위치 계산 및 설정
  void _calculateAndSetDropdownPosition(UnifiedMenuItem menu) {
    final RenderBox? renderBox =
        _menuKeys[menu.id]?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      _menuPositions[menu.id] = position.dx;
      // 위치 정보를 부모 위젯에 전달
      widget.onDropdownPositionChanged?.call(position.dx);
    }
  }

  /// 드롭다운 컨텐츠 생성
  Widget _buildDropdownContent(UnifiedMenuItem parentMenu, List<UnifiedMenuItem> children) {
    return Container(
      width: 220, // 적정 너비로 조정
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children.map((child) => _buildDropdownMenuItem(child)).toList(),
      ),
    );
  }

  /// 드롭다운 메뉴 아이템 (호버 효과 포함)
  Widget _buildDropdownMenuItem(UnifiedMenuItem item) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSubMenuId = item.id),
      onExit: (_) => setState(() => _hoveredSubMenuId = null),
      child: Container(
        decoration: BoxDecoration(
          color: _hoveredSubMenuId == item.id
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            item.subIcon ?? item.icon,
            size: 18,
            color: _hoveredSubMenuId == item.id
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              color: _hoveredSubMenuId == item.id
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: item.tooltip != null
              ? Text(
                  item.tooltip!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              : null,
          onTap: () => _navigateToMenu(item.id),
        ),
      ),
    );
  }

  /// 메뉴 네비게이션 (권한 기반)
  void _navigateToMenu(String menuId) {
    final authState = ref.read(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;

    // 좌석배치도편집은 Navigator.push로 전체화면 실행
    if (menuId == 'seat_layout_editor') {
      // 먼저 모든 메뉴 상태 닫기
      setState(() {
        _expandedMenuId = null; // 사이드바 확장 메뉴 닫기
        _openDropdownId = null; // 헤더 드롭다운 메뉴 닫기
      });

      // 부모 위젯에도 드롭다운 닫힘 알림
      widget.onDropdownChanged?.call(null);
      widget.onDropdownContentChanged?.call(null);
      widget.onMenuItemSelected?.call(); // 부모 위젯에 메뉴 선택 알림 (사이드바 닫기)

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SeatLayoutEditor(), fullscreenDialog: true),
      );

      return; // 중앙집중 네비게이션 실행 방지
    }

    // 나머지는 권한 기반 중앙집중 네비게이션 사용
    ref.read(currentScreenProvider.notifier).navigateWithPermission(menuId, userLevel);
    widget.onMenuItemSelected?.call();

    // 드롭다운 닫기
    setState(() {
      _openDropdownId = null;
    });
    widget.onDropdownChanged?.call(null);
    widget.onDropdownContentChanged?.call(null);

    // 성공 메시지 표시
    final menu = MenuRegistry.findById(menuId);
    if (menu != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${menu.title} 화면으로 이동했습니다'), duration: const Duration(seconds: 1)),
      );
    }
  }

  /// 권한 레벨에 따른 색상 반환
  Color _getPermissionColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.level1:
        return Colors.red;
      case PermissionLevel.level2:
        return Colors.orange;
      case PermissionLevel.level3:
        return Colors.blue;
      case PermissionLevel.level4:
        return Colors.green;
      case PermissionLevel.level5:
        return Colors.grey;
    }
  }
}
