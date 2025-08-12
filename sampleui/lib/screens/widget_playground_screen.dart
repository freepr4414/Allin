import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  double? _mainWidth; // null로 초기화하여 build에서 설정

  @override
  Widget build(BuildContext context) {
    // 첫 빌드 시 화면 너비의 50%로 설정
    _mainWidth ??= MediaQuery.of(context).size.width * 0.5;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('위젯 플레이그라운드'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // 메인 프리뷰 패널 (크기 조절 가능)
          Container(
            width: _mainWidth ?? MediaQuery.of(context).size.width * 0.5,
            constraints: const BoxConstraints(
              minWidth: 100.0,
            ),
            child: const WidgetPreviewPanel(),
          ),
          // 크기 조절 핸들
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                final minWidth = 100.0;
                final maxWidth = MediaQuery.of(context).size.width - 200.0;
                setState(() {
                  _mainWidth = ((_mainWidth ?? 0) + details.delta.dx).clamp(minWidth, maxWidth);
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  right: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: const PropertyPanel(),
            ),
          ),
          // 사이드바 2: 테마 패널
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: const ThemePanel(),
            ),
          ),
        ],
      ),
    );
  }
}
