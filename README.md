# 🏢 Allin Project - Study Cafe Management System

종합적인 스터디카페 관리 시스템입니다.

## 📁 프로젝트 구조

```
Allin/
├── 📱 naradesk/          # Flutter 데스크톱 관리자 앱
├── 📱 naradevice/        # Flutter 디바이스 앱
├── 🔧 narabackend/       # Go 백엔드 서버
├── 🎮 naracontrol/       # Go 컨트롤 서버
├── 🗄️ naradbmake/        # Go 데이터베이스 관리
└── 💬 chat-manager/      # PowerShell 채팅 관리 스크립트
```

## 🚀 주요 기능

### 📱 naradesk (Flutter Desktop)
- 관리자용 데스크톱 애플리케이션
- 회원 관리, 결제 내역, 대시보드
- 반응형 UI 및 테마 시스템
- 폰트 크기 조절 기능

### 📱 naradevice (Flutter)
- 사용자용 모바일/태블릿 앱
- 좌석 예약 및 이용 현황

### 🔧 narabackend (Go)
- RESTful API 서버
- 데이터베이스 연동
- 사용자 인증 및 권한 관리

### 🎮 naracontrol (Go)
- 실시간 제어 서버
- WebSocket 통신
- 좌석 상태 관리

### 🗄️ naradbmake (Go)
- 데이터베이스 스키마 관리
- 초기 데이터 생성
- 마이그레이션 도구

## 🛠️ 개발 환경

- **Flutter**: 3.x
- **Go**: 1.21+
- **Database**: MySQL/PostgreSQL
- **OS**: Windows, macOS, Linux

## 📝 최근 업데이트

### 2025-08-11
- ✅ DataTable2 폰트 크기 적용 문제 해결
- ✅ 회원목록/결제내역 배지 폰트 반응형 적용
- ✅ 디버깅 로그 정리
- ✅ Git 저장소 통합 설정

## 🔧 빌드 방법

### Flutter 앱
```bash
cd naradesk
flutter pub get
flutter run -d windows

cd naradevice
flutter pub get
flutter run
```

### Go 서버
```bash
cd narabackend
go build -o bin/server.exe ./src

cd naracontrol
go build -o bin/naracontrol.exe ./src
```

## 📄 라이선스

Private Project
