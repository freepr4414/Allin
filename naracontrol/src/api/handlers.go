package api

import (
	"log"
	"net/http"

	"github.com/soinfree/naracontrol/src/websocket"
)

// SetupHTTPHandlers는 HTTP 핸들러를 설정합니다.
func SetupHTTPHandlers(wsServer *websocket.WebSocketServer) {
	// 헬스체크 엔드포인트
	http.HandleFunc("/health", healthCheckHandler)

	// WebSocket 핸들러 등록
	http.HandleFunc("/ws", wsServer.HandleWebSocket)

	log.Printf("HTTP 핸들러 설정 완료: /health, /ws")
}

// healthCheckHandler는 서버 상태 확인을 위한 헬스체크 핸들러입니다.
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
