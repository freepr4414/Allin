package server

import (
	"log"
	"sync"

	"github.com/soinfree/naracontrol/src/config"
	"github.com/soinfree/naracontrol/src/models"
	"github.com/soinfree/naracontrol/src/tcp"
)

// TCP 클라이언트 ID와 models.Client 매핑
var (
	tcpClientMap   = make(map[string]*models.Client)
	tcpClientMapMu sync.RWMutex
)

// SetupTCPServer는 TCP 서버를 설정하고 시작합니다.
func SetupTCPServer(serverInstance *Server) *tcp.TCPServer {
	// TCP 서버 설정
	tcpAddress := config.GetTCPServerAddress()
	if tcpAddress == "" {
		tcpAddress = ":8091" // TCP 서버는 8091 포트 사용
	}

	tcpServer := tcp.NewTCPServer(tcpAddress)
	if err := tcpServer.Start(); err != nil {
		log.Printf("TCP 서버 시작 실패: %v", err)
		return nil
	}

	// TCP 메시지 전송 함수 설정
	serverInstance.SendTCPMessageFunc = func(clientID string, message []byte) error {
		return tcpServer.SendToClient(clientID, message)
	}

	// 메시지 처리 콜백 설정 (바이너리 전용)
	tcpServer.SetMessageCallback(func(clientID string, data []byte) {
		// 클라이언트 ID를 기반으로 클라이언트 검색
		tcpClient := tcpServer.GetClient(clientID)

		// 바이너리 메시지 처리 (TCP는 바이너리 전용)
		var extractedCompanyCode string = ""
		shouldUpdateCompanyCode := false

		// 바이너리 메시지에서 정보 추출
		if len(data) >= 5 {
			binaryMsg, clientType, err := models.DecodeBinaryMessage(data)
			if err == nil {
				log.Printf("TCP 바이너리 메시지 디코딩 성공: 클라이언트타입=%s, 메시지타입=%d", clientType, binaryMsg.Type)
				switch binaryMsg.Type {
				case models.BinaryMessageTypePing, models.BinaryMessageTypePong:
					// ping/pong 메시지는 회사코드 업데이트 없이 라우팅만 처리
				case models.BinaryMessageTypeConnect:
					// 연결 메시지에서 회사코드 추출
					companyCode, userCode, source, err := models.DecodeConnectData(binaryMsg.Data)
					if err == nil && companyCode != "" {
						extractedCompanyCode = companyCode
						shouldUpdateCompanyCode = true
						if tcpClient != nil {
							tcpClient.SetCompanyCode(companyCode)
							tcpClient.SetDeviceType("naradevice") // TCP는 항상 naradevice
						}
						log.Printf("TCP 클라이언트 %s 연결 메시지: 회사코드=%s, 사용자코드=%s, 소스=%s",
							clientID, companyCode, userCode, source)
					}
				case models.BinaryMessageTypeMessage:
					// 일반 메시지에서도 회사코드 확인 가능
					companyCode, _, _, _, _, _, _, err := models.DecodeMessageData(binaryMsg.Data)
					if err == nil && companyCode != "" {
						extractedCompanyCode = companyCode
						shouldUpdateCompanyCode = true
						if tcpClient != nil && tcpClient.CompanyCode == "" {
							tcpClient.SetCompanyCode(companyCode)
						}
					}
				}
			} else {
				log.Printf("TCP 바이너리 메시지 디코딩 실패 - 클라이언트: %s, 오류: %v", clientID, err)
				return
			}
		} else {
			log.Printf("TCP 메시지가 너무 짧음 - 클라이언트: %s, 길이: %d", clientID, len(data))
			return
		}

		// 서버에서 기존 등록된 클라이언트 찾기 (매핑 사용)
		tcpClientMapMu.RLock()
		registeredClient, exists := tcpClientMap[clientID]
		tcpClientMapMu.RUnlock()

		// 회사코드 업데이트가 필요한 경우에만 처리
		if shouldUpdateCompanyCode && exists && registeredClient != nil && extractedCompanyCode != "" {
			if registeredClient.CompanyCode != extractedCompanyCode {
				log.Printf("기존 클라이언트 %s의 회사코드 업데이트: %s -> %s",
					clientID, registeredClient.CompanyCode, extractedCompanyCode)

				// 기존 회사별 인덱스에서 제거
				if registeredClient.CompanyCode != "" {
					serverInstance.CompanyMutex.Lock()
					if oldCompanyClients, exists := serverInstance.ClientsByCompany[registeredClient.CompanyCode]; exists {
						delete(oldCompanyClients, registeredClient)
					}
					serverInstance.CompanyMutex.Unlock()
				}

				// 회사코드 업데이트
				registeredClient.CompanyCode = extractedCompanyCode

				// 새로운 회사별 인덱스에 추가
				companyClients := serverInstance.getCompanyClients(extractedCompanyCode)
				serverInstance.CompanyMutex.Lock()
				companyClients[registeredClient] = true
				serverInstance.CompanyMutex.Unlock()
			}
		}

		// 등록된 클라이언트가 있는지 확인
		if !exists || registeredClient == nil {
			// 등록된 클라이언트가 없으면 로그만 출력 (정상적이지 않은 상황)
			log.Printf("경고: 매핑되지 않은 클라이언트 %s에서 메시지 수신", clientID)
			return
		}

		// 중앙 메시지 라우터를 통해 메시지 라우팅
		if serverInstance.messageRouter != nil {
			serverInstance.messageRouter(registeredClient, data)
		}
	})

	// 클라이언트 연결 콜백 설정
	tcpServer.SetConnectCallback(func(client *tcp.TCPClient) {
		log.Printf("TCP 클라이언트 연결: %s (%s)", client.ID, client.Conn.RemoteAddr().String())

		// 기본적으로 naradevice 타입으로 등록
		modelClient := &models.Client{
			ID:            client.ID,
			CompanyCode:   "unknown",                   // 초기 기본값
			Type:          config.ClientTypeNaradevice, // TCP는 Naradevice 클라이언트용
			UseBinaryMode: true,                        // 바이너리 모드 사용
		}

		// 클라이언트 매핑 저장
		tcpClientMapMu.Lock()
		tcpClientMap[client.ID] = modelClient
		tcpClientMapMu.Unlock()

		// 서버에 클라이언트 등록
		serverInstance.GetRegisterChannel() <- modelClient
	})

	// 클라이언트 연결 해제 콜백 설정
	tcpServer.SetDisconnectCallback(func(clientID string) {
		log.Printf("TCP 클라이언트 연결 해제: %s", clientID)

		// 매핑된 클라이언트 객체 가져오기
		tcpClientMapMu.RLock()
		modelClient, exists := tcpClientMap[clientID]
		tcpClientMapMu.RUnlock()

		if exists {
			// 서버에서 클라이언트 등록 해제
			serverInstance.GetUnregisterChannel() <- modelClient

			// 매핑에서 제거
			tcpClientMapMu.Lock()
			delete(tcpClientMap, clientID)
			tcpClientMapMu.Unlock()
		}
	})

	log.Printf("TCP 서버가 %s에서 시작되었습니다", tcpAddress)
	return tcpServer
}
