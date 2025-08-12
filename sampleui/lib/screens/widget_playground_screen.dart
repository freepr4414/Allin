import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_selection_provider.dart';
import '../widgets/property_panel.dart';
import '../widgets/theme_panel.dart';
import '../widgets/widget_preview_panel.dart';

class WidgetPlaygroundScreen extends ConsumerStatefulWidget {
  const WidgetPlaygroundScreen({super.key});

  @override
  ConsumerState<WidgetPlaygroundScreen> createState() =>
      _WidgetPlaygroundScreenState();
}

class _WidgetPlaygroundScreenState
    extends ConsumerState<WidgetPlaygroundScreen> {
  double _mainWidth = 800.0;

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final currentThemeColor = ref.watch(currentThemeColorProvider);
    final currentFontLevel = ref.watch(currentFontSizeLevelProvider);
    final selectedWidget = ref.watch(selectedWidgetProvider);
    final pageWidth = ref.watch(pageWidthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('위젯 플레이그라운드'),
        centerTitle: true,
        actions: [
          // 선택된 위젯 표시
          if (selectedWidget != SelectedWidgetType.none)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  AppConstants.smallBorderRadius,
                ),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.widgets, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    selectedWidget.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 페이지 너비 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.width_full, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '${pageWidth.toInt()}px',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 현재 설정 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
            ),
            child: Text(
              '${currentThemeMode.displayName} • ${currentThemeColor.displayName} • ${currentFontLevel.displayName}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 메인 영역 (가로폭 조절 가능)
          Expanded(
            child: Container(
              width: _mainWidth,
              constraints: BoxConstraints(
                minWidth: AppConstants.playgroundMinWidth,
              ),
              child: const WidgetPreviewPanel(),
            ),
          ),

          // 크기 조절 핸들
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _mainWidth = (_mainWidth + details.delta.dx).clamp(
                    AppConstants.playgroundMinWidth,
                    MediaQuery.of(context).size.width -
                        AppConstants.propertyPanelWidth -
                        AppConstants.themePanelWidth -
                        20,
                  );
                });
              },
              child: Container(
                width: 4,
                color: Colors.grey.shade300,
                child: Center(
                  child: Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 사이드바 1: 속성 설정 패널
          Container(
            width: AppConstants.propertyPanelWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const PropertyPanel(),
          ),

          // 사이드바 2: 테마 및 코드 패널
          Container(
            width: AppConstants.themePanelWidth,
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: const ThemePanel(),
          ),
        ],
      ),
    );
  }
}
