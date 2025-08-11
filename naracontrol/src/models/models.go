package models

import (
	"encoding/json"
	"time"
)

// 클라이언트 정보를 저장할 구조체
type Client struct {
	ID            string
	CompanyCode   string
	UserCode      string
	Type          string    // naradesk 또는 naradevice
	CreatedAt     time.Time // 연결 생성 시간
	UseBinaryMode bool      // 바이너리 메시지 모드 사용 여부
	DeviceTagged  string    // 디바이스 특수 태그 (예: QF1003)
}

// 메시지 구조체 - 바이너리 구조와 통일
type Message struct {
	CompanyCode string `json:"companyCode"`
	UserCode    string `json:"userCode"`
	Source      string `json:"source"` // naradesk 또는 naradevice (추가)
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
	Source      string `json:"source"` // naradesk 또는 naradevice
}
