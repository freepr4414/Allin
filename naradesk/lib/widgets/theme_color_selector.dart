import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';

class ThemeColorSelector extends ConsumerWidget {
  const ThemeColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(currentThemeColorProvider);
    final fontSizeRatio = ref.watch(currentBaseFontSizeProvider) / 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '테마컬러',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize:
                  (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) *
                  fontSizeRatio,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: AppThemeColor.values.map((color) {
            final isSelected = currentColor == color;
            return GestureDetector(
              onTap: () {
                print('테마 컬러 선택 - 기존: ${currentColor.name}, 새로운: ${color.name}');
                ref.read(themeProvider.notifier).setThemeColor(color);
              },
              child: Container(
                width: 40.0 * fontSizeRatio,
                height: 40.0 * fontSizeRatio,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3.0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20.0 * fontSizeRatio,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
