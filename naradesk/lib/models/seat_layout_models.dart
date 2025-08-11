import 'package:flutter/material.dart';

/// 좌석 배치도 데이터 모델
class SeatLayoutData {
  final double top;
  final double left;
  final double width;
  final double height;
  final double rotation; // 배치도 전체 회전 각도 (도 단위)
  final Color backgroundColor;
  final Color borderColor;
  final List<Seat> seats;

  const SeatLayoutData({
    this.top = 50,
    this.left = 50,
    this.width = 1800,
    this.height = 900,
    this.rotation = 0,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.seats = const [],
  });

  SeatLayoutData copyWith({
    double? top,
    double? left,
    double? width,
    double? height,
    double? rotation,
    Color? backgroundColor,
    Color? borderColor,
    List<Seat>? seats,
  }) {
    return SeatLayoutData(
      top: top ?? this.top,
      left: left ?? this.left,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      seats: seats ?? this.seats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeatLayoutData &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          left == other.left &&
          width == other.width &&
          height == other.height &&
          rotation == other.rotation &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          seats == other.seats;

  @override
  int get hashCode =>
      top.hashCode ^
      left.hashCode ^
      width.hashCode ^
      height.hashCode ^
      rotation.hashCode ^
      backgroundColor.hashCode ^
      borderColor.hashCode ^
      seats.hashCode;
}

/// 좌석 모델
class Seat {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color backgroundColor;
  final String number;
  final bool isSelected;

  const Seat({
    required this.id,
    required this.x,
    required this.y,
    this.width = 100,
    this.height = 100,
    this.backgroundColor = Colors.grey,
    required this.number,
    this.isSelected = false,
  });

  Seat copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    Color? backgroundColor,
    String? number,
    bool? isSelected,
  }) {
    return Seat(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      number: number ?? this.number,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Seat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          backgroundColor == other.backgroundColor &&
          number == other.number &&
          isSelected == other.isSelected;

  @override
  int get hashCode =>
      id.hashCode ^
      x.hashCode ^
      y.hashCode ^
      width.hashCode ^
      height.hashCode ^
      backgroundColor.hashCode ^
      number.hashCode ^
      isSelected.hashCode;
}
