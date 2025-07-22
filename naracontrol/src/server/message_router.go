package server

import (
	"log"

	"github.com/soinfree/naracontrol/src/message"
	"github.com/soinfree/naracontrol/src/models"
	"github.com/soinfree/naracontrol/src/tcp"
)

// SetupMessageRouter는 메시지 라우터를 설정합니다.
func SetupMessageRouter(serverInstance *Server, tcpServer *tcp.TCPServer) {
	// 메시지 라우터 설정 - 중앙 집중식 메시지 라우팅 로직 구현
	var routeFunc RouteMessageFunc = func(sender *models.Client, data []byte) {
		log.Printf("메시지 라우팅 시작 - 클라이언트: %s, 회사코드: %s, 타입: %s",
			sender.ID, sender.CompanyCode, sender.Type)

		// 메시지 크기 로깅 (디버깅용)
		log.Printf("메시지 크기: %d 바이트", len(data))

		// 메시지의 처음 100바이트 로깅 (디버깅용, 바이너리 데이터 유의)
		if len(data) > 0 {
			previewSize := min(len(data), 100)
			log.Printf("메시지 미리보기: %s", string(data[:previewSize]))
		}

		// 메시지 라우팅 로직을 message 패키지의 RouteMessage 함수로 위임
		message.RouteMessage(serverInstance, sender, data)
	}

	serverInstance.SetMessageRouter(routeFunc)
	log.Printf("메시지 라우터가 설정되었습니다. TCP 서버 참조: %v", tcpServer != nil)
}
