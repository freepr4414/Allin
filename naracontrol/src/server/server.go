package server

import (
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/soinfree/naracontrol/src/config"
	"github.com/soinfree/naracontrol/src/models"
)

// RouteMessageFunc 타입은 메시지 라우팅 함수의 시그니처를 정의합니다
type RouteMessageFunc func(sender *models.Client, message []byte)

// MessageHandlerFunc 타입은 메시지 처리 함수의 시그니처를 정의합니다
type MessageHandlerFunc func(sender *models.Client, message []byte) bool

// ClientConnectFunc 타입은 클라이언트 연결 함수의 시그니처를 정의합니다
type ClientConnectFunc func(client *models.Client)

// ClientDisconnectFunc 타입은 클라이언트 연결 해제 함수의 시그니처를 정의합니다
type ClientDisconnectFunc func(clientID string)

// 서버 구조체
type Server struct {
	Clients    map[*models.Client]bool
	Register   chan *models.Client
	Unregister chan *models.Client
	Mutex      sync.Mutex

	// 회사 코드별로 클라이언트를 관리하는 맵
	ClientsByCompany map[string]map[*models.Client]bool
	CompanyMutex     sync.RWMutex

	// 마지막 활동 시간을 추적하기 위한 맵
	LastActivity  map[*models.Client]time.Time
	ActivityMutex sync.RWMutex

	// 세분화된 뮤텍스 배열 (샤딩)
	MutexShards []*sync.RWMutex
	ShardCount  int

	// 메시지 라우팅 함수
	messageRouter RouteMessageFunc
	// 메시지 핸들러 함수 목록
	messageHandlers []MessageHandlerFunc
	handlersMutex   sync.RWMutex
	// 클라이언트 연결/연결 해제 콜백
	onClientConnected    ClientConnectFunc
	onClientDisconnected ClientDisconnectFunc
	callbackMutex        sync.RWMutex

	// TCP 메시지 전송 함수
	SendTCPMessageFunc func(clientID string, message []byte) error

	// WebSocket 메시지 전송 함수
	SendWSMessageFunc func(clientID string, message []byte) error
}

// 메시지 라우팅 함수 설정
func (s *Server) SetMessageRouter(router RouteMessageFunc) {
	s.messageRouter = router
}

// MessageRouter는 메시지 라우팅 함수를 반환합니다
func (s *Server) MessageRouter() RouteMessageFunc {
	if s.messageRouter == nil {
		log.Printf("경고: messageRouter가 nil입니다. 기본 라우터로 대체합니다.")
		// 기본 라우터 함수 - 에러 로그만 출력
		return func(sender *models.Client, data []byte) {
			log.Printf("경고: 메시지 라우터가 설정되지 않았습니다. 메시지가 라우팅되지 않습니다. 발신자: %s", sender.ID)
		}
	}
	return s.messageRouter
}

// message 패키지의 인터페이스 구현을 위한 메서드들
func (s *Server) CompanyMutexRLock() {
	s.CompanyMutex.RLock()
}

func (s *Server) CompanyMutexRUnlock() {
	s.CompanyMutex.RUnlock()
}

func (s *Server) GetClientsByCompany() map[string]map[*models.Client]bool {
	return s.ClientsByCompany
}

func (s *Server) GetUnregisterChannel() chan<- *models.Client {
	return s.Unregister
}

// GetRegisterChannel은 클라이언트 등록 채널을 반환합니다
func (s *Server) GetRegisterChannel() chan<- *models.Client {
	return s.Register
}

// TCP 서버로 메시지를 전송하는 메서드
// 메시지 라우터에서 호출되는 인터페이스 메서드
func (s *Server) SendTCPMessage(clientID string, message []byte) error {
	if s.SendTCPMessageFunc != nil {
		log.Printf("[TCP] 클라이언트 %s로 메시지 전송 시도 (크기: %d 바이트)", clientID, len(message))
		err := s.SendTCPMessageFunc(clientID, message)
		if err != nil {
			log.Printf("[TCP] 메시지 전송 실패: %s, 오류: %v", clientID, err)
		} else {
			log.Printf("[TCP] 메시지 전송 성공: %s", clientID)
		}
		return err
	}
	log.Printf("[TCP] TCP 메시지 전송 함수가 설정되지 않았습니다. 클라이언트: %s", clientID)
	return fmt.Errorf("TCP message sending function not set")
}

// WebSocket 서버로 메시지를 전송하는 메서드
// 메시지 라우터에서 호출되는 인터페이스 메서드
func (s *Server) SendWSMessage(clientID string, message []byte) error {
	if s.SendWSMessageFunc != nil {
		log.Printf("[WS] 클라이언트 %s로 메시지 전송 시도 (크기: %d 바이트)", clientID, len(message))
		err := s.SendWSMessageFunc(clientID, message)
		if err != nil {
			log.Printf("[WS] 메시지 전송 실패: %s, 오류: %v", clientID, err)
		} else {
			log.Printf("[WS] 메시지 전송 성공: %s", clientID)
		}
		return err
	}
	log.Printf("[WS] WebSocket 메시지 전송 함수가 설정되지 않았습니다. 클라이언트: %s", clientID)
	return fmt.Errorf("WebSocket message sending function not set")
}

// 새 서버 생성
func NewServer() *Server {
	// 샤드로 뮤텍스 배열 초기화
	mutexShards := make([]*sync.RWMutex, config.DefaultShardCount)
	for i := range config.DefaultShardCount {
		mutexShards[i] = &sync.RWMutex{}
	}

	server := &Server{
		Clients:          make(map[*models.Client]bool),
		Register:         make(chan *models.Client),
		Unregister:       make(chan *models.Client),
		ClientsByCompany: make(map[string]map[*models.Client]bool),
		LastActivity:     make(map[*models.Client]time.Time),
		MutexShards:      mutexShards,
		ShardCount:       config.DefaultShardCount,
	}

	return server
}

// 서버 실행
func (s *Server) Run() {
	// 비활성 연결 정리를 위한 티커 설정
	cleanupTicker := time.NewTicker(config.CleanupInterval)
	defer cleanupTicker.Stop()

	// 상태 로깅을 위한 티커
	statsTicker := time.NewTicker(config.StatsInterval)
	defer statsTicker.Stop()

	for {
		select {
		case client := <-s.Register:
			s.handleClientRegister(client)

		case client := <-s.Unregister:
			s.handleClientUnregister(client)

		case <-cleanupTicker.C:
			// 비활성 연결 정리
			s.cleanupInactiveConnections()

		case <-statsTicker.C:
			// 현재 연결 상태 로깅
			counts := s.getClientsCount()
			log.Printf("현재 연결 - 전체: %d, Naradesk: %d, Naradevice: %d",
				counts["total"], counts["naradesk"], counts["naradevice"])
		}
	}
}

// 클라이언트 등록 처리
func (s *Server) handleClientRegister(client *models.Client) {
	log.Printf("클라이언트 등록: %s (%s) - %s", client.CompanyCode, client.UserCode, client.Type)

	// 클라이언트 추가
	s.Mutex.Lock()
	s.Clients[client] = true
	s.Mutex.Unlock()

	// 회사별 인덱스에 추가
	companyClients := s.getCompanyClients(client.CompanyCode)
	s.CompanyMutex.Lock()
	companyClients[client] = true
	s.CompanyMutex.Unlock()

	// 활동 시간 초기화
	s.UpdateClientActivity(client)

	// 클라이언트 연결 콜백 호출
	s.handleClientConnected(client)
}

// 클라이언트 등록 해제 처리
func (s *Server) handleClientUnregister(client *models.Client) {
	log.Printf("클라이언트 등록 해제: %s (%s) - %s", client.CompanyCode, client.UserCode, client.Type)

	// 클라이언트 ID 기반 락 획득
	s.LockClientWrite(client.ID)

	// 클라이언트 맵에서 제거
	s.Mutex.Lock()
	delete(s.Clients, client)
	s.Mutex.Unlock()

	// 회사별 인덱스에서 제거
	s.CompanyMutex.Lock()
	if companyClients, exists := s.ClientsByCompany[client.CompanyCode]; exists {
		delete(companyClients, client)
		// 맵이 비었으면 삭제
		if len(companyClients) == 0 {
			delete(s.ClientsByCompany, client.CompanyCode)
		}
	}
	s.CompanyMutex.Unlock()

	// 활동 시간 맵에서 제거
	s.ActivityMutex.Lock()
	delete(s.LastActivity, client)
	s.ActivityMutex.Unlock()

	s.UnlockClientWrite(client.ID)

	// 클라이언트 연결 해제 콜백 호출
	s.handleClientDisconnected(client)
}

// 서버의 클라이언트 관련 정보를 가져옵니다
func (s *Server) getClientsCount() map[string]int {
	s.Mutex.Lock()
	defer s.Mutex.Unlock()

	naradeskCount := 0
	naradeviceCount := 0

	for client := range s.Clients {
		switch client.Type {
		case config.ClientTypeNaradesk:
			naradeskCount++
		case config.ClientTypeNaradevice:
			naradeviceCount++
		}
	}

	return map[string]int{
		"total":      len(s.Clients),
		"naradesk":   naradeskCount,
		"naradevice": naradeviceCount,
	}
}

// 클라이언트 ID를 기반으로 샤드 인덱스를 계산
func (s *Server) getShardIndex(clientID string) int {
	// 간단한 해시 함수: 문자열의 각 바이트 값을 더한 후 샤드 수로 나눔
	var sum int
	for i := 0; i < len(clientID); i++ {
		sum += int(clientID[i])
	}
	return sum % s.ShardCount
}

// 클라이언트에 대한 읽기 락 획득
func (s *Server) LockClientRead(clientID string) {
	shardIndex := s.getShardIndex(clientID)
	s.MutexShards[shardIndex].RLock()
}

// 클라이언트에 대한 읽기 락 해제
func (s *Server) UnlockClientRead(clientID string) {
	shardIndex := s.getShardIndex(clientID)
	s.MutexShards[shardIndex].RUnlock()
}

// 클라이언트에 대한 쓰기 락 획득
func (s *Server) LockClientWrite(clientID string) {
	shardIndex := s.getShardIndex(clientID)
	s.MutexShards[shardIndex].Lock()
}

// 클라이언트에 대한 쓰기 락 해제
func (s *Server) UnlockClientWrite(clientID string) {
	shardIndex := s.getShardIndex(clientID)
	s.MutexShards[shardIndex].Unlock()
}

// 클라이언트 활동 시간 업데이트
func (s *Server) UpdateClientActivity(client *models.Client) {
	s.ActivityMutex.Lock()
	defer s.ActivityMutex.Unlock()
	s.LastActivity[client] = time.Now()
}

// 특정 회사 코드에 해당하는 클라이언트 맵을 가져오거나 생성
func (s *Server) getCompanyClients(companyCode string) map[*models.Client]bool {
	s.CompanyMutex.RLock()
	clients, exists := s.ClientsByCompany[companyCode]
	s.CompanyMutex.RUnlock()

	if !exists {
		s.CompanyMutex.Lock()
		// 다시 확인 (다른 고루틴에서 이미 생성했을 수 있음)
		clients, exists = s.ClientsByCompany[companyCode]
		if !exists {
			clients = make(map[*models.Client]bool)
			s.ClientsByCompany[companyCode] = clients
		}
		s.CompanyMutex.Unlock()
	}

	return clients
}

// 비활성 연결 정리
func (s *Server) cleanupInactiveConnections() {
	now := time.Now()
	var inactiveClients []*models.Client
	// 비활성 클라이언트 식별
	s.ActivityMutex.RLock()
	for client, lastActive := range s.LastActivity {
		if now.Sub(lastActive) > config.InactiveTimeout {
			inactiveClients = append(inactiveClients, client)
		}
	}
	s.ActivityMutex.RUnlock()
	// 비활성 클라이언트 정리
	for _, client := range inactiveClients {
		log.Printf("비활성 클라이언트 정리: %s (%s) - %s", client.CompanyCode, client.UserCode, client.Type)
		// TCP 클라이언트는 별도로 처리해야 함
		s.Unregister <- client
	}

	if len(inactiveClients) > 0 {
		log.Printf("%d개의 비활성 연결을 정리했습니다", len(inactiveClients))
	}
}

// 메시지 라우팅 함수
func (s *Server) RouteMessage(sender *models.Client, message []byte) {
	// 추가된 메시지 핸들러가 있는지 확인
	s.handlersMutex.RLock()
	handlers := s.messageHandlers
	s.handlersMutex.RUnlock()

	// 핸들러를 통해 메시지 처리 시도
	for _, handler := range handlers {
		if handler(sender, message) {
			// 핸들러가 true를 반환하면 메시지가 처리된 것으로 간주
			return
		}
	}

	// 라우터가 설정되어 있으면 해당 함수 호출
	if s.messageRouter != nil {
		s.messageRouter(sender, message)
	} else {
		log.Println("Warning: No message router configured")
	}
}

// 클라이언트 연결 콜백 설정
func (s *Server) SetOnClientConnected(callback ClientConnectFunc) {
	s.callbackMutex.Lock()
	defer s.callbackMutex.Unlock()
	s.onClientConnected = callback
}

// 클라이언트 연결 해제 콜백 설정
func (s *Server) SetOnClientDisconnected(callback ClientDisconnectFunc) {
	s.callbackMutex.Lock()
	defer s.callbackMutex.Unlock()
	s.onClientDisconnected = callback
}

// 메시지 핸들러 추가
func (s *Server) AddMessageHandler(handler MessageHandlerFunc) {
	s.handlersMutex.Lock()
	defer s.handlersMutex.Unlock()
	s.messageHandlers = append(s.messageHandlers, handler)
}

// 클라이언트 연결 처리 (콜백 호출)
func (s *Server) handleClientConnected(client *models.Client) {
	s.callbackMutex.RLock()
	callback := s.onClientConnected
	s.callbackMutex.RUnlock()

	if callback != nil {
		callback(client)
	}
}

// 클라이언트 연결 해제 처리 (콜백 호출)
func (s *Server) handleClientDisconnected(client *models.Client) {
	s.callbackMutex.RLock()
	callback := s.onClientDisconnected
	s.callbackMutex.RUnlock()

	if callback != nil {
		callback(client.ID)
	}
}
