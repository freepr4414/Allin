import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentThemeModeProvider);
    final fontSizeRatio = ref.watch(currentBaseFontSizeProvider) / 12.0;

    // (디버그 로그 제거됨)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '모드선택',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize:
                  (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) *
                  fontSizeRatio,
            ),
          ),
        ),
        Row(
          children: AppThemeMode.values.map((mode) {
            final isSelected = currentMode == mode;

            // 각 버튼별 색상 상태 로그
            // 현재 테마 모드에 따라 색상 결정 - Provider에서 직접 가져옴
            // (dark 여부 직접 변수 필요 없어짐)

            Color iconColor;
            Color textColor;

            final scheme = Theme.of(context).colorScheme;
            final onSurface = scheme.onSurface;
            if (isSelected) {
              // 선택된 배경색
              // 라이트 모드에서는 onSurface, 다크에서는 onPrimaryContainer 대비 색 사용
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final useOnSurface = !isDark; // 사용자 요구에 맞춰 라이트에서 대비 높이기
              iconColor = useOnSurface ? onSurface : scheme.onPrimaryContainer;
              textColor = useOnSurface ? onSurface : scheme.onPrimaryContainer;
            } else {
              iconColor = onSurface.withValues(alpha: 0.55);
              textColor = onSurface.withValues(alpha: 0.55);
            }

            // (디버그 로그 제거됨)

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.icon,
                        size: 24.0 * fontSizeRatio,
                        color: iconColor, // 위에서 정의한 변수 사용
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        mode.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor, // 위에서 정의한 변수 사용
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.fontSize ??
                                  12) *
                              fontSizeRatio,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
