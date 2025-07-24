import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 설정 팝업의 표시 여부를 관리하는 프로바이더
final settingsPopupVisibilityProvider = StateProvider<bool>((ref) => false);
