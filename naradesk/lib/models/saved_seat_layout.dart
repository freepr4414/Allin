import 'dart:convert';

/// 저장된 좌석 배치도 데이터 모델
class SavedSeatLayout {
  final List<SeatData> seats;
  final LayoutSettings layoutSettings;
  final DateTime savedAt;
  final String version;

  const SavedSeatLayout({
    required this.seats,
    required this.layoutSettings,
    required this.savedAt,
    this.version = '1.0',
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'seats': seats.map((seat) => seat.toJson()).toList(),
      'layoutSettings': layoutSettings.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'version': version,
    };
  }

  /// JSON에서 복원
  factory SavedSeatLayout.fromJson(Map<String, dynamic> json) {
    return SavedSeatLayout(
      seats: (json['seats'] as List)
          .map((seatJson) => SeatData.fromJson(seatJson))
          .toList(),
      layoutSettings: LayoutSettings.fromJson(json['layoutSettings']),
      savedAt: DateTime.parse(json['savedAt']),
      version: json['version'] ?? '1.0',
    );
  }

  /// JSON 문자열로 직렬화
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// JSON 문자열에서 복원
  factory SavedSeatLayout.fromJsonString(String jsonString) {
    return SavedSeatLayout.fromJson(jsonDecode(jsonString));
  }

  SavedSeatLayout copyWith({
    List<SeatData>? seats,
    LayoutSettings? layoutSettings,
    DateTime? savedAt,
    String? version,
  }) {
    return SavedSeatLayout(
      seats: seats ?? this.seats,
      layoutSettings: layoutSettings ?? this.layoutSettings,
      savedAt: savedAt ?? this.savedAt,
      version: version ?? this.version,
    );
  }
}

/// 개별 좌석 데이터
class SeatData {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String number;
  final int colorValue; // Color를 int로 저장

  const SeatData({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.number,
    required this.colorValue,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'number': number,
      'colorValue': colorValue,
    };
  }

  /// JSON에서 복원
  factory SeatData.fromJson(Map<String, dynamic> json) {
    return SeatData(
      id: json['id'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      number: json['number'],
      colorValue: json['colorValue'],
    );
  }

  SeatData copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    String? number,
    int? colorValue,
  }) {
    return SeatData(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      number: number ?? this.number,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

/// 배치도 전체 설정
class LayoutSettings {
  final double top;
  final double left;
  final double width;
  final double height;
  final int backgroundColorValue; // Color를 int로 저장
  final int borderColorValue; // Color를 int로 저장
  final double rotation; // 회전 각도 (도 단위)

  const LayoutSettings({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.backgroundColorValue,
    required this.borderColorValue,
    this.rotation = 0.0,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'top': top,
      'left': left,
      'width': width,
      'height': height,
      'backgroundColorValue': backgroundColorValue,
      'borderColorValue': borderColorValue,
      'rotation': rotation,
    };
  }

  /// JSON에서 복원
  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    return LayoutSettings(
      top: json['top'].toDouble(),
      left: json['left'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      backgroundColorValue: json['backgroundColorValue'],
      borderColorValue: json['borderColorValue'],
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  LayoutSettings copyWith({
    double? top,
    double? left,
    double? width,
    double? height,
    int? backgroundColorValue,
    int? borderColorValue,
    double? rotation,
  }) {
    return LayoutSettings(
      top: top ?? this.top,
      left: left ?? this.left,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      rotation: rotation ?? this.rotation,
    );
  }
}
