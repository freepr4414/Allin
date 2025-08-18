import '../models/manager_model.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class AuthService {
  static Manager? _currentManager;

  /// 현재 로그인한 관리자 정보
  static Manager? get currentManager => _currentManager;

  /// 관리자 로그인 - 올바른 API 엔드포인트 사용
  static Future<Manager?> login(String managerId, String password) async {
    try {
      print('🔐 [AuthService] 로그인 시도 시작');
      print('👤 [AuthService] Manager ID: $managerId');
      print('🔑 [AuthService] Password 길이: ${password.length}');

      // 올바른 엔드포인트: /managers (백엔드에서 정의된 대로)
      print('📡 [AuthService] API 호출 시작: /managers');
      final response = await ApiService.get('/managers');

      print('📊 [AuthService] API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> managersData = response.data;
        print('📋 [AuthService] 받은 데이터 수: ${managersData.length}');
        print('🗂️ [AuthService] 전체 응답 데이터: ${response.data}');

        // 입력한 ID와 비밀번호로 관리자 찾기
        for (int i = 0; i < managersData.length; i++) {
          final managerJson = managersData[i];
          print('🔍 [AuthService] 매니저 [$i] 원본 JSON: $managerJson');

          try {
            final manager = Manager.fromJson(managerJson);
            print('👤 [AuthService] 파싱된 매니저 [$i]:');
            print('   - ID: "${manager.managerId}"');
            print('   - Name: "${manager.managerName}"');
            print('   - Password: "${manager.password}"');
            print('   - Email: "${manager.email}"');

            print('🔎 [AuthService] 비교 중:');
            print(
              '   - 입력된 ID: "$managerId" vs 매니저 ID: "${manager.managerId}"',
            );
            print('   - 입력된 PW: "$password" vs 매니저 PW: "${manager.password}"');
            print('   - ID 매칭: ${manager.managerId == managerId}');
            print('   - PW 매칭: ${manager.password == password}');

            if (manager.managerId == managerId &&
                manager.password == password) {
              print('✅ [AuthService] 로그인 성공! 매니저: ${manager.managerName}');
              _currentManager = manager;
              return manager;
            }
          } catch (e) {
            print('❌ [AuthService] 매니저 데이터 파싱 오류: $e');
          }
        }
      } else {
        developer.log(
          '❌ [AuthService] API 응답 오류: ${response.statusCode}',
          name: 'AUTH_SERVICE',
        );
      }

      developer.log(
        '❌ [AuthService] 로그인 실패: 매칭되는 사용자 없음',
        name: 'AUTH_SERVICE',
      );
      return null; // 로그인 실패
    } catch (e) {
      developer.log('💥 [AuthService] 로그인 예외 발생: $e', name: 'AUTH_SERVICE');
      print('로그인 오류: $e');
      throw ApiException('로그인 중 오류가 발생했습니다: $e');
    }
  }

  /// 로그아웃
  static void logout() {
    _currentManager = null;
  }

  /// 로그인 상태 확인
  static bool get isLoggedIn => _currentManager != null;

  /// 모든 관리자 목록 가져오기 (관리 목적)
  static Future<List<Manager>> getAllManagers() async {
    try {
      final response = await ApiService.get('/managers');

      if (response.statusCode == 200) {
        final List<dynamic> managersData = response.data;
        return managersData.map((json) => Manager.fromJson(json)).toList();
      }

      throw ApiException('관리자 목록을 가져올 수 없습니다');
    } catch (e) {
      print('관리자 목록 조회 오류: $e');
      throw ApiException('관리자 목록 조회 중 오류가 발생했습니다: $e');
    }
  }
}
