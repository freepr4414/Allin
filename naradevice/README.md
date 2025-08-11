# Naradevice 데스크톱 애플리케이션

Flutter로 개발된 데스크톱 애플리케이션으로, NaraControl 서버와 웹소켓으로 통신합니다.

## 주요 기능

- 회사코드를 통한 NaraControl 서버 연결
- 열람실코드, 좌석번호, 전원번호 입력 및 전송
- WebSocket을 통한 데이터 수신

## 실행 방법

```bash
cd c:\SoInfree\testsock2\naradevice
flutter run -d windows  # Windows에서 실행 시
flutter run -d macos    # macOS에서 실행 시
flutter run -d linux    # Linux에서 실행 시
```

참고: NaraControl 서버가 먼저 실행되어 있어야 웹소켓 연결이 가능합니다.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
