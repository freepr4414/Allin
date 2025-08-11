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
	// 클라이언트 타입 (naradesk 또는 naradevice)
	ClientTypeNaradesk   = "naradesk"   // WebSocket 클라이언트
	ClientTypeNaradevice = "naradevice" // TCP 클라이언트
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
	DefaultShardCount = 16 // 웹소켓 서버 포트
	ServerPort        = ":8090"
)
