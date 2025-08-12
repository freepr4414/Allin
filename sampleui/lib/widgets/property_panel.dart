import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/widget_selection_provider.dart';

class PropertyPanel extends ConsumerWidget {
  const PropertyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWidget = ref.watch(selectedWidgetProvider);
    final properties = ref.watch(widgetPropertiesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.settings, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '위젯 속성',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 선택된 위젯 표시
          Text(
            '선택된 위젯: ${selectedWidget.displayName}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // 속성 설정 영역
          Expanded(
            child: selectedWidget == SelectedWidgetType.none
                ? const Center(
                    child: Text(
                      '위젯을 클릭하여 속성을 편집하세요',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: _buildPropertiesForWidget(
                      context,
                      ref,
                      selectedWidget,
                      properties,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForWidget(
    BuildContext context,
    WidgetRef ref,
    SelectedWidgetType widgetType,
    WidgetProperties properties,
  ) {
    switch (widgetType) {
      case SelectedWidgetType.container:
        return _buildContainerProperties(context, ref, properties);
      case SelectedWidgetType.text:
        return _buildTextProperties(context, ref, properties);
      case SelectedWidgetType.button:
        return _buildButtonProperties(context, ref, properties);
      case SelectedWidgetType.textField:
        return _buildTextFieldProperties(context, ref, properties);
      case SelectedWidgetType.checkbox:
      case SelectedWidgetType.radioButton:
      case SelectedWidgetType.switch_:
        return _buildBooleanProperties(context, ref, properties);
      case SelectedWidgetType.slider:
        return _buildSliderProperties(context, ref, properties);
      case SelectedWidgetType.dropdownButton:
        return _buildDropdownProperties(context, ref, properties);
      case SelectedWidgetType.icon:
        return _buildIconProperties(context, ref, properties);
      case SelectedWidgetType.card:
        return _buildCardProperties(context, ref, properties);
      case SelectedWidgetType.listTile:
        return _buildListTileProperties(context, ref, properties);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContainerProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('크기'),
        _buildSliderProperty(
          'Width',
          properties.width,
          50.0,
          400.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('width', value),
        ),
        _buildSliderProperty(
          'Height',
          properties.height,
          50.0,
          300.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('height', value),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('색상'),
        _buildColorProperty(
          'Background Color',
          properties.backgroundColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('backgroundColor', color),
        ),
        _buildSliderProperty(
          'Background Opacity',
          properties.backgroundOpacity,
          0.0,
          1.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('backgroundOpacity', value),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('테두리'),
        _buildSliderProperty(
          'Border Radius',
          properties.borderRadius,
          0.0,
          50.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('borderRadius', value),
        ),
        _buildSliderProperty(
          'Border Width',
          properties.borderWidth,
          0.0,
          10.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('borderWidth', value),
        ),
        _buildColorProperty(
          'Border Color',
          properties.borderColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('borderColor', color),
        ),
      ],
    );
  }

  Widget _buildTextProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('텍스트'),
        _buildTextFieldProperty(
          'Text',
          properties.text,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('text', value),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('스타일'),
        _buildSliderProperty(
          'Font Size',
          properties.fontSize,
          10.0,
          50.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('fontSize', value),
        ),
        _buildColorProperty(
          'Text Color',
          properties.textColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('textColor', color),
        ),
        _buildSliderProperty(
          'Text Opacity',
          properties.textOpacity,
          0.0,
          1.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('textOpacity', value),
        ),
      ],
    );
  }

  Widget _buildButtonProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('버튼'),
        _buildTextFieldProperty(
          'Button Text',
          properties.buttonText,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('buttonText', value),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('스타일'),
        _buildSwitchProperty(
          'Elevated Button',
          properties.isElevated,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('isElevated', value),
        ),
        _buildColorProperty(
          'Button Color',
          properties.buttonColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('buttonColor', color),
        ),
        _buildColorProperty(
          'Text Color',
          properties.buttonTextColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('buttonTextColor', color),
        ),
        _buildSliderProperty(
          'Button Opacity',
          properties.buttonOpacity,
          0.0,
          1.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('buttonOpacity', value),
        ),
      ],
    );
  }

  Widget _buildTextFieldProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('텍스트 필드'),
        _buildTextFieldProperty(
          'Hint Text',
          properties.hintText,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('hintText', value),
        ),
        _buildTextFieldProperty(
          'Label Text',
          properties.labelText,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('labelText', value),
        ),
        _buildSwitchProperty(
          'Obscure Text',
          properties.obscureText,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('obscureText', value),
        ),
      ],
    );
  }

  Widget _buildBooleanProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('옵션'),
        _buildTextFieldProperty(
          'Title',
          properties.title,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('title', value),
        ),
        _buildSwitchProperty(
          'Value',
          properties.boolValue,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('boolValue', value),
        ),
      ],
    );
  }

  Widget _buildSliderProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('슬라이더'),
        _buildSliderProperty(
          'Current Value',
          properties.sliderValue,
          properties.sliderMin,
          properties.sliderMax,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('sliderValue', value),
        ),
        _buildSliderProperty(
          'Min Value',
          properties.sliderMin,
          0.0,
          100.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('sliderMin', value),
        ),
        _buildSliderProperty(
          'Max Value',
          properties.sliderMax,
          100.0,
          1000.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('sliderMax', value),
        ),
      ],
    );
  }

  Widget _buildDropdownProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('드롭다운'),
        Text('Selected: ${properties.selectedDropdownValue}'),
        const SizedBox(height: 8),
        const Text('Available options:'),
        ...properties.dropdownItems.map(
          (item) => ListTile(
            dense: true,
            title: Text(item),
            trailing: Icon(
              item == properties.selectedDropdownValue ? Icons.check : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('아이콘'),
        _buildSliderProperty(
          'Icon Size',
          properties.iconSize,
          16.0,
          100.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('iconSize', value),
        ),
        _buildColorProperty(
          'Icon Color',
          properties.iconColor,
          (color) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('iconColor', color),
        ),
        _buildSliderProperty(
          'Icon Opacity',
          properties.iconOpacity,
          0.0,
          1.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('iconOpacity', value),
        ),
      ],
    );
  }

  Widget _buildCardProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('카드'),
        _buildSliderProperty(
          'Elevation',
          properties.elevation,
          0.0,
          20.0,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('elevation', value),
        ),
        _buildSwitchProperty(
          'Show Shadow',
          properties.showShadow,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('showShadow', value),
        ),
      ],
    );
  }

  Widget _buildListTileProperties(
    BuildContext context,
    WidgetRef ref,
    WidgetProperties properties,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('리스트 타일'),
        _buildTextFieldProperty(
          'Title',
          properties.title,
          (value) => ref
              .read(widgetPropertiesProvider.notifier)
              .updateProperty('title', value),
        ),
      ],
    );
  }

  // 헬퍼 위젯들
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildSliderProperty(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorProperty(
    String label,
    Color color,
    Function(Color) onChanged,
  ) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.grey,
      Colors.black,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors
              .map(
                (c) => GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      border: Border.all(
                        color: color == c ? Colors.black : Colors.grey,
                        width: color == c ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextFieldProperty(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchProperty(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
