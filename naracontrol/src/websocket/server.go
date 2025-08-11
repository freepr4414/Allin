package websocket

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/soinfree/naracontrol/src/config"
	"github.com/soinfree/naracontrol/src/models"
)

// 웹소켓 업그레이더 설정
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// 모든 오리진 허용 (개발용)
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// WebSocketClient 구조체는 WebSocket 클라이언트를 나타냅니다
type WebSocketClient struct {
	ID           string             // 고유 클라이언트 식별자 (UUID)
	Conn         *websocket.Conn    // WebSocket 네트워크 연결 객체
	Send         chan []byte        // 메시지 전송 채널 (WebSocket 전용)
	Active       bool               // 클라이언트 활성 상태 (연결/해제)
	LastPing     time.Time          // 마지막 활동 시간 (heartbeat 추적용)
	DeviceType   string             // 디바이스 타입 ("naradesk", "naradevice")
	CompanyCode  string             // 회사 코드 (메시지 라우팅 기준)
	UserCode     string             // 사용자 코드 (회사 내 사용자 구분)
	DeviceID     string             // 디바이스 고유 식별자
	DeviceTagged string             // 디바이스 태그 정보
	mu           sync.Mutex         // 동시성 제어용 뮤텍스
	closed       bool               // 종료 상태 추가 (WebSocket 전용)
	closeMu      sync.Mutex         // 종료 상태 보호용 뮤텍스 (WebSocket 전용)
	ctx          context.Context    // 컨텍스트 추가 (WebSocket 전용)
	cancel       context.CancelFunc // 캔슬 함수 추가 (WebSocket 전용)
}

// WebSocketServer 구조체는 WebSocket 서버를 나타냅니다
type WebSocketServer struct {
	clients      map[string]*WebSocketClient
	clientsMu    sync.RWMutex
	onMessage    func(clientID string, data []byte)
	onConnect    func(client *models.Client)
	onDisconnect func(clientID string)
}

// NewWebSocketServer는 새 WebSocket 서버를 생성합니다
func NewWebSocketServer() *WebSocketServer {
	return &WebSocketServer{
		clients: make(map[string]*WebSocketClient),
	}
}

// HandleWebSocket은 WebSocket 연결 요청을 처리합니다
func (s *WebSocketServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	// WebSocket으로 업그레이드
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket 업그레이드 실패: %v", err)
		return
	}

	// 새 클라이언트 생성
	clientID := uuid.New().String()
	ctx, cancel := context.WithCancel(context.Background())
	client := &WebSocketClient{
		ID:       clientID,
		Conn:     conn,
		Send:     make(chan []byte, 256),
		Active:   true,
		LastPing: time.Now(),
		ctx:      ctx,
		cancel:   cancel,
	}

	// 클라이언트 맵에 추가
	s.clientsMu.Lock()
	s.clients[clientID] = client
	s.clientsMu.Unlock()

	log.Printf("WebSocket 클라이언트 연결: %s (%s)", clientID, conn.RemoteAddr().String())

	// 읽기/쓰기 고루틴 시작
	go s.readPump(client)
	go s.writePump(client)
}

// readPump는 클라이언트로부터 메시지를 읽습니다
func (s *WebSocketServer) readPump(client *WebSocketClient) {
	defer func() {
		// 클라이언트 안전 종료
		client.Close()

		// 클라이언트 맵에서 제거
		s.clientsMu.Lock()
		delete(s.clients, client.ID)
		s.clientsMu.Unlock()

		log.Printf("WebSocket 클라이언트 연결 해제: %s", client.ID)

		if s.onDisconnect != nil {
			s.onDisconnect(client.ID)
		}
	}()

	// 연결 유지를 위한 설정
	client.Conn.SetReadLimit(4096) // 메시지 크기 제한
	client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	client.Conn.SetPongHandler(func(string) error {
		client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	// 바이너리 환영 메시지 보내기 (안전한 전송)
	welcomeData := []byte{}
	welcomeMsg := &models.BinaryMessage{
		Type: models.BinaryMessageTypeWelcome,
		Data: welcomeData,
	}
	welcomeMessage, err := models.EncodeBinaryMessage(welcomeMsg, "naradesk")
	if err == nil {
		select {
		case client.Send <- welcomeMessage:
		case <-client.ctx.Done():
			return
		default:
			// 채널이 막혀있으면 로그만 남기고 계속
			log.Printf("클라이언트 %s 바이너리 환영 메시지 전송 실패", client.ID)
		}
	}

	for {
		select {
		case <-client.ctx.Done():
			// 컨텍스트가 취소되면 종료
			log.Printf("WebSocket 클라이언트 %s 컨텍스트 취소됨", client.ID)
			return
		default:
			// 메시지 읽기 시도
			_, message, err := client.Conn.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
					log.Printf("WebSocket 읽기 오류: %v", err)
				}
				return
			}
			// 바이너리 메시지 처리 (WebSocket은 바이너리 전용)
			if binaryMsg, clientType, err := models.DecodeBinaryMessage(message); err == nil {
				log.Printf("WebSocket 바이너리 메시지 수신: 타입=%d, 클라이언트=%s, 인증타입=%s", binaryMsg.Type, client.ID, clientType)

				switch binaryMsg.Type {
				case models.BinaryMessageTypeConnect:
					// 바이너리 연결 메시지 처리
					companyCode, userCode, source, err := models.DecodeConnectData(binaryMsg.Data)
					if err != nil {
						log.Printf("WebSocket 바이너리 연결 메시지 디코딩 실패: %v", err)
						continue
					}

					client.mu.Lock()
					client.CompanyCode = companyCode
					client.UserCode = userCode
					client.DeviceType = source
					client.LastPing = time.Now()
					client.mu.Unlock()

					log.Printf("WebSocket 바이너리 클라이언트 정보 업데이트: %s, company=%s, user=%s, type=%s",
						client.ID, companyCode, userCode, source)

					// 서버에 연결 콜백 호출
					if s.onConnect != nil {
						modelClient := &models.Client{
							ID:            client.ID,
							CompanyCode:   companyCode,
							UserCode:      userCode,
							Type:          config.ClientTypeNaradesk, // WebSocket은 항상 naradesk
							UseBinaryMode: true,
						}
						s.onConnect(modelClient)
					}

					// 바이너리 환영 메시지 전송
					welcomeData := []byte{}
					welcomeMsg := &models.BinaryMessage{
						Type: models.BinaryMessageTypeWelcome,
						Data: welcomeData,
					}
					welcomeMessage, err := models.EncodeBinaryMessage(welcomeMsg, "naradesk")
					if err != nil {
						log.Printf("WebSocket 바이너리 환영 메시지 인코딩 실패: %v", err)
						continue
					}

					select {
					case client.Send <- welcomeMessage:
						log.Printf("WebSocket 바이너리 환영 메시지 전송: 클라이언트=%s", client.ID)
					default:
						log.Printf("WebSocket 클라이언트 %s 전송 채널이 가득참", client.ID)
					}
					continue

				case models.BinaryMessageTypePing:
					// 바이너리 ping에 pong으로 응답
					log.Printf("WebSocket 클라이언트 %s에서 핑(Ping) 수신 - 퐁(Pong) 응답 전송", client.ID)

					// LastPing 업데이트
					client.mu.Lock()
					client.LastPing = time.Now()
					client.mu.Unlock()

					pongData := []byte{}
					pongMsg := &models.BinaryMessage{
						Type: models.BinaryMessageTypePong,
						Data: pongData,
					}
					pongMessage, err := models.EncodeBinaryMessage(pongMsg, "naradesk")
					if err != nil {
						log.Printf("WebSocket 바이너리 pong 메시지 인코딩 실패: %v", err)
						continue
					}

					select {
					case client.Send <- pongMessage:
						log.Printf("WebSocket 바이너리 pong 응답 전송: 클라이언트=%s", client.ID)
					default:
						log.Printf("WebSocket 클라이언트 %s 전송 채널이 가득참", client.ID)
					}
					continue

				default:
					// 기타 바이너리 메시지는 메시지 콜백으로 처리
					log.Printf("WebSocket 클라이언트 %s에서 바이너리 메시지 수신: 타입=%d, 크기=%d bytes", client.ID, binaryMsg.Type, len(message))
					if s.onMessage != nil {
						s.onMessage(client.ID, message)
					}
					continue
				}
			} else {
				log.Printf("WebSocket 클라이언트 %s에서 잘못된 바이너리 메시지 수신: 크기=%d bytes (최소 5 bytes 필요)", client.ID, len(message))
				continue
			}
		}
	}
}

// writePump는 클라이언트에게 메시지를 전송합니다
func (s *WebSocketServer) writePump(client *WebSocketClient) {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		// 클라이언트가 이미 종료되지 않았다면 종료
		if !client.IsClosed() {
			client.Close()
		}
	}()

	for {
		select {
		case <-client.ctx.Done():
			// 컨텍스트가 취소되면 종료
			log.Printf("WebSocket 클라이언트 %s 쓰기 컨텍스트 취소됨", client.ID)
			return

		case message, ok := <-client.Send:
			client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				// 채널이 닫힘
				log.Printf("클라이언트 %s: 전송 채널이 닫혔습니다. 연결을 종료합니다", client.ID)
				client.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// 바이너리 메시지로 전송 (WebSocket은 바이너리 전용)
			w, err := client.Conn.NextWriter(websocket.BinaryMessage)
			if err != nil {
				log.Printf("클라이언트 %s: writer 가져오기 오류: %v", client.ID, err)
				return
			}

			n, err := w.Write(message)
			if err != nil {
				log.Printf("클라이언트 %s: 메시지 쓰기 오류: %v", client.ID, err)
				return
			}
			log.Printf("클라이언트 %s: %d 바이트 바이너리 메시지 전송", client.ID, n)

			// 큐에 있는 다른 메시지도 함께 전송
			n = len(client.Send)
			for i := 0; i < n; i++ {
				additionalMsg := <-client.Send
				w.Write(additionalMsg)
				log.Printf("클라이언트 %s: 추가 대기 중인 메시지 전송", client.ID)
			}

			if err := w.Close(); err != nil {
				log.Printf("클라이언트 %s: writer 닫기 오류: %v", client.ID, err)
				return
			}
			log.Printf("클라이언트 %s: 메시지 전송 성공", client.ID)
		case <-ticker.C:
			// 핑 메시지 전송
			client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := client.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("클라이언트 %s: ping 전송 오류: %v", client.ID, err)
				return
			}
		}
	}
}

// SendToClient는 특정 클라이언트에게 메시지를 전송합니다
func (s *WebSocketServer) SendToClient(clientID string, data []byte) error {
	s.clientsMu.RLock()
	client, exists := s.clients[clientID]
	s.clientsMu.RUnlock()

	if !exists {
		log.Printf("메시지 전달용 WebSocket 클라이언트를 찾을 수 없음: %s", clientID)
		// 디버그: 모든 클라이언트 목록 출력
		s.PrintAllClients()
		return fmt.Errorf("client not found: %s", clientID)
	}

	log.Printf("클라이언트 %s에게 WebSocket 바이너리 메시지 전송 (타입: %s, 회사: %s)",
		clientID, client.DeviceType, client.CompanyCode)
	log.Printf("바이너리 메시지 크기: %d bytes", len(data))

	select {
	case client.Send <- data:
		log.Printf("클라이언트 %s 메시지 대기열에 추가", clientID)
		return nil
	default:
		// 채널이 가득 찼거나 닫혔으면 연결 종료
		log.Printf("클라이언트 %s 메시지 대기열 추가 실패 (채널이 가득 참 또는 닫힘)", clientID)
		s.clientsMu.Lock()
		delete(s.clients, clientID)
		s.clientsMu.Unlock()

		close(client.Send)
		client.Conn.Close()
		return fmt.Errorf("client channel full or closed: %s", clientID)
	}
}

// BroadcastToAll은 모든 클라이언트에게 메시지를 전송합니다
func (s *WebSocketServer) BroadcastToAll(data []byte) {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	for _, client := range s.clients {
		select {
		case client.Send <- data:
		default:
			// 가득 찬 채널은 무시
		}
	}
}

// BroadcastToType은 특정 타입의 모든 클라이언트에게 메시지를 전송합니다
func (s *WebSocketServer) BroadcastToType(deviceType string, data []byte) {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	for _, client := range s.clients {
		if client.DeviceType == deviceType {
			select {
			case client.Send <- data:
			default:
				// 가득 찬 채널은 무시
			}
		}
	}
}

// SetMessageCallback은 메시지 처리 콜백을 설정합니다
func (s *WebSocketServer) SetMessageCallback(callback func(clientID string, data []byte)) {
	s.onMessage = callback
}

// SetConnectCallback은 연결 콜백을 설정합니다
func (s *WebSocketServer) SetConnectCallback(callback func(client *models.Client)) {
	s.onConnect = callback
}

// SetDisconnectCallback은 연결 해제 콜백을 설정합니다
func (s *WebSocketServer) SetDisconnectCallback(callback func(clientID string)) {
	s.onDisconnect = callback
}

// UpdateClientInfo는 클라이언트 정보를 업데이트합니다
func (s *WebSocketServer) UpdateClientInfo(clientID string, companyCode string, userCode string, deviceType string) {
	s.clientsMu.RLock()
	client, exists := s.clients[clientID]
	s.clientsMu.RUnlock()

	if !exists {
		return
	}

	client.mu.Lock()
	defer client.mu.Unlock()

	client.CompanyCode = companyCode
	client.UserCode = userCode
	client.DeviceType = deviceType
}

// GetClient는 클라이언트 ID로 WebSocketClient를 검색합니다
func (s *WebSocketServer) GetClient(clientID string) *WebSocketClient {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	return s.clients[clientID]
}

// 디버그용: 모든 웹소켓 클라이언트 정보 출력
func (s *WebSocketServer) PrintAllClients() {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	log.Printf("=== 웹소켓 서버 클라이언트 목록 ===")
	log.Printf("총 %d개의 웹소켓 클라이언트가 연결되어 있습니다.", len(s.clients))

	for id, client := range s.clients {
		log.Printf("클라이언트 ID: %s, 타입: %s, 회사코드: %s",
			id, client.DeviceType, client.CompanyCode)
	}
	log.Printf("=== 웹소켓 클라이언트 목록 끝 ===")
}

// 특정 타입의 클라이언트 목록 반환
func (s *WebSocketServer) GetClientsByType(deviceType string) []string {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	var clientIDs []string
	for id, client := range s.clients {
		if client.DeviceType == deviceType {
			clientIDs = append(clientIDs, id)
		}
	}

	return clientIDs
}

// Close는 WebSocket 클라이언트를 안전하게 종료합니다
func (c *WebSocketClient) Close() {
	c.closeMu.Lock()
	defer c.closeMu.Unlock()

	if !c.closed {
		c.mu.Lock()
		c.Active = false
		c.mu.Unlock()

		c.closed = true
		c.cancel()     // 컨텍스트 취소
		close(c.Send)  // 채널 닫기
		c.Conn.Close() // 연결 닫기
	}
}

// Stop은 WebSocket 서버를 정상적으로 종료합니다
func (s *WebSocketServer) Stop() {
	log.Println("WebSocket 서버를 종료하는 중...")

	// 모든 클라이언트 연결 해제
	s.clientsMu.Lock()
	for _, client := range s.clients {
		client.Close()
	}
	s.clients = make(map[string]*WebSocketClient)
	s.clientsMu.Unlock()

	log.Println("WebSocket 서버가 종료되었습니다")
}

// IsClosed는 클라이언트가 종료되었는지 확인합니다
func (c *WebSocketClient) IsClosed() bool {
	c.closeMu.Lock()
	defer c.closeMu.Unlock()
	return c.closed
}
