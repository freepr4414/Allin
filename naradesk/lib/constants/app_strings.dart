/// 앱 전체 문자열 상수 관리 (국제화 대비)
class AppStrings {
  // ============ 일반 메시지 ============
  static const String appTitle = 'Study Cafe Management';
  static const String loading = '로딩 중...';
  static const String error = '오류가 발생했습니다';
  static const String success = '성공적으로 완료되었습니다';
  static const String warning = '경고';
  static const String info = '정보';
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String save = '저장';
  static const String delete = '삭제';
  static const String edit = '편집';
  static const String add = '추가';
  static const String search = '검색';
  static const String filter = '필터';
  static const String refresh = '새로고침';
  static const String retry = '재시도';

  // ============ 로그인 관련 ============
  static const String loginTitle = '스터디카페 관리 시스템';
  static const String loginSubtitle = '관리자 계정으로 로그인하세요';
  static const String username = '사용자명';
  static const String password = '비밀번호';
  static const String login = '로그인';
  static const String loginFailed = '로그인에 실패했습니다';
  static const String invalidCredentials = '잘못된 사용자명 또는 비밀번호입니다';
  static const String loginSuccess = '로그인되었습니다';
  static const String logout = '로그아웃';
  static const String logoutConfirm = '로그아웃하시겠습니까?';

  // ============ 권한 관련 ============
  static const String accessDenied = '접근 권한이 없습니다';
  static const String insufficientPermission = '권한이 부족합니다';
  static const String permissionRequired = '다음 권한이 필요합니다';
  static const String adminOnly = '관리자 전용 기능입니다';

  // ============ 네비게이션 관련 ============
  static const String navigationFailed = '페이지 이동에 실패했습니다';
  static const String pageNotFound = '페이지를 찾을 수 없습니다';
  static const String redirectingToDefault = '기본 페이지로 이동합니다';

  // ============ 메뉴 관련 ============
  static const String dashboard = '대시보드';
  static const String overview = '전체 현황';
  static const String reports = '리포트';
  static const String seatManagement = '좌석 관리';
  static const String seatLayout = '좌석 배치도';
  static const String seatStatus = '좌석 현황';
  static const String seatHistory = '이용 내역';
  static const String memberManagement = '회원 관리';
  static const String memberList = '회원 목록';
  static const String memberRegister = '회원 등록';
  static const String memberPayments = '결제 내역';
  static const String settings = '설정';
  static const String generalSettings = '일반 설정';
  static const String seatSettings = '좌석 설정';
  static const String notificationSettings = '알림 설정';
  static const String adminFunctions = '관리자 기능';
  static const String seatLayoutEditor = '좌석 배치도 편집';
  static const String systemSettings = '시스템 설정';
  static const String userManagement = '사용자 관리';

  // ============ 좌석 관련 ============
  static const String seatNumber = '좌석 번호';
  static const String seatType = '좌석 유형';
  static const String seatAvailable = '이용 가능';
  static const String seatOccupied = '사용 중';
  static const String seatReserved = '예약됨';
  static const String seatMaintenance = '점검 중';
  static const String checkIn = '입실';
  static const String checkOut = '퇴실';
  static const String extend = '연장';
  static const String moveUser = '사용자 이동';

  // ============ 회원 관련 ============
  static const String memberName = '회원명';
  static const String memberPhone = '전화번호';
  static const String memberEmail = '이메일';
  static const String memberType = '회원 유형';
  static const String membershipExpiry = '멤버십 만료일';
  static const String remainingTime = '잔여 시간';
  static const String usageHistory = '이용 기록';

  // ============ 결제 관련 ============
  static const String paymentAmount = '결제 금액';
  static const String paymentMethod = '결제 방법';
  static const String paymentDate = '결제일';
  static const String paymentStatus = '결제 상태';
  static const String refund = '환불';
  static const String refundConfirm = '환불하시겠습니까?';

  // ============ 에러 메시지 ============
  static const String networkError = '네트워크 연결을 확인해주세요';
  static const String serverError = '서버 오류가 발생했습니다';
  static const String dataNotFound = '데이터를 찾을 수 없습니다';
  static const String validationError = '입력값을 확인해주세요';
  static const String unexpectedError = '예상치 못한 오류가 발생했습니다';

  // ============ 성공 메시지 ============
  static const String saveSuccess = '저장되었습니다';
  static const String deleteSuccess = '삭제되었습니다';
  static const String updateSuccess = '수정되었습니다';

  // ============ 확인 메시지 ============
  static const String deleteConfirm = '정말 삭제하시겠습니까?';
  static const String saveConfirm = '저장하시겠습니까?';
  static const String discardChanges = '변경사항을 취소하시겠습니까?';

  // ============ 동적 메시지 생성 함수 ============
  static String navigationMessage(String destination) => '$destination 화면으로 이동했습니다';
  static String permissionDeniedForFeature(String feature) => '$feature 기능에 접근할 권한이 없습니다';
  static String userNotFound(String username) => '사용자 "$username"을 찾을 수 없습니다';
  static String routeNotFound(String routeId) => '라우트 "$routeId"를 찾을 수 없습니다';
  static String featureNotImplemented(String feature) => '$feature 기능은 구현 예정입니다';
  static String itemCount(int count, String item) => '$item $count개';
  static String timeRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분 남음';
    } else {
      return '$minutes분 남음';
    }
  }
}
