package models

import (
	"bytes"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"math/big"
)

// 메시지 타입 상수
const (
	BinaryMessageTypeConnect = byte(1)
	BinaryMessageTypeMessage = byte(2)
	BinaryMessageTypePing    = byte(3)
	BinaryMessageTypePong    = byte(4)
	BinaryMessageTypeWelcome = byte(5)
)

// GetBinaryMessageTypeName은 메시지 타입을 한국어 텍스트로 변환합니다
func GetBinaryMessageTypeName(msgType byte) string {
	switch msgType {
	case BinaryMessageTypeConnect:
		return "연결(Connect)"
	case BinaryMessageTypeMessage:
		return "메시지(Message)"
	case BinaryMessageTypePing:
		return "핑(Ping)"
	case BinaryMessageTypePong:
		return "퐁(Pong)"
	case BinaryMessageTypeWelcome:
		return "환영(Welcome)"
	default:
		return "알 수 없음(Unknown)"
	}
}

// BinaryMessage는 바이너리 형식의 메시지를 표현합니다
type BinaryMessage struct {
	Auth uint32 // 4바이트 인증 헤더 (맨 앞)
	Type byte   // 메시지 타입 (1바이트)
	Data []byte // 메시지 데이터 (가변 길이)
}

// 랜덤 바이트 생성 함수
func randomByte() byte {
	n, _ := rand.Int(rand.Reader, big.NewInt(256))
	return byte(n.Int64())
}

// Naradesk용 인증 생성: 첫3바이트 합산
func generateNaradeskAuth() uint32 {
	byte1 := randomByte()
	byte2 := randomByte()
	byte3 := randomByte()
	byte4 := byte((int(byte1) + int(byte2) + int(byte3)) & 0xFF)

	return uint32(byte1)<<24 | uint32(byte2)<<16 | uint32(byte3)<<8 | uint32(byte4)
}

// Naradevice용 인증 생성: (첫번째+두번째) XOR 세번째
func generateNaradeviceAuth() uint32 {
	byte1 := randomByte()
	byte2 := randomByte()
	byte3 := randomByte()
	byte4 := byte((int(byte1)+int(byte2))&0xFF) ^ byte3

	return uint32(byte1)<<24 | uint32(byte2)<<16 | uint32(byte3)<<8 | uint32(byte4)
}

// Naradesk 인증 검증
func validateNaradeskAuth(auth uint32) bool {
	byte1 := byte(auth >> 24)
	byte2 := byte(auth >> 16)
	byte3 := byte(auth >> 8)
	byte4 := byte(auth)

	expected := byte((int(byte1) + int(byte2) + int(byte3)) & 0xFF)
	return byte4 == expected
}

// Naradevice 인증 검증
func validateNaradeviceAuth(auth uint32) bool {
	byte1 := byte(auth >> 24)
	byte2 := byte(auth >> 16)
	byte3 := byte(auth >> 8)
	byte4 := byte(auth)

	expected := byte((int(byte1)+int(byte2))&0xFF) ^ byte3
	return byte4 == expected
}

// EncodeBinaryMessage는 BinaryMessage를 바이트 배열로 인코딩합니다
// 형식: [인증(4바이트)][타입(1바이트)][데이터 길이(4바이트)][데이터(가변 길이)]
func EncodeBinaryMessage(msg *BinaryMessage, clientType string) ([]byte, error) {
	var buf bytes.Buffer

	// 클라이언트 타입별 인증 생성
	var auth uint32
	switch clientType {
	case "naradesk": // naradesk는 기존 shinnara 인증 방식 사용
		auth = generateNaradeskAuth()
	case "naradevice":
		auth = generateNaradeviceAuth()
	default:
		return nil, errors.New("지원하지 않는 클라이언트 타입")
	}

	// 인증 헤더 작성 (4바이트, 빅 엔디안)
	authBytes := make([]byte, 4)
	binary.BigEndian.PutUint32(authBytes, auth)
	buf.Write(authBytes)

	// 타입 작성
	buf.WriteByte(msg.Type)

	// 데이터 길이 작성 (4바이트, 빅 엔디안)
	dataLen := uint32(len(msg.Data))
	lenBytes := make([]byte, 4)
	binary.BigEndian.PutUint32(lenBytes, dataLen)
	buf.Write(lenBytes)

	// 데이터 작성
	buf.Write(msg.Data)

	return buf.Bytes(), nil
}

// DecodeBinaryMessage는 바이트 배열을 BinaryMessage로 디코딩합니다
func DecodeBinaryMessage(data []byte) (*BinaryMessage, string, error) {
	if len(data) < 9 { // 최소 9바이트 필요 (인증 4바이트 + 타입 1바이트 + 길이 4바이트)
		return nil, "", errors.New("데이터가 너무 짧습니다")
	}

	// 인증 헤더 읽기
	auth := binary.BigEndian.Uint32(data[0:4])

	// 클라이언트 타입 확인 및 검증
	var clientType string
	if validateNaradeskAuth(auth) {
		clientType = "naradesk" // naradesk 인증 방식 사용
	} else if validateNaradeviceAuth(auth) {
		clientType = "naradevice"
	} else {
		return nil, "", errors.New("잘못된 인증 헤더")
	}

	// 타입 읽기
	msgType := data[4]

	// 데이터 길이 읽기
	dataLen := binary.BigEndian.Uint32(data[5:9])

	// 데이터 읽기
	if uint32(len(data)-9) < dataLen {
		return nil, "", errors.New("데이터 길이가 잘못되었습니다")
	}

	msgData := data[9 : 9+dataLen]

	return &BinaryMessage{
		Auth: auth,
		Type: msgType,
		Data: msgData,
	}, clientType, nil
}

// EncodeConnectData는 연결 메시지 데이터를 인코딩합니다
// 형식: [회사코드 길이(1바이트)][회사코드][사용자코드 길이(1바이트)][사용자코드][소스 길이(1바이트)][소스]
func EncodeConnectData(companyCode, userCode, source string) []byte {
	var buf bytes.Buffer

	// 회사코드
	buf.WriteByte(byte(len(companyCode)))
	buf.WriteString(companyCode)

	// 사용자코드
	buf.WriteByte(byte(len(userCode)))
	buf.WriteString(userCode)

	// 소스
	buf.WriteByte(byte(len(source)))
	buf.WriteString(source)

	return buf.Bytes()
}

// DecodeConnectData는 연결 메시지 데이터를 디코딩합니다
func DecodeConnectData(data []byte) (companyCode, userCode, source string, err error) {
	if len(data) < 3 { // 최소 3바이트 필요 (각 길이 필드)
		return "", "", "", errors.New("연결 데이터가 너무 짧습니다")
	}

	buf := bytes.NewBuffer(data)

	// 회사코드 읽기
	companyLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", err
	}
	if int(companyLen) > buf.Len() {
		return "", "", "", errors.New("회사코드 길이가 잘못되었습니다")
	}
	companyBytes := make([]byte, companyLen)
	buf.Read(companyBytes)
	companyCode = string(companyBytes)

	// 사용자코드 읽기
	userLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", err
	}
	if int(userLen) > buf.Len() {
		return "", "", "", errors.New("사용자코드 길이가 잘못되었습니다")
	}
	userBytes := make([]byte, userLen)
	buf.Read(userBytes)
	userCode = string(userBytes)

	// 소스 읽기
	sourceLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", err
	}
	if int(sourceLen) > buf.Len() {
		return "", "", "", errors.New("소스 길이가 잘못되었습니다")
	}
	sourceBytes := make([]byte, sourceLen)
	buf.Read(sourceBytes)
	source = string(sourceBytes)

	return companyCode, userCode, source, nil
}

// EncodeMessageData는 일반 메시지 데이터를 인코딩합니다
// 형식: [회사코드 길이(1바이트)][회사코드][사용자코드 길이(1바이트)][사용자코드][소스 길이(1바이트)][소스]
//
//	[방코드 길이(1바이트)][방코드][좌석번호 길이(1바이트)][좌석번호]
//	[전원번호 길이(1바이트)][전원번호][타임스탬프 길이(1바이트)][타임스탬프]
func EncodeMessageData(companyCode, userCode, source, roomCode, seatNumber, powerNumber, timestamp string) []byte {
	var buf bytes.Buffer

	// 회사코드
	buf.WriteByte(byte(len(companyCode)))
	buf.WriteString(companyCode)

	// 사용자코드
	buf.WriteByte(byte(len(userCode)))
	buf.WriteString(userCode)

	// 소스 (추가)
	buf.WriteByte(byte(len(source)))
	buf.WriteString(source)

	// 방코드
	buf.WriteByte(byte(len(roomCode)))
	buf.WriteString(roomCode)

	// 좌석번호
	buf.WriteByte(byte(len(seatNumber)))
	buf.WriteString(seatNumber)

	// 전원번호
	buf.WriteByte(byte(len(powerNumber)))
	buf.WriteString(powerNumber)

	// 타임스탬프
	buf.WriteByte(byte(len(timestamp)))
	buf.WriteString(timestamp)

	return buf.Bytes()
}

// DecodeMessageData는 일반 메시지 데이터를 디코딩합니다
func DecodeMessageData(data []byte) (companyCode, userCode, source, roomCode, seatNumber, powerNumber, timestamp string, err error) {
	if len(data) < 7 { // 최소 7바이트 필요 (각 길이 필드)
		return "", "", "", "", "", "", "", errors.New("메시지 데이터가 너무 짧습니다")
	}

	buf := bytes.NewBuffer(data)

	// 회사코드 읽기
	companyLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(companyLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("회사코드 길이가 잘못되었습니다")
	}
	companyBytes := make([]byte, companyLen)
	buf.Read(companyBytes)
	companyCode = string(companyBytes)

	// 사용자코드 읽기
	userLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(userLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("사용자코드 길이가 잘못되었습니다")
	}
	userBytes := make([]byte, userLen)
	buf.Read(userBytes)
	userCode = string(userBytes)

	// 소스 읽기 (추가)
	sourceLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(sourceLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("소스 길이가 잘못되었습니다")
	}
	sourceBytes := make([]byte, sourceLen)
	buf.Read(sourceBytes)
	source = string(sourceBytes)

	// 방코드 읽기
	roomLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(roomLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("방코드 길이가 잘못되었습니다")
	}
	roomBytes := make([]byte, roomLen)
	buf.Read(roomBytes)
	roomCode = string(roomBytes)

	// 좌석번호 읽기
	seatLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(seatLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("좌석번호 길이가 잘못되었습니다")
	}
	seatBytes := make([]byte, seatLen)
	buf.Read(seatBytes)
	seatNumber = string(seatBytes)

	// 전원번호 읽기
	powerLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(powerLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("전원번호 길이가 잘못되었습니다")
	}
	powerBytes := make([]byte, powerLen)
	buf.Read(powerBytes)
	powerNumber = string(powerBytes)

	// 타임스탬프 읽기
	timestampLen, err := buf.ReadByte()
	if err != nil {
		return "", "", "", "", "", "", "", err
	}
	if int(timestampLen) > buf.Len() {
		return "", "", "", "", "", "", "", errors.New("타임스탬프 길이가 잘못되었습니다")
	}
	timestampBytes := make([]byte, timestampLen)
	buf.Read(timestampBytes)
	timestamp = string(timestampBytes)

	return companyCode, userCode, source, roomCode, seatNumber, powerNumber, timestamp, nil
}

// EncodeWelcomeData는 웰컴 메시지 데이터를 인코딩합니다
// 형식: [메시지 길이(1바이트)][메시지]
func EncodeWelcomeData(message string) []byte {
	var buf bytes.Buffer

	// 메시지
	buf.WriteByte(byte(len(message)))
	buf.WriteString(message)

	return buf.Bytes()
}

// DecodeWelcomeData는 웰컴 메시지 데이터를 디코딩합니다
func DecodeWelcomeData(data []byte) (message string, err error) {
	if len(data) < 1 { // 최소 1바이트 필요 (길이 필드)
		return "", errors.New("웰컴 데이터가 너무 짧습니다")
	}

	buf := bytes.NewBuffer(data)

	// 메시지 읽기
	messageLen, err := buf.ReadByte()
	if err != nil {
		return "", err
	}
	if int(messageLen) > buf.Len() {
		return "", errors.New("메시지 길이가 잘못되었습니다")
	}
	messageBytes := make([]byte, messageLen)
	buf.Read(messageBytes)
	message = string(messageBytes)

	return message, nil
}

// 편의 함수들

// CreateBinaryConnectMessage는 바이너리 연결 메시지를 생성합니다
func CreateBinaryConnectMessage(companyCode, userCode, source string) []byte {
	connectData := EncodeConnectData(companyCode, userCode, source)
	msg := &BinaryMessage{
		Type: BinaryMessageTypeConnect,
		Data: connectData,
	}
	// source에 따라 클라이언트 타입 결정
	clientType := source
	if source != "naradesk" && source != "naradevice" {
		clientType = "naradesk" // 기본값을 naradesk로 변경
	}
	result, _ := EncodeBinaryMessage(msg, clientType)
	return result
}

// CreateBinaryMessage는 바이너리 일반 메시지를 생성합니다
func CreateBinaryMessage(companyCode, userCode, source, roomCode, seatNumber, powerNumber, timestamp string) []byte {
	messageData := EncodeMessageData(companyCode, userCode, source, roomCode, seatNumber, powerNumber, timestamp)
	msg := &BinaryMessage{
		Type: BinaryMessageTypeMessage,
		Data: messageData,
	}
	// source에 따라 클라이언트 타입 결정
	clientType := source
	if source != "naradesk" && source != "naradevice" {
		clientType = "naradesk" // 기본값을 naradesk로 변경
	}
	result, _ := EncodeBinaryMessage(msg, clientType)
	return result
}

// CreateBinaryPingMessage는 바이너리 핑 메시지를 생성합니다
func CreateBinaryPingMessage(clientType string) []byte {
	msg := &BinaryMessage{
		Type: BinaryMessageTypePing,
		Data: []byte{},
	}
	result, _ := EncodeBinaryMessage(msg, clientType)
	return result
}

// CreateBinaryPongMessage는 바이너리 퐁 메시지를 생성합니다
func CreateBinaryPongMessage(clientType string) []byte {
	msg := &BinaryMessage{
		Type: BinaryMessageTypePong,
		Data: []byte{},
	}
	result, _ := EncodeBinaryMessage(msg, clientType)
	return result
}

// CreateBinaryWelcomeMessage는 바이너리 웰컴 메시지를 생성합니다
func CreateBinaryWelcomeMessage(message string, clientType string) []byte {
	welcomeData := EncodeWelcomeData(message)
	msg := &BinaryMessage{
		Type: BinaryMessageTypeWelcome,
		Data: welcomeData,
	}
	result, _ := EncodeBinaryMessage(msg, clientType)
	return result
}
