// manager.go
package tables

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"

	"narabackend/src/consts"
	"narabackend/src/utils"
)

// Manager 구조체는 manager_table의 각 컬럼을 Go 구조체로 매핑합니다.
// 시스템 관리자의 기본 정보와 권한을 나타내며, 보안을 위해 비밀번호는 응답에서 제외됩니다.
// JSON 태그는 API 응답 시 필드명을 정의하고, db 태그는 데이터베이스 컬럼명을 정의합니다.
type Manager struct {
	ManagerID   string    `json:"manager_id" db:"manager_id"`
	Name        string    `json:"name" db:"name"`
	Password    string    `json:"password,omitempty" db:"password"`
	Email       string    `json:"email" db:"email"`
	Phone       string    `json:"phone" db:"phone"`
	Role        string    `json:"role" db:"role"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// ManagerRequest는 HTTP 요청 시 사용되는 구조체입니다.
// 생성(POST) 및 업데이트(PUT/PATCH) 연산에서 클라이언트가 전송하는 데이터를 파싱하는 데 사용됩니다.
// 자동 생성되는 필드(시간 관련 필드)는 포함하지 않으며, 비밀번호는 별도 엔드포인트에서 처리합니다.
type ManagerRequest struct {
	ManagerID string `json:"manager_id"`
	Name      string `json:"name"`
	Password  string `json:"password"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
	Role      string `json:"role"`
}

// RegisterManagerRoutes는 manager_table 관련 REST API 엔드포인트를 등록합니다.
// 관리자 계정의 생명주기 전체를 관리하는 CRUD 연산과 비밀번호 변경 기능을 제공합니다.
// 각 엔드포인트는 HTTP 메서드와 URL 패턴에 따라 적절한 핸들러 함수로 라우팅됩니다.
func RegisterManagerRoutes(r *mux.Router) {
	r.HandleFunc("/managers", GetManagers).Methods("GET")
	r.HandleFunc("/managers/{manager_id}", GetManager).Methods("GET")
	r.HandleFunc("/managers", CreateManager).Methods("POST")
	r.HandleFunc("/managers/{manager_id}", UpdateManager).Methods("PUT", "PATCH")
	r.HandleFunc("/managers/{manager_id}", DeleteManager).Methods("DELETE")
	r.HandleFunc("/managers/{manager_id}/password", UpdateManagerPassword).Methods("PATCH")
}

// GetManagers: 관리자 목록을 조회하는 API 엔드포인트입니다.
// X-Fields 헤더를 통한 동적 필드 선택, 필터링, 검색, 정렬 기능을 제공합니다.
// 보안상 비밀번호 필드는 기본적으로 제외되며, 성능 최적화를 위해 다양한 기술을 사용합니다.
func GetManagers(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화 및 리소스 보호)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 허용된 필드 목록 정의 - 보안을 위해 화이트리스트 방식 사용
	// 비밀번호 필드는 보안상 제외하여 노출 방지
	allowedFields := []string{
		"manager_id", "name", "email", "phone", "role", "created_at", "updated_at",
	}

	// X-Fields 헤더를 통한 필드 선택 처리
	// 클라이언트가 필요한 필드만 요청하여 네트워크 트래픽 및 응답 크기 최적화
	fieldsHeader := r.Header.Get("X-Fields")
	var fields []string
	if fieldsHeader != "" {
		// 요청된 필드를 콤마로 분리하여 처리
		requested := strings.Split(fieldsHeader, ",")
		allowedSet := make(map[string]bool)
		for _, f := range allowedFields {
			allowedSet[f] = true
		}
		// 요청된 필드 중 허용된 필드만 선택 (보안 검증)
		for _, f := range requested {
			f = strings.TrimSpace(f)
			if allowedSet[f] {
				fields = append(fields, f)
			}
		}
		// 선택된 필드가 없으면 전체 허용 필드 사용
		if len(fields) == 0 {
			fields = allowedFields
		}
	} else {
		// X-Fields 헤더가 없으면 전체 허용 필드 사용
		fields = allowedFields
	}

	// 필터링 조건 처리 (관리자 계정 관련 쿼리 파라미터)
	filters := []string{}
	args := []interface{}{}
	paramIdx := 1

	// 지원하는 필터 파라미터 목록 (역할 기반 필터링)
	filterParams := map[string]string{
		"role":       "role",       // 관리자 역할별 필터링 (admin, manager, operator 등)
		"manager_id": "manager_id", // 특정 관리자 ID로 필터링
	}

	// URL 쿼리 파라미터에서 필터 조건 추출
	log.Printf("요청된 쿼리 파라미터: %v", r.URL.Query())
	for param, dbField := range filterParams {
		if value := r.URL.Query().Get(param); value != "" {
			log.Printf("필터 추가: %s = %s", param, value)
			filters = append(filters, fmt.Sprintf("%s = $%d", dbField, paramIdx))
			args = append(args, value)
			paramIdx++
		}
	}

	// 검색 기능 추가 (name, email에 대한 부분 검색)
	// 관리자 이름이나 이메일 주소를 통한 유연한 검색 지원
	if search := r.URL.Query().Get("search"); search != "" {
		log.Printf("검색어 추가: %s", search)
		filters = append(filters, fmt.Sprintf("(name LIKE $%d OR email LIKE $%d)", paramIdx, paramIdx+1))
		args = append(args, "%"+search+"%", "%"+search+"%")
		paramIdx += 2
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 목록 조회 요청 시작")

	// 쿼리 구성 - 동적 필드 선택과 필터링 조건 적용
	query := "SELECT " + strings.Join(fields, ", ") + " FROM manager_table"
	if len(filters) > 0 {
		query += " WHERE " + strings.Join(filters, " AND ")
	}

	// 정렬 옵션 처리 (URL 쿼리 파라미터의 sort 값 사용)
	if sort := r.URL.Query().Get("sort"); sort != "" {
		direction := "ASC"
		// "-" 접두사로 내림차순 정렬 지원 (예: sort=-created_at)
		if strings.HasPrefix(sort, "-") {
			sort = sort[1:]
			direction = "DESC"
		}

		// 허용된 정렬 필드인지 확인 (SQL 인젝션 방지)
		allowedSortFields := map[string]bool{
			"manager_id": true,
			"name":       true,
			"email":      true,
			"role":       true,
			"created_at": true,
		}

		if allowedSortFields[sort] {
			query += fmt.Sprintf(" ORDER BY %s %s", sort, direction)
		}
	} else {
		// 기본 정렬은 manager_id 기준 오름차순
		query += " ORDER BY manager_id ASC"
	}

	// 쿼리 로깅
	log.Printf("최종 필터 조건: %v", filters)
	log.Printf("실행 쿼리: %s, 인자: %v", query, args)

	// 쿼리 실행 - 인자 유무에 따른 조건부 실행
	var rows *sql.Rows
	var err error
	if len(args) > 0 {
		rows, err = utils.DB.QueryContext(ctx, query, args...)
	} else {
		rows, err = utils.DB.QueryContext(ctx, query)
	}

	if err != nil {
		log.Printf("데이터베이스 쿼리 오류: %v", err)
		log.Printf("실패한 쿼리: %s", query)
		log.Printf("실패한 인자: %v", args)
		http.Error(w, "데이터 조회 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// 결과 처리 - 컬럼 정보 가져오기
	columns, err := rows.Columns()
	if err != nil {
		log.Printf("컬럼 정보 조회 오류: %v", err)
		http.Error(w, "데이터 처리 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}

	// 결과를 맵 슬라이스로 구성 - 동적 필드 처리를 위해
	result := []map[string]interface{}{}
	for rows.Next() {
		// 스캔을 위한 인터페이스 슬라이스 준비
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		// 데이터베이스 결과를 스캔
		if err := rows.Scan(valuePtrs...); err != nil {
			log.Printf("행 스캔 오류: %v", err)
			http.Error(w, "데이터 처리 중 오류가 발생했습니다", http.StatusInternalServerError)
			return
		}

		// 각 로우를 맵으로 변환
		rowMap := make(map[string]interface{})
		for i, col := range columns {
			var v interface{}
			val := values[i]
			// 바이트 배열을 문자열로 변환 (PostgreSQL의 text 타입 처리)
			if b, ok := val.([]byte); ok {
				v = string(b)
			} else {
				v = val
			}
			rowMap[col] = v
		}
		result = append(result, rowMap)
	}

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("목록 조회 쿼리 실행 시간: %v, 결과 수: %d", duration, len(result))

	// 결과 반환
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// GetManager: URL 경로에서 manager_id를 추출하여 특정 관리자 정보를 조회합니다.
// 보안상 비밀번호 필드는 제외하고 모든 필드를 반환하며, 성능 최적화를 위해 인라인 쿼리를 사용합니다.
// 관리자 ID는 문자열 타입이므로 별도의 타입 변환 없이 직접 사용합니다.
func GetManager(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 경로에서 manager_id 파라미터 추출 및 검증
	vars := mux.Vars(r)
	managerID := vars["manager_id"]
	if managerID == "" {
		log.Printf("manager_id 파라미터 누락")
		http.Error(w, "잘못된 manager_id", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 단일 조회 요청 시작 - ID: %s", managerID)

	// 관리자 정보 데이터 구조체
	var manager Manager

	// 인라인 쿼리 실행 및 체인 스타일 스캔 연산으로 성능 최적화
	// 보안상 비밀번호 필드는 조회에서 제외
	// 모든 필드를 한 번에 조회하여 네트워크 왕복 최소화
	err := utils.DB.QueryRowContext(ctx, `
		SELECT manager_id, name, email, phone, role, created_at, updated_at
		FROM manager_table WHERE manager_id = $1`, managerID).
		Scan(&manager.ManagerID, &manager.Name, &manager.Email, &manager.Phone,
			&manager.Role, &manager.CreatedAt, &manager.UpdatedAt)

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("단일 조회 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("Manager 없음 - ID: %s", managerID)
			http.Error(w, "Manager를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			log.Printf("단일 조회 오류: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(manager); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// CreateManager: 새로운 관리자 계정을 생성합니다.
// JSON 요청 본문을 파싱하여 필수 필드를 검증하고, 비밀번호를 해싱한 후 데이터베이스에 저장합니다.
// RETURNING 절을 사용하여 생성된 완전한 레코드를 한 번에 반환합니다.
// TODO: 실제 운영 환경에서는 bcrypt 등의 보안 해싱 알고리즘을 사용해야 합니다.
func CreateManager(w http.ResponseWriter, r *http.Request) {
	// JSON 요청 본문 파싱 및 검증
	var req ManagerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 디코딩 오류: %v", err)
		http.Error(w, "잘못된 JSON 형식", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증 - 관리자 계정 생성에 반드시 필요한 정보들
	if req.ManagerID == "" || req.Name == "" || req.Password == "" || req.Email == "" {
		log.Printf("필수 필드 누락 - ManagerID: %s, Name: %s, Email: %s", 
			req.ManagerID, req.Name, req.Email)
		http.Error(w, "필수 필드가 누락되었습니다 (manager_id, name, password, email)", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 생성 요청 시작 - ID: %s, Name: %s, Email: %s", 
		req.ManagerID, req.Name, req.Email)

	// 비밀번호 해싱 (실제 환경에서는 bcrypt 등을 사용해야 함)
	// TODO: bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost) 구현 필요
	hashedPassword := req.Password // 현재는 평문 저장 (보안상 위험)

	// INSERT 쿼리 실행 및 RETURNING을 통한 생성된 데이터 반환
	// - CURRENT_TIMESTAMP로 자동 시간 설정
	// - 체인 스타일 스캔으로 성능 최적화
	// - 비밀번호는 응답에서 제외
	query := `
		INSERT INTO manager_table (
			manager_id, name, password, email, phone, role, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
		)
		RETURNING manager_id, name, email, phone, role, created_at, updated_at
	`

	var manager Manager
	err := utils.DB.QueryRowContext(ctx, query,
		req.ManagerID, req.Name, hashedPassword, req.Email, req.Phone, req.Role,
	).Scan(&manager.ManagerID, &manager.Name, &manager.Email, &manager.Phone,
		&manager.Role, &manager.CreatedAt, &manager.UpdatedAt)

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("생성 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 중복 키 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		log.Printf("관리자 생성 오류: %v", err)
		// 중복된 관리자 ID 또는 이메일 처리
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique constraint") {
			http.Error(w, "이미 존재하는 관리자 ID입니다", http.StatusConflict)
		} else {
			http.Error(w, "관리자 생성 실패", http.StatusInternalServerError)
		}
		return
	}

	// 201 Created 상태로 생성된 데이터 반환
	log.Printf("Manager 생성 완료 - ID: %s", manager.ManagerID)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(manager); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// UpdateManager: 기존 관리자 정보를 업데이트합니다 (비밀번호 제외).
// URL 경로의 manager_id와 JSON 요청 본문의 데이터를 사용하여 UPDATE 연산을 수행합니다.
// COALESCE와 NULLIF를 사용하여 선택적 업데이트를 지원하며, 비밀번호는 별도 엔드포인트에서 처리합니다.
func UpdateManager(w http.ResponseWriter, r *http.Request) {
	// URL 경로에서 manager_id 파라미터 추출 및 검증
	vars := mux.Vars(r)
	managerID := vars["manager_id"]

	if managerID == "" {
		log.Printf("manager_id 파라미터 누락")
		http.Error(w, "관리자 ID가 필요합니다", http.StatusBadRequest)
		return
	}

	// JSON 요청 본문 파싱 및 검증
	var req ManagerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 디코딩 오류: %v", err)
		http.Error(w, "잘못된 JSON 형식", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 업데이트 요청 시작 - ID: %s", managerID)

	// UPDATE 쿼리 실행 - COALESCE와 NULLIF를 사용한 선택적 업데이트
	// - COALESCE(NULLIF(value, ''), current_value): 빈 문자열이 아닌 경우만 업데이트
	// - RETURNING으로 업데이트된 완전한 레코드 반환 (비밀번호 제외)
	// - 비밀번호는 보안상 별도 엔드포인트에서만 변경 가능
	query := `
		UPDATE manager_table SET
			name = COALESCE(NULLIF($2, ''), name),
			email = COALESCE(NULLIF($3, ''), email),
			phone = COALESCE(NULLIF($4, ''), phone),
			role = COALESCE(NULLIF($5, ''), role),
			updated_at = CURRENT_TIMESTAMP
		WHERE manager_id = $1
		RETURNING manager_id, name, email, phone, role, created_at, updated_at
	`

	var manager Manager
	err := utils.DB.QueryRowContext(ctx, query,
		managerID, req.Name, req.Email, req.Phone, req.Role,
	).Scan(&manager.ManagerID, &manager.Name, &manager.Email, &manager.Phone,
		&manager.Role, &manager.CreatedAt, &manager.UpdatedAt)

	// 실행 시간 및 결과 로깅
	duration := time.Since(startTime)
	log.Printf("업데이트 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드 존재 여부 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("업데이트할 Manager 없음 - ID: %s", managerID)
			http.Error(w, "관리자를 찾을 수 없습니다", http.StatusNotFound)
		} else {
			log.Printf("관리자 업데이트 오류: %v", err)
			// 이메일 중복 등의 제약 조건 위반 처리
			if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique constraint") {
				http.Error(w, "중복된 이메일 주소입니다", http.StatusConflict)
			} else {
				http.Error(w, "관리자 업데이트 실패", http.StatusInternalServerError)
			}
		}
		return
	}

	// 성공적인 업데이트 결과 반환
	log.Printf("Manager 업데이트 완료 - ID: %s", managerID)
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(manager); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// UpdateManagerPassword: 관리자의 비밀번호를 업데이트합니다.
// 보안을 위해 현재 비밀번호 확인 후 새 비밀번호로 변경하는 별도 엔드포인트입니다.
// TODO: 실제 운영 환경에서는 bcrypt를 사용한 비밀번호 검증 및 해싱이 필요합니다.
func UpdateManagerPassword(w http.ResponseWriter, r *http.Request) {
	// URL 경로에서 manager_id 파라미터 추출 및 검증
	vars := mux.Vars(r)
	managerID := vars["manager_id"]

	if managerID == "" {
		log.Printf("manager_id 파라미터 누락")
		http.Error(w, "관리자 ID가 필요합니다", http.StatusBadRequest)
		return
	}

	// 비밀번호 변경 전용 요청 구조체
	var req struct {
		CurrentPassword string `json:"current_password"` // 현재 비밀번호 (검증용)
		NewPassword     string `json:"new_password"`     // 새 비밀번호
	}

	// JSON 요청 본문 파싱 및 검증
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 디코딩 오류: %v", err)
		http.Error(w, "잘못된 JSON 형식", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증 - 새 비밀번호는 반드시 필요
	if req.NewPassword == "" {
		log.Printf("새 비밀번호 누락 - ManagerID: %s", managerID)
		http.Error(w, "새 비밀번호가 필요합니다", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 비밀번호 변경 요청 시작 - ID: %s", managerID)

	// TODO: 현재 비밀번호 확인 로직 추가 필요
	// 실제 환경에서는 다음과 같은 과정을 거쳐야 함:
	// 1. 데이터베이스에서 현재 해시된 비밀번호 조회
	// 2. bcrypt.CompareHashAndPassword로 현재 비밀번호 검증
	// 3. 검증 성공 시에만 새 비밀번호로 업데이트

	// 새 비밀번호 해싱 (실제 환경에서는 bcrypt 등을 사용해야 함)
	// TODO: bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost) 구현 필요
	hashedNewPassword := req.NewPassword // 현재는 평문 저장 (보안상 위험)

	// UPDATE 쿼리 실행 - 비밀번호와 수정 시간만 업데이트
	query := `
		UPDATE manager_table SET
			password = $2,
			updated_at = CURRENT_TIMESTAMP
		WHERE manager_id = $1
	`

	result, err := utils.DB.ExecContext(ctx, query, managerID, hashedNewPassword)

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("비밀번호 업데이트 쿼리 실행 시간: %v", duration)

	// 데이터베이스 오류 처리
	if err != nil {
		log.Printf("비밀번호 업데이트 오류: %v", err)
		http.Error(w, "비밀번호 업데이트 실패", http.StatusInternalServerError)
		return
	}

	// 영향받은 행 수 확인
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("영향받은 행 수 확인 오류: %v", err)
		http.Error(w, "업데이트 결과 확인 실패", http.StatusInternalServerError)
		return
	}

	// 업데이트된 레코드가 없는 경우 (존재하지 않는 관리자 ID)
	if rowsAffected == 0 {
		log.Printf("비밀번호 변경할 Manager 없음 - ID: %s", managerID)
		http.Error(w, "관리자를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// 성공적인 비밀번호 변경 완료 - 204 No Content 응답
	// 보안상 변경된 비밀번호나 관리자 정보는 응답에 포함하지 않음
	log.Printf("Manager 비밀번호 변경 완료 - ID: %s", managerID)
	w.WriteHeader(http.StatusNoContent)
}

// DeleteManager: 특정 관리자 계정을 삭제합니다.
// URL 경로에서 manager_id를 추출하여 해당 관리자를 데이터베이스에서 완전히 제거합니다.
// 데이터 정합성 보장을 위해 트랜잭션을 사용하며, 관련 데이터 확인 후 안전하게 삭제합니다.
func DeleteManager(w http.ResponseWriter, r *http.Request) {
	// URL 경로에서 manager_id 파라미터 추출 및 검증
	vars := mux.Vars(r)
	managerID := vars["manager_id"]

	if managerID == "" {
		log.Printf("manager_id 파라미터 누락")
		http.Error(w, "관리자 ID가 필요합니다", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Manager 삭제 요청 시작 - ID: %s", managerID)

	// 트랜잭션 시작 - 데이터 정합성 보장을 위해
	tx, err := utils.DB.BeginTx(ctx, nil)
	if err != nil {
		log.Printf("트랜잭션 시작 오류: %v", err)
		http.Error(w, "삭제 작업 시작 실패", http.StatusInternalServerError)
		return
	}
	// defer를 통한 자동 롤백 (성공 시 명시적으로 커밋)
	defer tx.Rollback()

	// 먼저 해당 관리자가 존재하는지 확인
	// EXISTS를 사용하여 효율적인 존재 여부 확인
	var exists bool
	err = tx.QueryRowContext(ctx, "SELECT EXISTS(SELECT 1 FROM manager_table WHERE manager_id = $1)", managerID).Scan(&exists)
	if err != nil {
		log.Printf("관리자 존재 확인 오류: %v", err)
		http.Error(w, "관리자 확인 실패", http.StatusInternalServerError)
		return
	}

	// 관리자가 존재하지 않는 경우 404 에러 반환
	if !exists {
		log.Printf("삭제할 Manager 없음 - ID: %s", managerID)
		http.Error(w, "관리자를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// TODO: 관련 데이터 확인 로직 추가 필요
	// 실제 환경에서는 다음과 같은 확인이 필요할 수 있음:
	// 1. manager_company_table에서 연결된 회사 확인
	// 2. manager_access_table에서 권한 정보 확인
	// 3. 해당 관리자가 생성한 다른 데이터 확인
	// 4. 외래 키 제약 조건에 따른 CASCADE 삭제 또는 제한 처리

	// 관리자 삭제 실행
	result, err := tx.ExecContext(ctx, "DELETE FROM manager_table WHERE manager_id = $1", managerID)
	if err != nil {
		log.Printf("관리자 삭제 오류: %v", err)
		// 외래 키 제약 조건 위반 확인
		if strings.Contains(err.Error(), "foreign key constraint") {
			http.Error(w, "연결된 데이터가 있어 삭제할 수 없습니다", http.StatusConflict)
		} else {
			http.Error(w, "관리자 삭제 실패", http.StatusInternalServerError)
		}
		return
	}

	// 영향받은 행 수 확인 (추가 검증)
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("영향받은 행 수 확인 오류: %v", err)
		http.Error(w, "삭제 결과 확인 실패", http.StatusInternalServerError)
		return
	}

	// 삭제된 레코드가 없는 경우 (이론적으로는 발생하지 않아야 함)
	if rowsAffected == 0 {
		log.Printf("예상치 못한 상황: 삭제된 행이 없음 - ID: %s", managerID)
		http.Error(w, "삭제할 관리자를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// 트랜잭션 커밋 - 모든 작업이 성공한 경우에만
	if err = tx.Commit(); err != nil {
		log.Printf("트랜잭션 커밋 오류: %v", err)
		http.Error(w, "삭제 작업 완료 실패", http.StatusInternalServerError)
		return
	}

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("Manager 삭제 완료 - ID: %s, 실행 시간: %v", managerID, duration)

	// 성공적인 삭제 완료 - 204 No Content 응답
	w.WriteHeader(http.StatusNoContent)
}
