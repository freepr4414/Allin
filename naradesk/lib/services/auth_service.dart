import '../models/manager_model.dart';
import '../services/api_service.dart';

/// 인증 관련 API 서비스
/// 로그인, 로그아웃 등 인증 기능을 담당합니다.
class AuthService {
  /// 관리자 로그인
  /// 백엔드의 GetManagers API를 활용하여 ID/PW 검증
  static Future<Manager?> login(String managerId, String password) async {
    try {
      // GetManagers API 호출 (manager_id 필터링을 통한 로그인 검증)
      // GET /managers?manager_id=xxx 형태로 요청
      final response = await ApiService.get('/managers', queryParameters: {
        'manager_id': managerId, // 정확한 ID 매칭
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> managers = response.data as List<dynamic>;
        
        // 검색 결과에서 정확한 ID와 비밀번호 매칭 확인
        for (final managerData in managers) {
          try {
            final manager = Manager.fromJson(managerData as Map<String, dynamic>);
            
            // ID가 정확히 일치하는지 확인
            if (manager.managerId == managerId) {
              // TODO: 실제 프로덕션에서는 백엔드에서 비밀번호 해싱 검증 필요
              // 현재는 테스트용 하드코딩
              if (password == '1111') {
                return manager;
              }
            }
          } catch (e) {
            // Manager 객체 생성 실패 시 다음 항목으로 진행
            continue;
          }
        }
        
        // 일치하는 관리자가 없거나 비밀번호가 틀린 경우
        return null;
      }
      
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('로그인 처리 중 오류가 발생했습니다');
    }
  }

  /// 특정 관리자 정보 조회
  static Future<Manager?> getManager(String managerId) async {
    try {
      final response = await ApiService.get('/managers/$managerId');
      
      if (response.statusCode == 200) {
        return Manager.fromJson(response.data as Map<String, dynamic>);
      }
      
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('관리자 정보 조회 중 오류가 발생했습니다');
    }
  }

  /// 로그아웃 (현재는 로컬 상태만 정리)
  static Future<void> logout() async {
    // 현재는 별도 API 호출 없이 로컬 상태만 정리
    // 추후 세션 관리가 추가되면 백엔드 API 호출 필요
  }
}
