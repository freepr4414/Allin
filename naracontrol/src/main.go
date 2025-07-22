package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/soinfree/naracontrol/src/api"
	"github.com/soinfree/naracontrol/src/server"
)

func main() {
	// 서버 인스턴스 생성
	serverInstance := server.NewServer()

	// TCP 서버 시작
	tcpServer := server.SetupTCPServer(serverInstance)
	if tcpServer == nil {
		log.Fatal("TCP 서버 초기화 실패")
	}
	defer tcpServer.Stop()

	// TCP 서버가 생성된 후 메시지 라우터 설정 (한 번만)
	server.SetupMessageRouter(serverInstance, tcpServer)

	// WebSocket 서버 시작 (메시지 라우터가 설정된 후)
	wsServer := server.SetupWebSocketServer(serverInstance)
	if wsServer == nil {
		log.Fatal("WebSocket 서버 초기화 실패")
	}
	defer wsServer.Stop()

	// 서버 루프 시작
	go serverInstance.Run()

	// HTTP 핸들러 설정
	api.SetupHTTPHandlers(wsServer)

	// HTTP 서버 설정
	httpServer := &http.Server{
		Addr:    ":8080",              // HTTP 및 WebSocket 서버는 8080 포트 사용
		Handler: http.DefaultServeMux, // 기본 핸들러 사용
	}

	// 서버를 고루틴에서 시작
	go func() {
		log.Printf("HTTP 및 WebSocket 서버가 포트 %s에서 시작됩니다", httpServer.Addr)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("HTTP 서버 오류: %v", err)
		}
	}()

	// 종료 신호 처리
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	// 종료 신호 대기
	<-stop
	log.Println("서버를 종료하는 중...")

	// HTTP 서버 정상 종료
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := httpServer.Shutdown(ctx); err != nil {
		log.Printf("서버 종료 오류: %v", err)
	}

	log.Println("서버가 정상적으로 종료되었습니다")
}
