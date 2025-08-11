import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_menu_models.dart';
import '../models/unified_route_registry.dart';
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
  // 디버그 로그 활성화 플래그 (필요 시 false 로 끄기)
  /// 디버그 옵션들
  static const bool _debugSubHover = false;
  // 드롭다운 재빌드를 위한 현재 열린 부모 & 자식 캐시
  UnifiedMenuItem? _currentOpenParent;
  List<UnifiedMenuItem> _currentOpenChildren = const [];
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
  Widget _buildHorizontalMenu(
    List<UnifiedMenuItem> menus,
    PermissionLevel userLevel,
  ) {
    return MouseRegion(
      onHover: (event) {
        if (_openDropdownId == null) return;
        final pos = event.position;
        final headerHeight = Responsive.getResponsiveValue(
          context,
          mobile: 60,
          tablet: 70,
          desktop: 80,
        );
        final cluster = _getMenuClusterBounds();
        if (cluster == null) return;
        final outsideCluster = pos.dx < cluster[0] || pos.dx > cluster[1];
        final belowHeader = pos.dy > headerHeight; // 세로 벗어남
        if (_hoveredMenuId == null && (outsideCluster || belowHeader)) {
          setState(() => _openDropdownId = null);
          widget.onDropdownChanged?.call(null);
          widget.onDropdownContentChanged?.call(null);
        }
      },
      onExit: (event) {
        if (_openDropdownId == null) return;
        final cluster = _getMenuClusterBounds();
        if (cluster == null) return;
        final pos = event.position;
        // 완전히 왼쪽/오른쪽으로 빠진 경우 닫기
        if (pos.dx < cluster[0] || pos.dx > cluster[1]) {
          setState(() => _openDropdownId = null);
          widget.onDropdownChanged?.call(null);
          widget.onDropdownContentChanged?.call(null);
        }
      },
      child: Row(
        children: menus
            .map((menu) => _buildHorizontalMenuItem(menu, userLevel))
            .toList(),
      ),
    );
  }

  /// 상단 메뉴 아이템
  Widget _buildHorizontalMenuItem(
    UnifiedMenuItem menu,
    PermissionLevel userLevel,
  ) {
    final isHovered = _hoveredMenuId == menu.id;
    final isOpen = _openDropdownId == menu.id;
    // onSurface 대신 사용자 정의 headerBaseColor 사용
    final brightness = Theme.of(context).brightness;
    // 사용자 요구: 라이트 모드 = 흰색, 다크 모드 = 검정색
    final headerBaseColor = brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    final hasAccessibleChildren = menu
        .getAccessibleChildren(userLevel)
        .isNotEmpty;

    if (!_menuKeys.containsKey(menu.id)) {
      _menuKeys[menu.id] = GlobalKey();
    }

    final menuWidget = MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredMenuId = menu.id);
        // 기존 방식 복구: 이미 다른 드롭다운이 열려 있을 때만 호버로 전환
        if (hasAccessibleChildren &&
            _openDropdownId != null &&
            _openDropdownId != menu.id) {
          _showDropdownOnHover(menu, userLevel);
        }
      },
      onExit: (_) => setState(() => _hoveredMenuId = null),
      child: GestureDetector(
        key: _menuKeys[menu.id],
        onTap: hasAccessibleChildren
            ? () => _toggleDropdown(menu, userLevel)
            : () => _navigateToMenu(menu.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: (isOpen || isHovered)
                ? headerBaseColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘: 열림 여부와 관계없이 모드별 기반색 유지 (다크=검정, 라이트=흰색)
              Icon(menu.icon, color: headerBaseColor, size: 18),
              const SizedBox(width: 8),
              Text(
                menu.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // open 상태에서 primary 로 바꾸면 다크모드 배경과 유사해 사라져 보임 -> 항상 기반색 유지
                  color: headerBaseColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasAccessibleChildren) ...[
                const SizedBox(width: 4),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  // 화살표도 동일한 대비 유지. 살짝 투명도 적용해 위계만 표시
                  color: headerBaseColor.withValues(alpha: isOpen ? 0.9 : 0.75),
                  size: 16,
                ),
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
  Widget _buildSidebarMenu(
    List<UnifiedMenuItem> menus,
    PermissionLevel userLevel,
  ) {
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
              itemBuilder: (context, index) =>
                  _buildSidebarMenuItem(menus[index], userLevel),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              border: Border.all(
                color: _getPermissionColor(userLevel).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              userLevel.displayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
  Widget _buildSidebarMenuItem(
    UnifiedMenuItem menu,
    PermissionLevel userLevel,
  ) {
    final isExpanded = _expandedMenuId == menu.id;
    final accessibleChildren = menu.getAccessibleChildren(userLevel);
    final hasAccessibleChildren = accessibleChildren.isNotEmpty;

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
              menu.icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              menu.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: hasAccessibleChildren
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                : null,
            onTap: hasAccessibleChildren
                ? () => setState(
                    () => _expandedMenuId = isExpanded ? null : menu.id,
                  )
                : () => _navigateToMenu(menu.id),
          ),
          // 서브 메뉴
          if (isExpanded && hasAccessibleChildren)
            Column(
              children: accessibleChildren
                  .map((child) => _buildSidebarSubMenuItem(child))
                  .toList(),
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
      title: Text(item.title, style: Theme.of(context).textTheme.bodySmall),
      onTap: () => _navigateToMenu(item.id),
    );
  }

  /// 모바일 메뉴 구성
  Widget _buildMobileMenu(
    List<UnifiedMenuItem> menus,
    PermissionLevel userLevel,
  ) {
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
      _currentOpenParent = menu;
      _currentOpenChildren = accessibleChildren;
      _calculateAndSetDropdownPosition(menu);
      widget.onDropdownContentChanged?.call(
        _buildDropdownContent(menu, accessibleChildren),
      );
    } else {
      _currentOpenParent = null;
      _currentOpenChildren = const [];
      widget.onDropdownContentChanged?.call(null);
    }
  }

  /// 호버 시 서브메뉴 표시
  void _showDropdownOnHover(UnifiedMenuItem menu, PermissionLevel userLevel) {
    final accessibleChildren = menu.getAccessibleChildren(userLevel);

    if (accessibleChildren.isEmpty) return;

    setState(() {
      _openDropdownId = menu.id;
      _currentOpenParent = menu;
      _currentOpenChildren = accessibleChildren;
    });

    widget.onDropdownChanged?.call(_openDropdownId);
    _calculateAndSetDropdownPosition(menu);
    widget.onDropdownContentChanged?.call(
      _buildDropdownContent(menu, accessibleChildren),
    );
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
  Widget _buildDropdownContent(
    UnifiedMenuItem parentMenu,
    List<UnifiedMenuItem> children,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onExit: (event) {
        if (_openDropdownId == null) return;
        // 현재 포인터의 전역 위치
        final pos = event.position; // global Offset
        final headerHeight = Responsive.getResponsiveValue(
          context,
          mobile: 60,
          tablet: 70,
          desktop: 80,
        );
        final size = MediaQuery.of(context).size;

        final outsideVertical = pos.dy > headerHeight; // 헤더/드롭다운 세로 영역 밖
        final outsideHorizontal = pos.dx < 0 || pos.dx > size.width;
        // 메인 메뉴(상단 메뉴 아이템들) 좌/우 경계 계산
        final cluster = _getMenuClusterBounds();
        bool outsideCluster = false;
        if (cluster != null) {
          final clusterLeft = cluster[0];
          final clusterRight = cluster[1];
          outsideCluster = pos.dx < clusterLeft || pos.dx > clusterRight;
        }

        // 메뉴 아이템 위가 아니면서 (세로 밖 || 화면 가로 밖 || 메뉴 클러스터 좌우 밖) 이면 닫기
        if (_hoveredMenuId == null &&
            (outsideVertical || outsideHorizontal || outsideCluster)) {
          setState(() => _openDropdownId = null);
          widget.onDropdownChanged?.call(null);
          widget.onDropdownContentChanged?.call(null);
        }
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: scheme.primary,
          // 라운딩 & 그림자 제거
          border: Border.all(
            color: scheme.onPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++)
              _buildDropdownMenuItem(
                children[i],
                isFirst: i == 0,
                isLast: i == children.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  /// 드롭다운 메뉴 아이템 (호버 효과 포함)
  Widget _buildDropdownMenuItem(
    UnifiedMenuItem item, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isHover = _hoveredSubMenuId == item.id;
    final baseTextColor = scheme.onPrimary;
    // 메인 메뉴와 동일한 호버 배경 컬러 계산 (라이트=White, 다크=Black)
    final brightness = Theme.of(context).brightness;
    // 대비 강화: 다크모드 더 밝게, 라이트모드 더 어둡게 (기존보다 1.5~2배 강도)
    final Color hoverBackground = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.16);

    if (_debugSubHover) {
      debugPrint(
        '[SUB BUILD] id=${item.id} isHover=$isHover hoverColor=${hoverBackground.toARGB32().toRadixString(16)}',
      );
    }

    return MouseRegion(
      onEnter: (e) {
        if (_debugSubHover) {
          debugPrint(
            '[SUB HOVER ENTER] id=${item.id} title=${item.title} pos=${e.position} willApply=${hoverBackground.toARGB32().toRadixString(16)}',
          );
        }
        setState(() => _hoveredSubMenuId = item.id);
        // 외부 오버레이에 한번 전달된 위젯은 내부 setState 만으로는 갱신되지 않을 수 있어 재전달
        if (_openDropdownId != null && _currentOpenParent != null) {
          widget.onDropdownContentChanged?.call(
            _buildDropdownContent(_currentOpenParent!, _currentOpenChildren),
          );
        }
      },
      onExit: (e) {
        if (_debugSubHover) {
          debugPrint(
            '[SUB HOVER EXIT ] id=${item.id} title=${item.title} pos=${e.position} removeColor',
          );
        }
        setState(() => _hoveredSubMenuId = null);
        if (_openDropdownId != null && _currentOpenParent != null) {
          widget.onDropdownContentChanged?.call(
            _buildDropdownContent(_currentOpenParent!, _currentOpenChildren),
          );
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_debugSubHover) {
            debugPrint('[SUB CLICK      ] id=${item.id} title=${item.title}');
          }
          _navigateToMenu(item.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isHover ? hoverBackground : Colors.transparent,
          ),
          padding: EdgeInsets.only(
            top: isFirst ? 10 : 4,
            bottom: isLast ? 10 : 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측 인디케이터 (호버 시 강조 바)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  color: isHover ? baseTextColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                item.subIcon ?? item.icon,
                size: 18,
                color: baseTextColor.withValues(alpha: isHover ? 1 : 0.85),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: baseTextColor,
                        fontWeight: isHover ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.15,
                      ),
                    ),
                    if (item.tooltip != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.tooltip!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: baseTextColor.withValues(alpha: 0.7),
                                height: 1.0,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// 메뉴 네비게이션 (권한 기반)
  void _navigateToMenu(String menuId) {
    final authState = ref.read(authProvider);
    final userLevel = authState.user?.permissionLevel ?? PermissionLevel.level5;

    // 상위 메뉴(자체 라우트 없음) 클릭 시 첫 접근 가능한 하위 메뉴로 포워딩
    final menu = MenuRegistry.findById(menuId);
    if (menu != null && menu.hasChildren) {
      // 현재 routeId가 존재하지 않으면 (RouteRegistry에 없는 상위 id) fallback
      final routeExists = RouteRegistry.findById(menuId) != null;
      if (!routeExists) {
        final accessibleChildren = menu.getAccessibleChildren(userLevel);
        if (accessibleChildren.isNotEmpty) {
          menuId = accessibleChildren.first.id; // 재지정
        }
      }
    }

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
        MaterialPageRoute(
          builder: (context) => const SeatLayoutEditor(),
          fullscreenDialog: true,
        ),
      );

      return; // 중앙집중 네비게이션 실행 방지
    }

    // 나머지는 권한 기반 중앙집중 네비게이션 사용
    ref
        .read(currentScreenProvider.notifier)
        .navigateWithPermission(menuId, userLevel);
    widget.onMenuItemSelected?.call();

    // 드롭다운 닫기
    setState(() {
      _openDropdownId = null;
    });
    widget.onDropdownChanged?.call(null);
    widget.onDropdownContentChanged?.call(null);

    // 성공 메시지 표시
    final confirmMenu = MenuRegistry.findById(menuId);
    if (confirmMenu != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${confirmMenu.title} 화면으로 이동했습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 권한 레벨에 따른 색상 반환
  Color _getPermissionColor(PermissionLevel level) {
    final scheme = Theme.of(context).colorScheme;
    switch (level) {
      case PermissionLevel.level1:
        return scheme.error; // 가장 높은 권한 경고성 강조
      case PermissionLevel.level2:
        return scheme.tertiary;
      case PermissionLevel.level3:
        return scheme.primary;
      case PermissionLevel.level4:
        return scheme.secondary;
      case PermissionLevel.level5:
        return scheme.outline; // 가장 낮은 권한 중립
    }
  }

  /// 현재 상단 가로 메뉴 아이템들의 전체 좌/우 경계를 계산
  /// 반환: [left, right] or null (계산 불가 시)
  List<double>? _getMenuClusterBounds() {
    if (_menuKeys.isEmpty) return null;
    double? minX;
    double? maxX;
    for (final entry in _menuKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final pos = box.localToGlobal(Offset.zero);
      minX = (minX == null) ? pos.dx : (pos.dx < minX ? pos.dx : minX);
      final right = pos.dx + box.size.width;
      maxX = (maxX == null) ? right : (right > maxX ? right : maxX);
    }
    if (minX == null || maxX == null) return null;
    return [minX, maxX];
  }
}
