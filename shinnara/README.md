# Shinnara 웹 애플리케이션

Flutter로 개발된 웹 애플리케이션으로, NaraControl 서버와 웹소켓으로 통신합니다.

## 주요 기능

- 로그인 기능 (회사코드, 회원코드, 비밀번호)
- WebSocket을 통한 NaraControl 서버 연결
- 연결 페이지에서 데이터 전송 및 수신

## 임시 사용자 데이터

- 회사코드: a1, 회원코드: a101, 비밀번호: 1111
- 회사코드: a1, 회원코드: a102, 비밀번호: 1111
- 회사코드: a2, 회원코드: a201, 비밀번호: 1111
- 회사코드: a2, 회원코드: a202, 비밀번호: 1111

## 실행 방법

```bash
cd c:\SoInfree\testsock2\infree
flutter run -d chrome
```

참고: NaraControl 서버가 먼저 실행되어 있어야 웹소켓 연결이 가능합니다.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
