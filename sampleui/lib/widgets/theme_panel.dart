import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';

class ThemePanel extends ConsumerWidget {
  const ThemePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final currentThemeColor = ref.watch(currentThemeColorProvider);
    final currentFontLevel = ref.watch(currentFontSizeLevelProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 - Auto Reload Test 123
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.palette, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '테마 및 폰트 설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 테마 설정
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '테마설정',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 테마 모드 선택
                  Text('테마 모드', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),

                  ...AppThemeMode.values.map(
                    (mode) => RadioListTile<AppThemeMode>(
                      title: Text(mode.displayName),
                      value: mode,
                      groupValue: currentThemeMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(value);
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 테마 색상 선택
                  Text('테마 색상', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemeColor.values
                        .map(
                          (color) => GestureDetector(
                            onTap: () {
                              ref
                                  .read(themeColorProvider.notifier)
                                  .setThemeColor(color);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: currentThemeColor == color
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  width: currentThemeColor == color ? 3 : 1,
                                ),
                              ),
                              child: currentThemeColor == color
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 폰트 크기 설정
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '폰트크기 설정',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: FontSizeLevel.values.map((level) {
                      final isSelected = currentFontLevel == level;
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(fontSizeProvider.notifier)
                              .setFontSizeLevel(level);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${level.level}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '현재: ${currentFontLevel.displayName} (${currentFontLevel.scaleFactor}x)',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 생성된 코드
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '적용된 위젯 속성 리스트 텍스트박스',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _generateCodeOutput(
                              currentThemeMode,
                              currentThemeColor,
                              currentFontLevel,
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // 클립보드에 복사 기능 추가 예정
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('복사'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // 초기화 기능
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('초기화'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateCodeOutput(
    AppThemeMode themeMode,
    AppThemeColor themeColor,
    FontSizeLevel fontLevel,
  ) {
    return '''
// 현재 설정된 테마 및 폰트 속성
ThemeData(
  brightness: ${themeMode == AppThemeMode.dark ? 'Brightness.dark' : 'Brightness.light'},
  primarySwatch: MaterialColor(${themeColor.colorValue}, <int, Color>{
    50: Color(0x${themeColor.colorValue.toRadixString(16).padLeft(8, '0')}),
    // ... 기타 색상 팔레트
  }),
  fontFamily: 'default',
  textTheme: TextTheme(
    // 폰트 크기 스케일: ${fontLevel.scaleFactor}x
    bodyLarge: TextStyle(fontSize: ${16 * fontLevel.scaleFactor}),
    bodyMedium: TextStyle(fontSize: ${14 * fontLevel.scaleFactor}),
    titleLarge: TextStyle(fontSize: ${22 * fontLevel.scaleFactor}),
  ),
)

// 선택된 설정값
테마 모드: ${themeMode.displayName}
테마 색상: ${themeColor.displayName}
폰트 크기: ${fontLevel.displayName} (${fontLevel.scaleFactor}x)

// 위젯 속성 (선택된 위젯에 따라 동적 생성)
Container(
  width: 100,
  height: 50,
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Color(0x${themeColor.colorValue.toRadixString(16).padLeft(8, '0')}),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Sample Text',
    style: TextStyle(
      fontSize: ${16 * fontLevel.scaleFactor},
      color: Colors.white,
    ),
  ),
)
''';
  }
}
