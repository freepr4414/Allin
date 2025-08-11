import 'package:flutter/material.dart';

/// 좌석 배치 에디터 관련 상수
class SeatLayoutConstants {
  SeatLayoutConstants._();

  // 기본값
  static const double defaultTop = 50.0;
  static const double defaultLeft = 50.0;
  static const double defaultWidth = 1800.0;
  static const double defaultHeight = 900.0;
  static const Color defaultBackgroundColor = Colors.white;
  static const Color defaultBorderColor = Colors.black;

  // 좌석 기본값
  static const double defaultSeatWidth = 100.0;
  static const double defaultSeatHeight = 100.0;
  static const Color defaultSeatBackgroundColor = Colors.grey;

  // 크기 제한
  static const double minSeatSize = 20.0;
  static const double maxSeatSize = 200.0;

  // 간격 및 여백
  static const double seatSpacing = 120.0;
  static const double seatsPerRow = 10.0;
  static const double seatMargin = 20.0;

  // 이동 및 크기 조절 단위
  static const double moveStep = 5.0;
  static const double resizeStep = 5.0;

  // UI 관련
  static const double handleSize = 8.0;
  static const double borderWidth = 2.0;
  static const double selectedBorderWidth = 3.0;
  static const double buttonPadding = 16.0;
  static const double buttonVerticalPadding = 12.0;
  static const double topButtonsTop = 10.0;
  static const double topButtonsLeft = 16.0;
  static const double buttonSpacing = 8.0;
  static const double popupMaxWidth = 1200.0; // 가로로 늘려서 한 줄 배치 가능하게
  static const double popupMinWidth = 800.0;
  static const double popupMaxHeight = 400.0; // 세로는 줄여서 컴팩트하게

  // 색상
  static const Color selectedBorderColor = Colors.blue;
  static const Color handleColor = Colors.indigo;
  static const Color textColor = Colors.white;

  // 그림자
  static const Color shadowColor = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color popupShadowColor = Color.fromRGBO(0, 0, 0, 0.18);
  static const double shadowBlurRadius = 4.0;
  static const double popupShadowBlurRadius = 16.0;
  static const Offset shadowOffset = Offset(0, 2);
  static const Offset popupShadowOffset = Offset(0, 6);

  // 경계값
  static const double outlineOpacity = 0.3;
  static const int outlineAlpha = 77; // 0.3 * 255 ≈ 77

  // 애니메이션
  static const Duration animationDuration = Duration(milliseconds: 200);

  // 키보드 단축키 관련
  static const String moveKeyDescription = 'Ctrl + 방향키: 이동';
  static const String resizeKeyDescription = 'Shift + 방향키: 크기 변경';

  // 툴팁
  static const String backButtonTooltip = '돌아가기';
  static const String settingsButtonTooltip = '설정';
}
