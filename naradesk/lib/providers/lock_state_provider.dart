import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 배치도 이동 잠금 상태 Provider (기본값: true - 잠금상태)
final layoutMoveLockProvider = StateProvider<bool>((ref) => true);

/// 좌석 배치 변경 잠금 상태 Provider (기본값: true - 잠금상태)
final seatEditLockProvider = StateProvider<bool>((ref) => true);
