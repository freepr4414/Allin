package tables

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"

	"narabackend/src/consts"
	"narabackend/src/utils"
)

// RegisterManagerAccessRoutes는 manager_access_table 관련 엔드포인트를 등록합니다.
func RegisterManagerAccessRoutes(r *mux.Router) {
	r.HandleFunc("/manager-access", GetManagerAccesses).Methods("GET")
	r.HandleFunc("/manager-access/{id}", GetManagerAccess).Methods("GET")
	r.HandleFunc("/manager-access", CreateManagerAccess).Methods("POST")
	r.HandleFunc("/manager-access/{id}", UpdateManagerAccess).Methods("PUT")
	r.HandleFunc("/manager-access/{id}", DeleteManagerAccess).Methods("DELETE")
}

// ManagerAccess 구조체는 manager_access_table의 각 컬럼을 매핑합니다.
type ManagerAccess struct {
	SerialNumber int       `json:"serial_number" db:"serial_number"`
	ManagerID    string    `json:"manager_id" db:"manager_id"`
	AccessLevel  int       `json:"access_level" db:"access_level"`
	Permissions  string    `json:"permissions" db:"permissions"`
	GrantedAt    time.Time `json:"granted_at" db:"granted_at"`
	ExpiresAt    time.Time `json:"expires_at" db:"expires_at"`
	Status       string    `json:"status" db:"status"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// ManagerAccessRequest는 요청 시 사용되는 구조체입니다.
type ManagerAccessRequest struct {
	ManagerID   string `json:"manager_id"`
	AccessLevel int    `json:"access_level"`
	Permissions string `json:"permissions"`
	ExpiresAt   string `json:"expires_at"`
	Status      string `json:"status"`
}

// GetManagerAccesses: "X-Fields" 헤더에 지정된 필드만 조회하거나 전체 필드를 조회합니다.
// URL 쿼리 파라미터를 통해 필터링 기능도 지원합니다.
func GetManagerAccesses(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 허용된 필드 목록 정의
	allowedFields := []string{
		"serial_number", "manager_id", "access_level", "permissions", "granted_at", "expires_at", "status", "created_at", "updated_at",
	}

	// 필드 선택 처리
	// X-Fields 헤더를 통한 필드 선택 처리
	fieldsHeader := r.Header.Get("X-Fields")
	var fields []string
	if fieldsHeader != "" {
		// 요청된 필드를 콤마로 분리하여 처리
		requested := strings.Split(fieldsHeader, ",")
		allowedSet := make(map[string]bool)
		for _, f := range allowedFields {
			allowedSet[f] = true
		}
		// 요청된 필드 중 허용된 필드만 선택
		for _, f := range requested {
			f = strings.TrimSpace(f)
			if allowedSet[f] {
				fields = append(fields, f)
			}
		}
		// 선택된 필드가 없으면 전체 필드 사용
		if len(fields) == 0 {
			fields = allowedFields
		}
	} else {
		// X-Fields 헤더가 없으면 전체 필드 사용
		fields = allowedFields
	}

	// 필터링 조건 처리 (관리자 접근 권한 관련 쿼리 파라미터)
	filters := []string{}
	args := []interface{}{}
	paramIdx := 1

	// 지원하는 필터 파라미터 목록
	filterParams := map[string]string{
		"manager_id":    "manager_id",
		"access_level":  "access_level",
		"status":        "status",
	}

	// URL 쿼리 파라미터에서 필터 조건 추출
	for param, dbField := range filterParams {
		if value := r.URL.Query().Get(param); value != "" {
			filters = append(filters, fmt.Sprintf("%s = $%d", dbField, paramIdx))
			args = append(args, value)
			paramIdx++
		}
	}

	// 검색 기능 추가 (permissions에 대한 부분 검색)
	if search := r.URL.Query().Get("search"); search != "" {
		filters = append(filters, fmt.Sprintf("permissions LIKE $%d", paramIdx))
		args = append(args, "%"+search+"%")
		paramIdx++
	}

	// 쿼리 구성
	query := "SELECT " + strings.Join(fields, ", ") + " FROM manager_access_table"
	if len(filters) > 0 {
		query += " WHERE " + strings.Join(filters, " AND ")
	}

	// 정렬 옵션 처리
	if sort := r.URL.Query().Get("sort"); sort != "" {
		direction := "ASC"
		if strings.HasPrefix(sort, "-") {
			sort = sort[1:]
			direction = "DESC"
		}

		// 허용된 정렬 필드인지 확인
		allowedSortFields := map[string]bool{
			"serial_number": true,
			"manager_id":    true,
			"access_level":  true,
			"granted_at":    true,
			"expires_at":    true,
			"created_at":    true,
		}

		if allowedSortFields[sort] {
			query += fmt.Sprintf(" ORDER BY %s %s", sort, direction)
		}
	} else {
		// 기본 정렬은 serial_number 기준
		query += " ORDER BY serial_number ASC"
	}
	
	// 로깅 추가
	log.Printf("실행 쿼리: %s, 인자: %v", query, args)
	
	// 쿼리 실행
	var rows *sql.Rows
	var err error
	if len(args) > 0 {
		rows, err = utils.DB.QueryContext(ctx, query, args...)
	} else {
		rows, err = utils.DB.QueryContext(ctx, query)
	}
	
	if err != nil {
		log.Printf("데이터베이스 쿼리 오류: %v", err)
		http.Error(w, "데이터 조회 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// 결과 처리
	columns, err := rows.Columns()
	if err != nil {
		log.Printf("컬럼 정보 조회 오류: %v", err)
		http.Error(w, "데이터 처리 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}

	result := []map[string]interface{}{}
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			log.Printf("행 스캔 오류: %v", err)
			http.Error(w, "데이터 처리 중 오류가 발생했습니다", http.StatusInternalServerError)
			return
		}

		rowMap := make(map[string]interface{})
		for i, col := range columns {
			var v interface{}
			val := values[i]
			if b, ok := val.([]byte); ok {
				v = string(b)
			} else {
				v = val
			}
			rowMap[col] = v
		}
		result = append(result, rowMap)
	}

	// 결과 반환
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// GetManagerAccess: URL 경로에서 id를 추출하여 특정 관리자 접근 기록을 조회합니다.
// strconv.Atoi를 사용하여 문자열을 정수로 변환하고 인라인 쿼리를 실행합니다.
func GetManagerAccess(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 경로에서 id 파라미터 추출 및 정수 변환 검증
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("ID 파싱 오류: %v", err)
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerAccess 단일 조회 요청 시작 - ID: %d", id)

	// 관리자 접근 기록 데이터 구조체
	var managerAccess ManagerAccess
	
	// 인라인 쿼리 실행 및 체인 스타일 스캔 연산으로 성능 최적화
	// 모든 필드를 한 번에 조회하여 네트워크 왕복 최소화
	err = utils.DB.QueryRowContext(ctx, `
		SELECT serial_number, manager_id, access_level, permissions, granted_at, expires_at, status, created_at, updated_at
		FROM manager_access_table WHERE serial_number = $1`, id).
		Scan(&managerAccess.SerialNumber, &managerAccess.ManagerID, &managerAccess.AccessLevel, &managerAccess.Permissions,
			&managerAccess.GrantedAt, &managerAccess.ExpiresAt, &managerAccess.Status, &managerAccess.CreatedAt, &managerAccess.UpdatedAt)
	
	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("단일 조회 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("ManagerAccess 없음 - ID: %d", id)
			http.Error(w, "ManagerAccess를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			log.Printf("단일 조회 오류: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	
	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(managerAccess); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// CreateManagerAccess: 새로운 관리자 접근 기록을 생성합니다.
// JSON 요청 본문을 파싱하여 데이터베이스에 INSERT 연산을 수행하고 생성된 결과를 반환합니다.
func CreateManagerAccess(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// JSON 요청 본문 파싱 및 검증
	var req ManagerAccessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 파싱 오류: %v", err)
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증 - manager_id는 반드시 필요
	if req.ManagerID == "" {
		log.Printf("필수 필드 누락: manager_id")
		http.Error(w, "필수 필드 누락", http.StatusBadRequest)
		return
	}

	// 새 관리자 접근 기록을 저장할 구조체
	var managerAccess ManagerAccess
	
	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerAccess 생성 요청 시작: %+v", req)
	
	// INSERT 쿼리 실행 및 RETURNING을 통한 생성된 데이터 반환
	// - CURRENT_TIMESTAMP로 자동 시간 설정
	// - 체인 스타일 스캔으로 성능 최적화
	err := utils.DB.QueryRowContext(ctx, `
		INSERT INTO manager_access_table (manager_id, access_level, permissions, granted_at, expires_at, status, created_at, updated_at)
		VALUES ($1, $2, $3, CURRENT_TIMESTAMP, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING serial_number, manager_id, access_level, permissions, granted_at, expires_at, status, created_at, updated_at`,
		req.ManagerID, req.AccessLevel, req.Permissions, req.ExpiresAt, req.Status).
		Scan(&managerAccess.SerialNumber, &managerAccess.ManagerID, &managerAccess.AccessLevel, &managerAccess.Permissions,
			&managerAccess.GrantedAt, &managerAccess.ExpiresAt, &managerAccess.Status, &managerAccess.CreatedAt, &managerAccess.UpdatedAt)

	// 실행 시간 및 오류 로깅
	duration := time.Since(startTime)
	log.Printf("생성 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 중복 키 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		log.Printf("생성 오류: %v", err)
		if strings.Contains(err.Error(), "duplicate key") {
			http.Error(w, "이미 존재하는 관리자 접근 기록입니다", http.StatusBadRequest)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// 201 Created 상태로 생성된 데이터 반환
	log.Printf("ManagerAccess 생성 완료 - ID: %d", managerAccess.SerialNumber)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(managerAccess); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// UpdateManagerAccess: 기존 관리자 접근 기록을 업데이트합니다.
// URL 경로의 ID와 JSON 요청 본문의 데이터를 사용하여 UPDATE 연산을 수행합니다.
func UpdateManagerAccess(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 경로에서 id 파라미터 추출 및 검증
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	// JSON 요청 본문 파싱 및 검증
	var req ManagerAccessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 파싱 오류: %v", err)
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerAccess 업데이트 요청 시작 - ID: %d, 데이터: %+v", id, req)

	// 업데이트된 데이터를 저장할 구조체
	var managerAccess ManagerAccess

	// UPDATE 쿼리 실행 - COALESCE와 NULLIF를 사용한 선택적 업데이트
	// - COALESCE(NULLIF(value, ''), current_value): 빈 문자열이 아닌 경우만 업데이트
	// - COALESCE(value, current_value): NULL이 아닌 경우만 업데이트
	// - RETURNING으로 업데이트된 완전한 레코드 반환
	err = utils.DB.QueryRowContext(ctx, `
		UPDATE manager_access_table SET
			manager_id = COALESCE(NULLIF($2, ''), manager_id),
			access_level = COALESCE($3, access_level),
			permissions = COALESCE(NULLIF($4, ''), permissions),
			status = COALESCE(NULLIF($5, ''), status),
			updated_at = CURRENT_TIMESTAMP
		WHERE serial_number = $1
		RETURNING serial_number, manager_id, access_level, permissions, granted_at, expires_at, status, created_at, updated_at`,
		id, req.ManagerID, req.AccessLevel, req.Permissions, req.Status).
		Scan(&managerAccess.SerialNumber, &managerAccess.ManagerID, &managerAccess.AccessLevel, &managerAccess.Permissions,
			&managerAccess.GrantedAt, &managerAccess.ExpiresAt, &managerAccess.Status, &managerAccess.CreatedAt, &managerAccess.UpdatedAt)

	// 실행 시간 및 결과 로깅
	duration := time.Since(startTime)
	log.Printf("업데이트 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드 존재 여부 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		log.Printf("업데이트 오류: %v", err)
		if err == sql.ErrNoRows {
			http.Error(w, "ManagerAccess를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// 성공적인 업데이트 결과 반환
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(managerAccess); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// DeleteManagerAccess: 특정 관리자 접근 기록을 삭제합니다.
// URL 경로에서 ID를 추출하여 해당 레코드를 데이터베이스에서 완전히 제거합니다.
func DeleteManagerAccess(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 경로에서 id 파라미터 추출 및 정수 변환
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("ID 파싱 오류: %v", err)
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerAccess 삭제 요청 시작 - ID: %d", id)

	// DELETE 쿼리 실행
	result, err := utils.DB.ExecContext(ctx, "DELETE FROM manager_access_table WHERE serial_number = $1", id)
	
	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("삭제 쿼리 실행 시간: %v", duration)

	// 데이터베이스 오류 처리
	if err != nil {
		log.Printf("삭제 쿼리 오류: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 영향받은 행 수 확인
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("영향받은 행 수 확인 오류: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 삭제된 레코드가 없는 경우 (존재하지 않는 ID)
	if rowsAffected == 0 {
		log.Printf("삭제할 ManagerAccess 없음 - ID: %d", id)
		http.Error(w, "ManagerAccess를 찾을 수 없습니다.", http.StatusNotFound)
		return
	}

	// 성공적인 삭제 완료 - 204 No Content 응답
	log.Printf("ManagerAccess 삭제 완료 - ID: %d", id)
	w.WriteHeader(http.StatusNoContent)
}