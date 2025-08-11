import 'package:flutter/material.dart';

import '../../constants/seat_layout_constants.dart';

/// 공통 버튼 스타일을 적용하는 래퍼 위젯
class StyledButtonWrapper extends StatelessWidget {
  final Widget child;

  const StyledButtonWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: SeatLayoutConstants.shadowColor,
            blurRadius: SeatLayoutConstants.shadowBlurRadius,
            offset: SeatLayoutConstants.shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}
