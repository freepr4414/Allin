package server

import (
	"log"

	"github.com/soinfree/naracontrol/src/config"
	"github.com/soinfree/naracontrol/src/models"
	"github.com/soinfree/naracontrol/src/websocket"
)

// SetupWebSocketServer는 WebSocket 서버를 설정하고 시작합니다.
func SetupWebSocketServer(serverInstance *Server) *websocket.WebSocketServer {
	wsServer := websocket.NewWebSocketServer()

	// WebSocket 메시지 전송 함수 설정
	serverInstance.SendWSMessageFunc = func(clientID string, message []byte) error {
		wsClient := wsServer.GetClient(clientID)
		if wsClient != nil {
			return wsServer.SendToClient(clientID, message)
		}
		return nil
	}

	// 메시지 처리 콜백 설정 (바이너리 전용)
	wsServer.SetMessageCallback(func(clientID string, data []byte) {
		// 등록된 실제 WebSocket 클라이언트 정보 조회
		wsClient := wsServer.GetClient(clientID)
		if wsClient == nil {
			log.Printf("WebSocket 클라이언트 %s를 찾을 수 없음", clientID)
			return
		}

		// 바이너리 메시지 처리 (WebSocket도 바이너리 전용)
		var extractedCompanyCode string = wsClient.CompanyCode
		if extractedCompanyCode == "" {
			extractedCompanyCode = "unknown"
		}

		// 바이너리 메시지에서 정보 추출
		if len(data) >= 5 {
			binaryMsg, clientType, err := models.DecodeBinaryMessage(data)
			if err == nil {
				log.Printf("WebSocket 바이너리 메시지 디코딩 성공: 클라이언트타입=%s, 메시지타입=%d", clientType, binaryMsg.Type)
				switch binaryMsg.Type {
				case models.BinaryMessageTypeConnect:
					// 연결 메시지에서 회사코드 추출
					companyCode, userCode, source, err := models.DecodeConnectData(binaryMsg.Data)
					if err == nil && companyCode != "" {
						extractedCompanyCode = companyCode
						wsClient.CompanyCode = companyCode
						wsClient.UserCode = userCode
						wsClient.DeviceType = source
						log.Printf("WebSocket 클라이언트 %s 연결: 회사코드=%s, 사용자코드=%s, 소스=%s",
							clientID, companyCode, userCode, source)
					}
				case models.BinaryMessageTypeMessage:
					// 일반 메시지에서도 회사코드 확인 가능
					companyCode, _, _, _, _, _, _, err := models.DecodeMessageData(binaryMsg.Data)
					if err == nil && companyCode != "" {
						extractedCompanyCode = companyCode
						if wsClient.CompanyCode == "" {
							wsClient.CompanyCode = companyCode
						}
					}
				}
			} else {
				log.Printf("WebSocket 바이너리 메시지 디코딩 실패 - 클라이언트: %s, 오류: %v", clientID, err)
				return
			}
		} else {
			log.Printf("WebSocket 메시지가 너무 짧음 - 클라이언트: %s, 길이: %d", clientID, len(data))
			return
		}

		// 실제 클라이언트 정보를 기반으로 models.Client 생성
		client := &models.Client{
			ID:            clientID,
			CompanyCode:   extractedCompanyCode,
			UserCode:      wsClient.UserCode,
			Type:          config.ClientTypeNaradesk, // WebSocket은 Naradesk 클라이언트용
			UseBinaryMode: true,                      // 바이너리 모드 사용
		}

		log.Printf("WebSocket 메시지 처리 - 클라이언트: %s, 회사코드: %s, 사용자코드: %s",
			clientID, client.CompanyCode, client.UserCode)

		// 메시지를 라우터로 전달
		if serverInstance.messageRouter != nil {
			serverInstance.messageRouter(client, data)
		}

		// 클라이언트 활동 시간 업데이트
		serverInstance.UpdateClientActivity(client)
	})

	// 클라이언트 연결 콜백 설정
	wsServer.SetConnectCallback(func(client *models.Client) {
		log.Printf("WebSocket 클라이언트 연결: %s", client.ID)

		// WebSocket 클라이언트는 기본적으로 Naradesk 타입 (바이너리 모드)
		if client.Type == "" {
			client.Type = config.ClientTypeNaradesk
		}
		client.UseBinaryMode = true

		// 서버에 클라이언트 등록
		serverInstance.GetRegisterChannel() <- client
	})

	// 클라이언트 연결 해제 콜백 설정
	wsServer.SetDisconnectCallback(func(clientID string) {
		log.Printf("WebSocket 클라이언트 연결 해제: %s", clientID)

		// 모델 클라이언트 생성하여 등록 해제
		client := &models.Client{
			ID:            clientID,
			CompanyCode:   "unknown",
			Type:          config.ClientTypeNaradesk,
			UseBinaryMode: true,
		}

		// 서버에서 클라이언트 등록 해제
		serverInstance.GetUnregisterChannel() <- client
	})

	return wsServer
}
