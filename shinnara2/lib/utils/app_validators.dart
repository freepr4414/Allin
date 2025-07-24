import '../models/unified_menu_models.dart';

/// 통일된 유효성 검사 시스템
class AppValidators {
  /// 필수 필드 검사
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '필수 입력 항목입니다';
    }
    return null;
  }

  /// 최소 길이 검사
  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.length < minLength) {
      return fieldName != null
          ? '$fieldName은(는) 최소 $minLength자 이상이어야 합니다'
          : '최소 $minLength자 이상 입력해주세요';
    }
    return null;
  }

  /// 최대 길이 검사
  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return fieldName != null
          ? '$fieldName은(는) 최대 $maxLength자까지 입력 가능합니다'
          : '최대 $maxLength자까지 입력 가능합니다';
    }
    return null;
  }

  /// 이메일 형식 검사
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  /// 전화번호 형식 검사
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '전화번호를 입력해주세요';
    }

    // 숫자와 하이픈만 허용
    final phoneRegex = RegExp(r'^[0-9-]+$');
    if (!phoneRegex.hasMatch(value)) {
      return '올바른 전화번호 형식이 아닙니다';
    }

    // 최소 길이 체크 (하이픈 제외)
    final numbersOnly = value.replaceAll('-', '');
    if (numbersOnly.length < 10) {
      return '전화번호가 너무 짧습니다';
    }

    return null;
  }

  /// 숫자 형식 검사
  static String? number(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '숫자를 입력해주세요';
    }

    if (double.tryParse(value) == null) {
      return '올바른 숫자 형식이 아닙니다';
    }
    return null;
  }

  /// 정수 형식 검사
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '정수를 입력해주세요';
    }

    if (int.tryParse(value) == null) {
      return '올바른 정수 형식이 아닙니다';
    }
    return null;
  }

  /// 범위 검사 (숫자)
  static String? numberRange(String? value, double min, double max, [String? fieldName]) {
    final numberResult = number(value, fieldName);
    if (numberResult != null) return numberResult;

    final numValue = double.parse(value!);
    if (numValue < min || numValue > max) {
      return fieldName != null
          ? '$fieldName은(는) $min ~ $max 범위여야 합니다'
          : '$min ~ $max 범위의 값을 입력해주세요';
    }
    return null;
  }

  /// 양수 검사
  static String? positiveNumber(String? value, [String? fieldName]) {
    final numberResult = number(value, fieldName);
    if (numberResult != null) return numberResult;

    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return fieldName != null ? '$fieldName은(는) 양수여야 합니다' : '양수를 입력해주세요';
    }
    return null;
  }

  /// 사용자명 형식 검사
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return '사용자명을 입력해주세요';
    }

    if (value.length < 3) {
      return '사용자명은 최소 3자 이상이어야 합니다';
    }

    if (value.length > 20) {
      return '사용자명은 최대 20자까지 입력 가능합니다';
    }

    // 영문, 숫자, 언더스코어만 허용
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return '사용자명은 영문, 숫자, 언더스코어(_)만 사용 가능합니다';
    }

    return null;
  }

  /// 비밀번호 형식 검사
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다';
    }

    if (value.length > 50) {
      return '비밀번호는 최대 50자까지 입력 가능합니다';
    }

    return null;
  }

  /// 비밀번호 확인 검사
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }

    if (value != originalPassword) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  /// 권한 레벨 검사
  static String? permission(PermissionLevel userLevel, PermissionLevel requiredLevel) {
    if (!userLevel.hasPermissionLevel(requiredLevel)) {
      return '${requiredLevel.displayName} 권한이 필요합니다';
    }
    return null;
  }

  /// 좌석 번호 형식 검사
  static String? seatNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '좌석 번호를 입력해주세요';
    }

    final seatNum = int.tryParse(value);
    if (seatNum == null) {
      return '올바른 좌석 번호 형식이 아닙니다';
    }

    if (seatNum <= 0) {
      return '좌석 번호는 1 이상이어야 합니다';
    }

    if (seatNum > 999) {
      return '좌석 번호는 999 이하여야 합니다';
    }

    return null;
  }

  /// 시간 형식 검사 (HH:MM)
  static String? timeFormat(String? value) {
    if (value == null || value.isEmpty) {
      return '시간을 입력해주세요';
    }

    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return '올바른 시간 형식이 아닙니다 (HH:MM)';
    }

    return null;
  }

  /// 날짜 형식 검사 (YYYY-MM-DD)
  static String? dateFormat(String? value) {
    if (value == null || value.isEmpty) {
      return '날짜를 입력해주세요';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return '올바른 날짜 형식이 아닙니다 (YYYY-MM-DD)';
    }
  }

  /// 조합 유효성 검사 (여러 검사를 순차적으로 실행)
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// 조건부 유효성 검사
  static String? conditional(String? value, bool condition, String? Function(String?) validator) {
    if (condition) {
      return validator(value);
    }
    return null;
  }

  /// 리스트 최소 선택 검사
  static String? minSelection<T>(List<T>? items, int minCount, [String? itemName]) {
    if (items == null || items.length < minCount) {
      return itemName != null ? '$itemName을(를) 최소 $minCount개 선택해주세요' : '최소 $minCount개 항목을 선택해주세요';
    }
    return null;
  }

  /// 리스트 최대 선택 검사
  static String? maxSelection<T>(List<T>? items, int maxCount, [String? itemName]) {
    if (items != null && items.length > maxCount) {
      return itemName != null
          ? '$itemName은(는) 최대 $maxCount개까지 선택 가능합니다'
          : '최대 $maxCount개 항목까지 선택 가능합니다';
    }
    return null;
  }
}
