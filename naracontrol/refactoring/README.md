# naracontrol 프로젝트 리팩토링 가이드

## 개요

현재 `naracontrol/src/main.go` 파일은 모든 기능이 한 파일에 집중되어 있어 유지보수와 기능 확장이 어렵습니다. 앞으로 계속 기능이 추가될 것을 고려하여 다음과 같이 파일을 여러 패키지로 분리하는 것을 권장합니다.

## 권장 디렉토리 구조

```
naracontrol/
├── pkg/
│   ├── config/
│   │   └── constants.go     # 상수 및 설정 값
│   ├── models/
│   │   └── models.go        # 데이터 모델 정의
│   ├── server/
│   │   └── server.go        # 서버 구조체 및 핵심 서버 기능
│   ├── client/
│   │   └── handler.go       # 클라이언트 연결 처리 로직
│   └── message/
│       └── router.go        # 메시지 라우팅 및 처리 기능
└── src/
    └── main.go              # 메인 함수와 서버 시작 코드
```

## 각 패키지별 역할

### 1. config 패키지

모든 상수와 설정 값을 정의합니다.

```go
package config

import "time"

// 시간 관련 상수
const (
    // 클라이언트 타임아웃 시간 (핑/퐁)
    PongWait = 60 * time.Second
    // 핑 주기 (퐁 대기 시간보다 짧아야 함)
    PingPeriod = (PongWait * 9) / 10
    // 비활성 타임아웃
    InactiveTimeout = 10 * time.Minute
    // 쓰기 타임아웃
    WriteWait = 10 * time.Second
    // 초기 연결 타임아웃
    ConnectTimeout = 10 * time.Second
    // 클라이언트 채널 버퍼 크기
    ClientSendBufferSize = 512
    // 클린업 주기
    CleanupInterval = 5 * time.Minute
    // 상태 로깅 주기
    StatsInterval = 1 * time.Minute
    // 메시지 크기 제한
    MaxMessageSize = 8192 // 8KB
    // 배치 처리 최대 메시지 수
    MaxBatchSize = 10
)

// 클라이언트 타입 상수
const (
    // 클라이언트 타입 (infree 또는 naradevice)
    ClientTypeInfree     = "infree"
    ClientTypeNaradevice = "naradevice"
)

// 메시지 타입 상수
const (
    // 메시지 타입
    MessageTypeConnect = "connect"
    MessageTypeMessage = "message"
    MessageTypePing    = "ping"
    MessageTypePong    = "pong"
    MessageTypeWelcome = "welcome"
)

// 기타 상수
const (
    // 샤드 수
    DefaultShardCount = 16
    // 웹소켓 서버 포트
    ServerPort = ":8080"
)
```

### 2. models 패키지

데이터 모델을 정의합니다.

```go
package models

import (
    "encoding/json"
    "time"

    "github.com/gorilla/websocket"
)

// 클라이언트 정보를 저장할 구조체
type Client struct {
    ID          string
    CompanyCode string
    UserCode    string
    Type        string // infree 또는 naradevice
    Conn        *websocket.Conn
    Send        chan []byte
    CreatedAt   time.Time // 연결 생성 시간
}

// 메시지 구조체
type Message struct {
    CompanyCode string `json:"companyCode"`
    UserCode    string `json:"userCode"`
    RoomCode    string `json:"roomCode"`
    SeatNumber  string `json:"seatNumber"`
    PowerNumber string `json:"powerNumber"`
    Timestamp   string `json:"timestamp"`
}

// 웹소켓 메시지 구조체
type WSMessage struct {
    Type string          `json:"type"` // connect 또는 message
    Data json.RawMessage `json:"data"`
}

// 연결 메시지 구조체
type ConnectMessage struct {
    CompanyCode string `json:"companyCode"`
    UserCode    string `json:"userCode"`
    Source      string `json:"source"` // infree 또는 naradevice
}
```

### 3. server 패키지

서버 구조체 및 핵심 서버 기능을 구현합니다.

```go
package server

import (
    "log"
    "net/http"
    "sync"
    "time"

    "github.com/gorilla/websocket"

    "github.com/soinfree/naracontrol/pkg/config"
    "github.com/soinfree/naracontrol/pkg/models"
)

// 서버 구조체
type Server struct {
    Clients    map[*models.Client]bool
    Register   chan *models.Client
    Unregister chan *models.Client
    Mutex      sync.Mutex

    // 회사 코드별로 클라이언트를 관리하는 맵
    ClientsByCompany map[string]map[*models.Client]bool
    CompanyMutex     sync.RWMutex

    // 타입별로 클라이언트를 관리하는 맵
    ClientsByType map[string]map[*models.Client]bool
    TypeMutex     sync.RWMutex

    // 마지막 활동 시간을 추적하기 위한 맵
    LastActivity  map[*models.Client]time.Time
    ActivityMutex sync.RWMutex

    // 세분화된 뮤텍스 배열 (샤딩)
    MutexShards []*sync.RWMutex
    ShardCount  int
}

// 새 서버 생성
func NewServer() *Server {
    // 서버 초기화 코드...
}

// 서버 실행
func (s *Server) Run() {
    // 서버 실행 코드...
}

// 클라이언트 등록 처리
func (s *Server) HandleClientRegister(client *models.Client) {
    // 클라이언트 등록 코드...
}

// 클라이언트 등록 해제 처리
func (s *Server) HandleClientUnregister(client *models.Client) {
    // 클라이언트 등록 해제 코드...
}

// 기타 서버 관련 메서드들...
```

### 4. client 패키지

클라이언트 연결 처리 로직을 구현합니다.

```go
package client

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "time"

    "github.com/gorilla/websocket"

    "github.com/soinfree/naracontrol/pkg/config"
    "github.com/soinfree/naracontrol/pkg/models"
    "github.com/soinfree/naracontrol/pkg/server"
)

// 웹소켓 연결 처리
func ServeWs(s *server.Server, w http.ResponseWriter, r *http.Request) {
    // 웹소켓 연결 처리 코드...
}

// 초기 연결 메시지 처리
func HandleInitialConnect(client *models.Client) bool {
    // 초기 연결 처리 코드...
}

// 메시지 읽기 펌프
func ReadPump(s *server.Server, client *models.Client) {
    // 메시지 읽기 코드...
}

// 메시지 쓰기 펌프
func WritePump(s *server.Server, client *models.Client) {
    // 메시지 쓰기 코드...
}

// ping 메시지 처리
func HandlePingMessage(s *server.Server, client *models.Client) {
    // ping 메시지 처리 코드...
}
```

### 5. message 패키지

메시지 라우팅 및 처리 관련 기능을 구현합니다.

```go
package message

import (
    "encoding/json"
    "log"

    "github.com/soinfree/naracontrol/pkg/config"
    "github.com/soinfree/naracontrol/pkg/models"
    "github.com/soinfree/naracontrol/pkg/server"
)

// 메시지 라우팅
func RouteMessage(s *server.Server, sender *models.Client, message []byte) {
    // 메시지 라우팅 코드...
}

// 기타 메시지 처리 관련 함수들...
```

### 6. main.go

메인 함수와 서버 시작 코드를 포함합니다.

```go
package main

import (
    "encoding/json"
    "log"
    "net/http"
    "time"

    "github.com/soinfree/naracontrol/pkg/client"
    "github.com/soinfree/naracontrol/pkg/config"
    "github.com/soinfree/naracontrol/pkg/server"
)

func main() {
    log.Println("---------------------------------------")
    log.Println("Starting Naracontrol WebSocket Server...")
    log.Println("Date: ", time.Now().Format(time.RFC1123))
    log.Println("---------------------------------------")

    // 서버 생성 및 실행
    wsServer := server.NewServer()
    go wsServer.Run()

    // 상태 확인용 핸들러
    http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  "running",
            "time":    time.Now().String(),
            "clients": wsServer.GetClientsCount(),
        })
    })

    // 웹소켓 핸들러
    http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
        client.ServeWs(wsServer, w, r)
    })

    log.Println("WebSocket server is running on " + config.ServerPort)
    log.Println("- Connect with WebSocket to ws://localhost" + config.ServerPort + "/ws")
    log.Println("- Check server status at http://localhost" + config.ServerPort + "/status")
    err := http.ListenAndServe(config.ServerPort, nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
```

## 리팩토링 방법

1. 먼저 `pkg` 디렉토리 아래에 필요한 하위 디렉토리들을 생성합니다.
2. 각 패키지에 해당하는 파일을 만들고 관련 코드를 이동합니다.
3. 모든 파일에서 적절한 임포트 경로를 설정합니다.
4. `main.go` 파일을 수정하여 새로운 패키지 구조를 사용하도록 합니다.
5. 코드를 컴파일하고 테스트합니다.

이렇게 코드를 분리하면 각 컴포넌트가 자신의 책임만 가지게 되어 코드의 모듈성이 향상되고 유지 관리가 쉬워집니다. 또한 앞으로 기능을 추가할 때 해당 패키지만 수정하면 되므로 확장성도 좋아집니다.
