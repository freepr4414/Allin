package config

import (
	"os"
)

// GetTCPServerAddress returns the TCP server address from environment or default
func GetTCPServerAddress() string {
	addr := os.Getenv("TCP_SERVER_ADDRESS")
	if addr == "" {
		return ":8091" // 기본 TCP 포트
	}
	return addr
}
