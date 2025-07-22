# Naracontrol 서버

## 사전 준비

- Go 언어가 설치되어 있어야 합니다.
- Gorilla Websocket 패키지가 필요합니다.

## 패키지 설치

```
cd c:\SoInfree\testsock2\naracontrol
go get github.com/gorilla/websocket
```

## 서버 실행

```
cd c:\SoInfree\testsock2\naracontrol
go run src/main.go
```

이 명령어를 실행하면 웹소켓 서버가 8080 포트에서 실행됩니다.

## 서버 기능:

1. infree 웹과 naradevice 앱의 WebSocket 연결을 관리합니다.
2. infree 웹에서 받은 메시지를 같은 회사 코드를 가진 naradevice 앱에게 전달합니다.
3. naradevice 앱에서 받은 메시지를 같은 회사 코드를 가진 infree 웹에게 전달합니다.
