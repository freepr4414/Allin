import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 선택된 위젯 타입
enum SelectedWidgetType {
  none,
  container,
  text,
  button,
  textField,
  checkbox,
  radioButton,
  switch_,
  slider,
  dropdownButton,
  icon,
  image,
  card,
  listTile,
}

extension SelectedWidgetTypeExtension on SelectedWidgetType {
  String get displayName {
    switch (this) {
      case SelectedWidgetType.none:
        return '선택 없음';
      case SelectedWidgetType.container:
        return 'Container';
      case SelectedWidgetType.text:
        return 'Text';
      case SelectedWidgetType.button:
        return 'Button';
      case SelectedWidgetType.textField:
        return 'TextField';
      case SelectedWidgetType.checkbox:
        return 'Checkbox';
      case SelectedWidgetType.radioButton:
        return 'Radio Button';
      case SelectedWidgetType.switch_:
        return 'Switch';
      case SelectedWidgetType.slider:
        return 'Slider';
      case SelectedWidgetType.dropdownButton:
        return 'Dropdown Button';
      case SelectedWidgetType.icon:
        return 'Icon';
      case SelectedWidgetType.image:
        return 'Image';
      case SelectedWidgetType.card:
        return 'Card';
      case SelectedWidgetType.listTile:
        return 'ListTile';
    }
  }
}

/// 위젯 속성 모델
class WidgetProperties {
  // Container 속성
  double width;
  double height;
  Color backgroundColor;
  double borderRadius;
  double borderWidth;
  Color borderColor;
  EdgeInsets padding;
  EdgeInsets margin;

  // Text 속성
  String text;
  double fontSize;
  FontWeight fontWeight;
  Color textColor;
  TextAlign textAlign;

  // Button 속성
  String buttonText;
  Color buttonColor;
  Color buttonTextColor;
  bool isElevated;

  // TextField 속성
  String hintText;
  String labelText;
  bool obscureText;
  int maxLines;

  // Checkbox/Radio/Switch 속성
  bool boolValue;
  String title;

  // Slider 속성
  double sliderValue;
  double sliderMin;
  double sliderMax;
  int sliderDivisions;

  // Dropdown 속성
  List<String> dropdownItems;
  String selectedDropdownValue;

  // Icon 속성
  IconData iconData;
  double iconSize;
  Color iconColor;

  // Card 속성
  double elevation;
  bool showShadow;

  // 투명도 속성
  double backgroundOpacity;
  double textOpacity;
  double buttonOpacity;
  double iconOpacity;

  WidgetProperties({
    this.width = 200.0,
    this.height = 100.0,
    this.backgroundColor = Colors.blue,
    this.borderRadius = 8.0,
    this.borderWidth = 0.0,
    this.borderColor = Colors.grey,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.text = 'Sample Text',
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.textColor = Colors.black,
    this.textAlign = TextAlign.left,
    this.buttonText = 'Button',
    this.buttonColor = Colors.blue,
    this.buttonTextColor = Colors.white,
    this.isElevated = true,
    this.hintText = 'Enter text...',
    this.labelText = 'Label',
    this.obscureText = false,
    this.maxLines = 1,
    this.boolValue = false,
    this.title = 'Option',
    this.sliderValue = 50.0,
    this.sliderMin = 0.0,
    this.sliderMax = 100.0,
    this.sliderDivisions = 10,
    this.dropdownItems = const ['Option 1', 'Option 2', 'Option 3'],
    this.selectedDropdownValue = 'Option 1',
    this.iconData = Icons.star,
    this.iconSize = 24.0,
    this.iconColor = Colors.blue,
    this.elevation = 4.0,
    this.showShadow = true,
    this.backgroundOpacity = 1.0,
    this.textOpacity = 1.0,
    this.buttonOpacity = 1.0,
    this.iconOpacity = 1.0,
  });

  WidgetProperties copyWith({
    double? width,
    double? height,
    Color? backgroundColor,
    double? borderRadius,
    double? borderWidth,
    Color? borderColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    String? text,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    TextAlign? textAlign,
    String? buttonText,
    Color? buttonColor,
    Color? buttonTextColor,
    bool? isElevated,
    String? hintText,
    String? labelText,
    bool? obscureText,
    int? maxLines,
    bool? boolValue,
    String? title,
    double? sliderValue,
    double? sliderMin,
    double? sliderMax,
    int? sliderDivisions,
    List<String>? dropdownItems,
    String? selectedDropdownValue,
    IconData? iconData,
    double? iconSize,
    Color? iconColor,
    double? elevation,
    bool? showShadow,
    double? backgroundOpacity,
    double? textOpacity,
    double? buttonOpacity,
    double? iconOpacity,
  }) {
    return WidgetProperties(
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      textAlign: textAlign ?? this.textAlign,
      buttonText: buttonText ?? this.buttonText,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      isElevated: isElevated ?? this.isElevated,
      hintText: hintText ?? this.hintText,
      labelText: labelText ?? this.labelText,
      obscureText: obscureText ?? this.obscureText,
      maxLines: maxLines ?? this.maxLines,
      boolValue: boolValue ?? this.boolValue,
      title: title ?? this.title,
      sliderValue: sliderValue ?? this.sliderValue,
      sliderMin: sliderMin ?? this.sliderMin,
      sliderMax: sliderMax ?? this.sliderMax,
      sliderDivisions: sliderDivisions ?? this.sliderDivisions,
      dropdownItems: dropdownItems ?? this.dropdownItems,
      selectedDropdownValue:
          selectedDropdownValue ?? this.selectedDropdownValue,
      iconData: iconData ?? this.iconData,
      iconSize: iconSize ?? this.iconSize,
      iconColor: iconColor ?? this.iconColor,
      elevation: elevation ?? this.elevation,
      showShadow: showShadow ?? this.showShadow,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      textOpacity: textOpacity ?? this.textOpacity,
      buttonOpacity: buttonOpacity ?? this.buttonOpacity,
      iconOpacity: iconOpacity ?? this.iconOpacity,
    );
  }
}

/// 선택된 위젯 상태 관리
class SelectedWidgetNotifier extends StateNotifier<SelectedWidgetType> {
  SelectedWidgetNotifier() : super(SelectedWidgetType.none);

  void selectWidget(SelectedWidgetType type) {
    state = type;
  }

  void clearSelection() {
    state = SelectedWidgetType.none;
  }
}

/// 위젯 속성 상태 관리
class WidgetPropertiesNotifier extends StateNotifier<WidgetProperties> {
  WidgetPropertiesNotifier() : super(WidgetProperties());

  void updateProperties(WidgetProperties properties) {
    state = properties;
  }

  void updateProperty<T>(String propertyName, T value) {
    switch (propertyName) {
      case 'width':
        state = state.copyWith(width: value as double);
        break;
      case 'height':
        state = state.copyWith(height: value as double);
        break;
      case 'backgroundColor':
        state = state.copyWith(backgroundColor: value as Color);
        break;
      case 'borderRadius':
        state = state.copyWith(borderRadius: value as double);
        break;
      case 'borderWidth':
        state = state.copyWith(borderWidth: value as double);
        break;
      case 'borderColor':
        state = state.copyWith(borderColor: value as Color);
        break;
      case 'text':
        state = state.copyWith(text: value as String);
        break;
      case 'fontSize':
        state = state.copyWith(fontSize: value as double);
        break;
      case 'fontWeight':
        state = state.copyWith(fontWeight: value as FontWeight);
        break;
      case 'textColor':
        state = state.copyWith(textColor: value as Color);
        break;
      case 'textAlign':
        state = state.copyWith(textAlign: value as TextAlign);
        break;
      case 'buttonText':
        state = state.copyWith(buttonText: value as String);
        break;
      case 'buttonColor':
        state = state.copyWith(buttonColor: value as Color);
        break;
      case 'buttonTextColor':
        state = state.copyWith(buttonTextColor: value as Color);
        break;
      case 'isElevated':
        state = state.copyWith(isElevated: value as bool);
        break;
      case 'hintText':
        state = state.copyWith(hintText: value as String);
        break;
      case 'labelText':
        state = state.copyWith(labelText: value as String);
        break;
      case 'obscureText':
        state = state.copyWith(obscureText: value as bool);
        break;
      case 'maxLines':
        state = state.copyWith(maxLines: value as int);
        break;
      case 'boolValue':
        state = state.copyWith(boolValue: value as bool);
        break;
      case 'title':
        state = state.copyWith(title: value as String);
        break;
      case 'sliderValue':
        state = state.copyWith(sliderValue: value as double);
        break;
      case 'sliderMin':
        state = state.copyWith(sliderMin: value as double);
        break;
      case 'sliderMax':
        state = state.copyWith(sliderMax: value as double);
        break;
      case 'sliderDivisions':
        state = state.copyWith(sliderDivisions: value as int);
        break;
      case 'selectedDropdownValue':
        state = state.copyWith(selectedDropdownValue: value as String);
        break;
      case 'iconData':
        state = state.copyWith(iconData: value as IconData);
        break;
      case 'iconSize':
        state = state.copyWith(iconSize: value as double);
        break;
      case 'iconColor':
        state = state.copyWith(iconColor: value as Color);
        break;
      case 'elevation':
        state = state.copyWith(elevation: value as double);
        break;
      case 'showShadow':
        state = state.copyWith(showShadow: value as bool);
        break;
      case 'backgroundOpacity':
        state = state.copyWith(backgroundOpacity: value as double);
        break;
      case 'textOpacity':
        state = state.copyWith(textOpacity: value as double);
        break;
      case 'buttonOpacity':
        state = state.copyWith(buttonOpacity: value as double);
        break;
      case 'iconOpacity':
        state = state.copyWith(iconOpacity: value as double);
        break;
    }
  }
}

/// Providers
final selectedWidgetProvider =
    StateNotifierProvider<SelectedWidgetNotifier, SelectedWidgetType>(
      (ref) => SelectedWidgetNotifier(),
    );

final widgetPropertiesProvider =
    StateNotifierProvider<WidgetPropertiesNotifier, WidgetProperties>(
      (ref) => WidgetPropertiesNotifier(),
    );

/// 페이지 너비 상태 관리
class PageWidthNotifier extends StateNotifier<double> {
  PageWidthNotifier() : super(800.0);

  void updateWidth(double width) {
    state = width.clamp(400.0, 1200.0);
  }
}

final pageWidthProvider = StateNotifierProvider<PageWidthNotifier, double>(
  (ref) => PageWidthNotifier(),
);
