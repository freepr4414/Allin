package message

import (
	"log"

	"github.com/soinfree/naracontrol/src/config"
	"github.com/soinfree/naracontrol/src/models"
)

type ServerInterface interface {
	CompanyMutexRLock()
	CompanyMutexRUnlock()
	GetClientsByCompany() map[string]map[*models.Client]bool
	LockClientRead(clientID string)
	UnlockClientRead(clientID string)
	LockClientWrite(clientID string)
	UnlockClientWrite(clientID string)
	GetUnregisterChannel() chan<- *models.Client
	SendTCPMessage(clientID string, message []byte) error
	SendWSMessage(clientID string, message []byte) error
}

func RouteMessage(s ServerInterface, sender *models.Client, message []byte) {
	log.Printf("[RECV] 메시지 라우팅 시작 - 발신자 ID: %s, 회사코드: %s, 타입: %s",
		sender.ID, sender.CompanyCode, sender.Type)

	binaryMsg, clientType, err := models.DecodeBinaryMessage(message)
	if err != nil {
		log.Printf("바이너리 메시지 디코딩 실패 - 발신자: %s, 오류: %v", sender.ID, err)
		return
	}

	log.Printf("인증된 클라이언트 타입: %s - 발신자: %s", clientType, sender.ID)

	if binaryMsg.Type != models.BinaryMessageTypeMessage {
		typeName := models.GetBinaryMessageTypeName(binaryMsg.Type)
		log.Printf("라우팅 대상이 아닌 메시지 타입: %s (타입 코드: %d)", typeName, binaryMsg.Type)
		return
	}

	companyCode, userCode, source, roomCode, seatNumber, powerNumber, _, err := models.DecodeMessageData(binaryMsg.Data)
	if err != nil {
		log.Println("Error decoding binary message data for routing:", err)
		return
	}

	var targetType string
	if sender.Type == config.ClientTypeNaradesk {
		targetType = config.ClientTypeNaradevice
	} else {
		targetType = config.ClientTypeNaradesk
	}

	log.Printf("바이너리 메시지 라우팅 - 발신자: %s (%s), 타입: %s, 대상타입: %s",
		sender.ID, sender.CompanyCode, sender.Type, targetType)

	s.CompanyMutexRLock()
	clientsByCompany := s.GetClientsByCompany()
	companyClients, exists := clientsByCompany[sender.CompanyCode]
	s.CompanyMutexRUnlock()

	if !exists || len(companyClients) == 0 {
		log.Printf("회사코드 %s에 대한 클라이언트가 없음", sender.CompanyCode)
		return
	}

	sentClients := make(map[string]bool)
	var recipientCount int

	for client := range companyClients {
		if client.Type != targetType {
			continue
		}

		if sentClients[client.ID] {
			continue
		}

		targetMessage := &models.BinaryMessage{
			Type: binaryMsg.Type,
			Data: binaryMsg.Data,
		}

		encodedMessage, err := models.EncodeBinaryMessage(targetMessage, client.Type)
		if err != nil {
			log.Printf("메시지 재인코딩 실패 - 클라이언트: %s, 오류: %v", client.ID, err)
			continue
		}

		if client.Type == config.ClientTypeNaradesk {
			err = s.SendWSMessage(client.ID, encodedMessage)
		} else {
			err = s.SendTCPMessage(client.ID, encodedMessage)
		}

		if err == nil {
			recipientCount++
			sentClients[client.ID] = true
			log.Printf("메시지 전송 성공 - 클라이언트: %s", client.ID)
		} else {
			log.Printf("메시지 전송 실패 - 클라이언트: %s, 오류: %v", client.ID, err)
		}
	}

	if recipientCount > 0 {
		log.Printf("바이너리 메시지 라우팅 완료 - 발신자: %s (%s) [Source: %s, Room: %s, Seat: %s, Power: %s], 수신자 수: %d",
			companyCode, userCode, source, roomCode, seatNumber, powerNumber, recipientCount)
	} else {
		log.Printf("바이너리 메시지 라우팅 실패 - 발신자: %s (%s), 수신자 없음", companyCode, userCode)
	}
}
