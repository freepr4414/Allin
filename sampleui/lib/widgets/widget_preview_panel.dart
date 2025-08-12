import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/widget_selection_provider.dart';
import '../theme/app_theme.dart';

class WidgetPreviewPanel extends ConsumerWidget {
  const WidgetPreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeColor = ref.watch(currentThemeColorProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 상단 제목 및 너비 조절
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentThemeColor.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '위젯 미리보기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 메인 미리보기 영역
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.all(16),
                      child: Theme(
                        data: AppTheme.lightTheme(currentThemeColor.color),
                        child: _buildWidgetGrid(context, ref, false),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetGrid(BuildContext context, WidgetRef ref, bool isDark) {
    final properties = ref.watch(widgetPropertiesProvider);
    final selectedWidget = ref.watch(selectedWidgetProvider);

    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.container,
            'Container',
            _buildSampleContainer(properties),
            selectedWidget == SelectedWidgetType.container,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.text,
            'Text',
            _buildSampleText(properties),
            selectedWidget == SelectedWidgetType.text,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.button,
            'Button',
            _buildSampleButton(properties),
            selectedWidget == SelectedWidgetType.button,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.textField,
            'TextField',
            _buildSampleTextField(properties),
            selectedWidget == SelectedWidgetType.textField,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.checkbox,
            'Checkbox',
            _buildSampleCheckbox(properties, ref),
            selectedWidget == SelectedWidgetType.checkbox,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.switch_,
            'Switch',
            _buildSampleSwitch(properties, ref),
            selectedWidget == SelectedWidgetType.switch_,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.slider,
            'Slider',
            _buildSampleSlider(properties, ref),
            selectedWidget == SelectedWidgetType.slider,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.dropdownButton,
            'Dropdown',
            _buildSampleDropdown(properties, ref),
            selectedWidget == SelectedWidgetType.dropdownButton,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.icon,
            'Icon',
            _buildSampleIcon(properties),
            selectedWidget == SelectedWidgetType.icon,
          ),
          _buildClickableWidget(
            context,
            ref,
            SelectedWidgetType.card,
            'Card',
            _buildSampleCard(properties),
            selectedWidget == SelectedWidgetType.card,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableWidget(
    BuildContext context,
    WidgetRef ref,
    SelectedWidgetType widgetType,
    String label,
    Widget widget,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedWidgetProvider.notifier).selectWidget(widgetType);
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.orange.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.orange : null,
              ),
            ),
            const SizedBox(height: 8),
            widget,
          ],
        ),
      ),
    );
  }

  Widget _buildSampleContainer(WidgetProperties properties) {
    return Container(
      width: properties.width * 0.3,
      height: properties.height * 0.4,
      decoration: BoxDecoration(
        color: properties.backgroundColor.withValues(
          alpha: properties.backgroundOpacity,
        ),
        borderRadius: BorderRadius.circular(properties.borderRadius),
        border: properties.borderWidth > 0
            ? Border.all(
                color: properties.borderColor,
                width: properties.borderWidth,
              )
            : null,
      ),
    );
  }

  Widget _buildSampleText(WidgetProperties properties) {
    return Text(
      properties.text,
      style: TextStyle(
        fontSize: properties.fontSize * 0.8,
        fontWeight: properties.fontWeight,
        color: properties.textColor.withValues(alpha: properties.textOpacity),
      ),
      textAlign: properties.textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSampleButton(WidgetProperties properties) {
    return properties.isElevated
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: properties.buttonColor.withValues(
                alpha: properties.buttonOpacity,
              ),
              foregroundColor: properties.buttonTextColor,
            ),
            onPressed: () {},
            child: Text(
              properties.buttonText,
              style: const TextStyle(fontSize: 12),
            ),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: properties.buttonColor.withValues(
                alpha: properties.buttonOpacity,
              ),
              side: BorderSide(
                color: properties.buttonColor.withValues(
                  alpha: properties.buttonOpacity,
                ),
              ),
            ),
            onPressed: () {},
            child: Text(
              properties.buttonText,
              style: const TextStyle(fontSize: 12),
            ),
          );
  }

  Widget _buildSampleTextField(WidgetProperties properties) {
    return SizedBox(
      width: 120,
      child: TextField(
        decoration: InputDecoration(
          hintText: properties.hintText,
          labelText: properties.labelText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
        ),
        obscureText: properties.obscureText,
        maxLines: properties.maxLines,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildSampleCheckbox(WidgetProperties properties, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: properties.boolValue,
          onChanged: (value) {
            ref
                .read(widgetPropertiesProvider.notifier)
                .updateProperty('boolValue', value ?? false);
          },
        ),
        Text(properties.title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSampleSwitch(WidgetProperties properties, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: properties.boolValue,
          onChanged: (value) {
            ref
                .read(widgetPropertiesProvider.notifier)
                .updateProperty('boolValue', value);
          },
        ),
        Text(properties.title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSampleSlider(WidgetProperties properties, WidgetRef ref) {
    return Column(
      children: [
        Text(
          '${properties.sliderValue.toInt()}',
          style: const TextStyle(fontSize: 12),
        ),
        SizedBox(
          width: 120,
          child: Slider(
            value: properties.sliderValue,
            min: properties.sliderMin,
            max: properties.sliderMax,
            divisions: properties.sliderDivisions,
            onChanged: (value) {
              ref
                  .read(widgetPropertiesProvider.notifier)
                  .updateProperty('sliderValue', value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSampleDropdown(WidgetProperties properties, WidgetRef ref) {
    return SizedBox(
      width: 120,
      child: DropdownButton<String>(
        value: properties.selectedDropdownValue,
        isExpanded: true,
        style: const TextStyle(fontSize: 12),
        items: properties.dropdownItems
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            ref
                .read(widgetPropertiesProvider.notifier)
                .updateProperty('selectedDropdownValue', value);
          }
        },
      ),
    );
  }

  Widget _buildSampleIcon(WidgetProperties properties) {
    return Icon(
      properties.iconData,
      size: properties.iconSize * 0.8,
      color: properties.iconColor.withValues(alpha: properties.iconOpacity),
    );
  }

  Widget _buildSampleCard(WidgetProperties properties) {
    return SizedBox(
      width: 120,
      height: 80,
      child: Card(
        elevation: properties.elevation,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'Card Content',
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
