package tcp

import (
	"fmt"
	"io"
	"log"
	"net"
	"sync"
	"time"

	"github.com/google/uuid"
)

// TCPClient는 연결된 TCP 클라이언트를 나타냅니다
type TCPClient struct {
	ID           string     // 고유 클라이언트 식별자 (UUID)
	Conn         net.Conn   // TCP 네트워크 연결 객체
	Active       bool       // 클라이언트 활성 상태 (연결/해제)
	LastPing     time.Time  // 마지막 활동 시간 (heartbeat 추적용)
	DeviceID     string     // 클라이언트 식별 정보
	DeviceType   string     // 디바이스 타입 ("naradesk", "naradevice")
	CompanyCode  string     // 회사 코드 (메시지 라우팅 기준)
	UserCode     string     // 사용자 코드 (회사 내 사용자 구분)
	DeviceTagged string     // 디바이스 특수 태그 (예: QF1003)
	mu           sync.Mutex // 동시성 제어용 뮤텍스
}

// TCPServer는 TCP 연결과 메시지를 처리합니다
type TCPServer struct {
	address      string                             // 서버 바인딩 주소 (예: ":8091")
	listener     net.Listener                       // TCP 리스너 (들어오는 연결 수락)
	clients      map[string]*TCPClient              // 연결된 클라이언트 맵 (키: 클라이언트 ID)
	clientsMu    sync.RWMutex                       // 클라이언트 맵 보호 뮤텍스 (읽기/쓰기 구분)
	done         chan struct{}                      // 서버 종료 신호 채널
	running      bool                               // 서버 실행 상태
	onMessage    func(clientID string, data []byte) // 메시지 수신 콜백 (메시지 라우팅으로 연결)
	onConnect    func(client *TCPClient)            // 클라이언트 연결 콜백 (서버 등록 처리)
	onDisconnect func(clientID string)              // 클라이언트 해제 콜백 (서버 등록 해제 처리)
}

// NewTCPServer는 새로운 TCP 서버를 생성합니다
func NewTCPServer(address string) *TCPServer {
	return &TCPServer{
		address: address,
		clients: make(map[string]*TCPClient),
		done:    make(chan struct{}),
	}
}

// Start는 TCP 서버를 초기화하고 시작합니다
func (s *TCPServer) Start() error {
	if s.running {
		return fmt.Errorf("TCP server is already running")
	}

	var err error
	s.listener, err = net.Listen("tcp", s.address)
	if err != nil {
		return fmt.Errorf("failed to start TCP server: %w", err)
	}

	s.running = true
	log.Printf("TCP 서버가 %s에서 시작되었습니다", s.address)

	// 고루틴에서 연결 수락 시작
	go s.acceptConnections()

	// 연결 모니터링 시작
	go s.monitorConnections()

	return nil
}

// Stop은 TCP 서버를 정상적으로 종료합니다
func (s *TCPServer) Stop() {
	if !s.running {
		return
	}

	log.Println("Stopping TCP Server...")
	s.running = false
	close(s.done)

	if s.listener != nil {
		s.listener.Close()
	}

	// 모든 클라이언트 연결 종료
	s.clientsMu.Lock()
	for _, client := range s.clients {
		client.Conn.Close()
	}
	// 연결은 끊어졌지만 객체는 남음
	// GC가 회수하기 전까지 메모리 점유
	// 아래와 같이 초기화 후: 깨끗한 상태가됨
	s.clients = make(map[string]*TCPClient) // 빈 맵
	s.clientsMu.Unlock()

	log.Println("TCP Server stopped")
}

// acceptConnections은 들어오는 TCP 연결을 수락합니다
func (s *TCPServer) acceptConnections() {
	for s.running {
		conn, err := s.listener.Accept()
		if err != nil {
			if s.running {
				log.Printf("연결 수락 실패: %v", err)
			}
			continue
		}

		clientID := uuid.New().String()
		log.Printf("새로운 TCP 연결 수락: %s (%s)", clientID, conn.RemoteAddr())

		client := &TCPClient{
			ID:         clientID,
			Conn:       conn,
			Active:     true,
			LastPing:   time.Now(),
			DeviceType: "naradevice", // TCP는 항상 naradevice
		}

		s.clientsMu.Lock()
		s.clients[clientID] = client
		s.clientsMu.Unlock()

		// 연결 콜백 호출
		if s.onConnect != nil {
			s.onConnect(client)
		}

		// 별도 고루틴에서 이 클라이언트의 연결을 처리
		go s.handleConnection(client)
	}
}

// handleConnection은 연결된 클라이언트에서 데이터를 처리합니다
func (s *TCPServer) handleConnection(client *TCPClient) {
	defer func() {
		log.Printf("TCP 클라이언트 연결 해제: %s", client.ID)
		client.Active = false
		client.Conn.Close()

		s.clientsMu.Lock()
		delete(s.clients, client.ID)
		s.clientsMu.Unlock()

		// 연결 해제 콜백 호출
		if s.onDisconnect != nil {
			s.onDisconnect(client.ID)
		}
	}()

	buffer := make([]byte, 4096)
	for client.Active && s.running {
		client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second)) // 읽기 제한 시간을 60초로 갱신
		n, err := client.Conn.Read(buffer)
		if err != nil {
			if err != io.EOF {
				log.Printf("클라이언트 %s에서 읽기 오류: %v", client.ID, err)
			}
			break
		}

		if n > 0 {
			client.LastPing = time.Now()
			data := make([]byte, n)
			copy(data, buffer[:n])

			// 바이너리 메시지 처리 (TCP는 바이너리 전용)
			if len(data) >= 5 {
				messageType := data[0]
				if messageType == 3 { // ping 메시지
					log.Printf("TCP 클라이언트 %s에서 핑(Ping) 수신 - 퐁(Pong) 응답 전송", client.ID)
					// ping에 대한 pong 응답 전송 (타입 4 = pong)
					pongMessage := []byte{4, 0, 0, 0, 0} // 타입 4, 데이터 길이 0
					client.Conn.Write(pongMessage)
				} else {
					log.Printf("TCP 클라이언트 %s에서 바이너리 메시지 수신: 타입=%d, 크기=%d bytes", client.ID, messageType, n)
				}
			} else {
				log.Printf("TCP 클라이언트 %s에서 잘못된 바이너리 메시지 수신: 크기=%d bytes (최소 5 bytes 필요)", client.ID, n)
			}

			// 메시지 콜백 호출
			if s.onMessage != nil {
				go func(c *TCPClient, data []byte) {
					defer func() {
						if r := recover(); r != nil {
							log.Printf("메시지 콜백에서 패닉 발생: %v", r)
						}
					}()
					s.onMessage(c.ID, data)
				}(client, data)
			}
		}
	}
}

// monitorConnections은 주기적으로 클라이언트 연결을 확인합니다
func (s *TCPServer) monitorConnections() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-s.done:
			return
		case <-ticker.C:
			s.checkInactiveClients()
		}
	}
}

// checkInactiveClients는 비활성 클라이언트를 확인하고 제거합니다
func (s *TCPServer) checkInactiveClients() {
	now := time.Now()
	inactiveThreshold := 60 * time.Second

	s.clientsMu.RLock()
	var inactiveClients []*TCPClient
	for _, client := range s.clients {
		if now.Sub(client.LastPing) > inactiveThreshold {
			inactiveClients = append(inactiveClients, client)
		}
	}
	s.clientsMu.RUnlock()

	for _, client := range inactiveClients {
		log.Printf("비활성 TCP 클라이언트 제거: %s", client.ID)
		client.Active = false
		client.Conn.Close()

		// 클라이언트 맵에서 실제로 제거
		s.clientsMu.Lock()
		delete(s.clients, client.ID)
		s.clientsMu.Unlock()

		// 서버 연결 해제 콜백 호출
		if s.onDisconnect != nil {
			s.onDisconnect(client.ID)
		}
	}
}

// SendToClient는 특정 클라이언트에게 데이터를 전송합니다
func (s *TCPServer) SendToClient(clientID string, data []byte) error {
	s.clientsMu.RLock()
	client, exists := s.clients[clientID]
	s.clientsMu.RUnlock()

	if !exists {
		return fmt.Errorf("client %s not found", clientID)
	}

	if !client.Active {
		return fmt.Errorf("client %s is not active", clientID)
	}

	client.mu.Lock()
	defer client.mu.Unlock()

	_, err := client.Conn.Write(data)
	if err != nil {
		log.Printf("클라이언트 %s로 데이터 전송 실패: %v", clientID, err)
		client.Active = false
		return err
	}

	return nil
}

// SetMessageCallback은 메시지 처리를 위한 콜백을 설정합니다
func (s *TCPServer) SetMessageCallback(callback func(clientID string, data []byte)) {
	s.onMessage = callback
}

// SetConnectCallback은 클라이언트 연결에 대한 콜백을 설정합니다
func (s *TCPServer) SetConnectCallback(callback func(client *TCPClient)) {
	s.onConnect = callback
}

// SetDisconnectCallback은 클라이언트 연결 해제에 대한 콜백을 설정합니다
func (s *TCPServer) SetDisconnectCallback(callback func(clientID string)) {
	s.onDisconnect = callback
}

// SetCompanyCode 메서드는 클라이언트의 회사 코드를 설정합니다
func (c *TCPClient) SetCompanyCode(companyCode string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.CompanyCode = companyCode
}

// SetDeviceType 메서드는 클라이언트의 디바이스 타입을 설정합니다
func (c *TCPClient) SetDeviceType(deviceType string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.DeviceType = deviceType
}

// SetDeviceTagged 메서드는 클라이언트의 디바이스 태그를 설정합니다
func (c *TCPClient) SetDeviceTagged(deviceTagged string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.DeviceTagged = deviceTagged
}

// GetClient 메서드는 클라이언트 ID로 TCPClient를 검색합니다
func (s *TCPServer) GetClient(clientID string) *TCPClient {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()
	return s.clients[clientID]
}
