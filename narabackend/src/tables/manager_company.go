package tables

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"

	"narabackend/src/consts"
	"narabackend/src/utils"
)

// RegisterManagerCompanyRoutes는 manager_company_table 관련 REST API 엔드포인트를 등록합니다.
// 관리자와 회사 간의 연결 관계를 관리하는 CRUD 연산을 제공합니다.
// 각 엔드포인트는 HTTP 메서드와 URL 패턴에 따라 적절한 핸들러 함수로 라우팅됩니다.
func RegisterManagerCompanyRoutes(r *mux.Router) {
	r.HandleFunc("/manager-company", GetManagerCompanies).Methods("GET")
	r.HandleFunc("/manager-company/{id}", GetManagerCompany).Methods("GET")
	r.HandleFunc("/manager-company", CreateManagerCompany).Methods("POST")
	r.HandleFunc("/manager-company/{id}", UpdateManagerCompany).Methods("PUT")
	r.HandleFunc("/manager-company/{id}", DeleteManagerCompany).Methods("DELETE")
}

// ManagerCompany 구조체는 manager_company_table의 각 컬럼을 Go 구조체로 매핑합니다.
// 관리자와 회사 간의 연결 관계 및 권한 정보를 나타냅니다.
// JSON 태그는 API 응답 시 필드명을 정의하고, db 태그는 데이터베이스 컬럼명을 정의합니다.
type ManagerCompany struct {
	SerialNumber int       `json:"serial_number" db:"serial_number"` // 고유 식별자 (자동 증가)
	ManagerID    string    `json:"manager_id" db:"manager_id"`       // 관리자 ID (외래 키)
	CompanyCode  string    `json:"company_code" db:"company_code"`   // 회사 코드 (외래 키)
	AssignedAt   time.Time `json:"assigned_at" db:"assigned_at"`     // 배정 시간 (자동 설정)
	Status       string    `json:"status" db:"status"`               // 연결 상태 (활성/비활성 등)
	CreatedAt    time.Time `json:"created_at" db:"created_at"`       // 생성 시간 (자동 설정)
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`       // 수정 시간 (자동 갱신)
}

// ManagerCompanyRequest는 HTTP 요청 시 사용되는 구조체입니다.
// 생성(POST) 및 업데이트(PUT) 연산에서 클라이언트가 전송하는 데이터를 파싱하는 데 사용됩니다.
// 자동 생성되는 필드(serial_number, 시간 관련 필드)는 포함하지 않습니다.
type ManagerCompanyRequest struct {
	ManagerID   string `json:"manager_id"`   // 관리자 ID (필수)
	CompanyCode string `json:"company_code"` // 회사 코드 (필수)
	Status      string `json:"status"`       // 연결 상태 (선택적)
}

// GetManagerCompanies: "X-Fields" 헤더에 지정된 필드만 조회하거나 전체 필드를 조회합니다.
// URL 쿼리 파라미터를 통해 필터링, 검색, 정렬 기능도 지원합니다.
// 성능 최적화를 위해 strconv.Atoi와 인라인 쿼리를 사용합니다.
func GetManagerCompanies(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 허용된 필드 목록 정의 - 보안을 위해 화이트리스트 방식 사용
	// 관리자-회사 연결 테이블의 모든 컬럼을 포함
	allowedFields := []string{
		"serial_number", "manager_id", "company_code", "assigned_at", "status", "created_at", "updated_at",
	}

	// X-Fields 헤더를 통한 필드 선택 처리
	// 클라이언트가 필요한 필드만 요청하여 네트워크 트래픽 최적화
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
		// 선택된 필드가 없으면 전체 필드 사용
		if len(fields) == 0 {
			fields = allowedFields
		}
	} else {
		// X-Fields 헤더가 없으면 전체 필드 사용
		fields = allowedFields
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerCompany 목록 조회 요청 시작")

	// 쿼리 구성 및 실행 - 동적 필드 선택으로 성능 최적화
	query := "SELECT " + strings.Join(fields, ", ") + " FROM manager_company_table"
	
	// 쿼리 로깅
	log.Printf("실행 쿼리: %s", query)
	
	// 데이터베이스 쿼리 실행
	rows, err := utils.DB.QueryContext(ctx, query)
	if err != nil {
		log.Printf("데이터베이스 쿼리 오류: %v", err)
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

// GetManagerCompany: URL 경로에서 id를 추출하여 특정 관리자-회사 연결 정보를 조회합니다.
// strconv.Atoi를 사용하여 문자열을 정수로 변환하고 인라인 쿼리를 실행합니다.
// 성능 최적화를 위해 체인 스타일 스캔 연산을 사용합니다.
func GetManagerCompany(w http.ResponseWriter, r *http.Request) {
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
	log.Printf("ManagerCompany 단일 조회 요청 시작 - ID: %d", id)

	// 관리자-회사 연결 정보 데이터 구조체
	var managerCompany ManagerCompany
	
	// 인라인 쿼리 실행 및 체인 스타일 스캔 연산으로 성능 최적화
	// 모든 필드를 한 번에 조회하여 네트워크 왕복 최소화
	err = utils.DB.QueryRowContext(ctx, `
		SELECT serial_number, manager_id, company_code, assigned_at, status, created_at, updated_at
		FROM manager_company_table WHERE serial_number = $1`, id).
		Scan(&managerCompany.SerialNumber, &managerCompany.ManagerID, &managerCompany.CompanyCode,
			&managerCompany.AssignedAt, &managerCompany.Status, &managerCompany.CreatedAt, &managerCompany.UpdatedAt)
	
	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("단일 조회 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("ManagerCompany 없음 - ID: %d", id)
			http.Error(w, "ManagerCompany를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			log.Printf("단일 조회 오류: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	
	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(managerCompany); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// CreateManagerCompany: 새로운 관리자-회사 연결 정보를 생성합니다.
// JSON 요청 본문을 파싱하여 데이터베이스에 INSERT 연산을 수행하고 생성된 결과를 반환합니다.
// RETURNING 절을 사용하여 생성된 완전한 레코드를 한 번에 반환합니다.
func CreateManagerCompany(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// JSON 요청 본문 파싱 및 검증
	var req ManagerCompanyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 파싱 오류: %v", err)
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증 - manager_id와 company_code는 반드시 필요
	if req.ManagerID == "" || req.CompanyCode == "" {
		log.Printf("필수 필드 누락 - ManagerID: %s, CompanyCode: %s", req.ManagerID, req.CompanyCode)
		http.Error(w, "필수 필드 누락", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerCompany 생성 요청 시작: %+v", req)

	// 새 관리자-회사 연결 정보를 저장할 구조체
	var managerCompany ManagerCompany

	// INSERT 쿼리 실행 및 RETURNING을 통한 생성된 데이터 반환
	// - CURRENT_TIMESTAMP로 자동 시간 설정
	// - 체인 스타일 스캔으로 성능 최적화
	err := utils.DB.QueryRowContext(ctx, `
		INSERT INTO manager_company_table (manager_id, company_code, assigned_at, status, created_at, updated_at)
		VALUES ($1, $2, CURRENT_TIMESTAMP, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING serial_number, manager_id, company_code, assigned_at, status, created_at, updated_at`,
		req.ManagerID, req.CompanyCode, req.Status).
		Scan(&managerCompany.SerialNumber, &managerCompany.ManagerID, &managerCompany.CompanyCode,
			&managerCompany.AssignedAt, &managerCompany.Status, &managerCompany.CreatedAt, &managerCompany.UpdatedAt)

	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("생성 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 중복 키 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		log.Printf("생성 오류: %v", err)
		if strings.Contains(err.Error(), "duplicate key") {
			http.Error(w, "이미 존재하는 관리자-회사 연결입니다", http.StatusBadRequest)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// 201 Created 상태로 생성된 데이터 반환
	log.Printf("ManagerCompany 생성 완료 - ID: %d", managerCompany.SerialNumber)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(managerCompany); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// UpdateManagerCompany: 기존 관리자-회사 연결 정보를 업데이트합니다.
// URL 경로의 ID와 JSON 요청 본문의 데이터를 사용하여 UPDATE 연산을 수행합니다.
// COALESCE와 NULLIF를 사용하여 선택적 업데이트를 지원합니다.
func UpdateManagerCompany(w http.ResponseWriter, r *http.Request) {
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

	// JSON 요청 본문 파싱 및 검증
	var req ManagerCompanyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 파싱 오류: %v", err)
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("ManagerCompany 업데이트 요청 시작 - ID: %d, 데이터: %+v", id, req)

	// 업데이트된 데이터를 저장할 구조체
	var managerCompany ManagerCompany

	// UPDATE 쿼리 실행 - COALESCE와 NULLIF를 사용한 선택적 업데이트
	// - COALESCE(NULLIF(value, ''), current_value): 빈 문자열이 아닌 경우만 업데이트
	// - RETURNING으로 업데이트된 완전한 레코드 반환
	err = utils.DB.QueryRowContext(ctx, `
		UPDATE manager_company_table SET
			manager_id = COALESCE(NULLIF($2, ''), manager_id),
			company_code = COALESCE(NULLIF($3, ''), company_code),
			status = COALESCE(NULLIF($4, ''), status),
			updated_at = CURRENT_TIMESTAMP
		WHERE serial_number = $1
		RETURNING serial_number, manager_id, company_code, assigned_at, status, created_at, updated_at`,
		id, req.ManagerID, req.CompanyCode, req.Status).
		Scan(&managerCompany.SerialNumber, &managerCompany.ManagerID, &managerCompany.CompanyCode,
			&managerCompany.AssignedAt, &managerCompany.Status, &managerCompany.CreatedAt, &managerCompany.UpdatedAt)

	// 실행 시간 및 결과 로깅
	duration := time.Since(startTime)
	log.Printf("업데이트 쿼리 실행 시간: %v", duration)

	// 에러 처리 - 레코드 존재 여부 및 일반적인 데이터베이스 오류 구분
	if err != nil {
		log.Printf("업데이트 오류: %v", err)
		if err == sql.ErrNoRows {
			http.Error(w, "ManagerCompany를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// 성공적인 업데이트 결과 반환
	log.Printf("ManagerCompany 업데이트 완료 - ID: %d", id)
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(managerCompany); err != nil {
		log.Printf("JSON 인코딩 오류: %v", err)
		http.Error(w, "응답 생성 중 오류가 발생했습니다", http.StatusInternalServerError)
		return
	}
}

// DeleteManagerCompany: 특정 관리자-회사 연결 정보를 삭제합니다.
// URL 경로에서 ID를 추출하여 해당 레코드를 데이터베이스에서 완전히 제거합니다.
// 외래 키 제약 조건이 있는 경우 관련 레코드 존재 여부를 확인해야 합니다.
func DeleteManagerCompany(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정 (성능 최적화)
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
	log.Printf("ManagerCompany 삭제 요청 시작 - ID: %d", id)

	// DELETE 쿼리 실행
	result, err := utils.DB.ExecContext(ctx, "DELETE FROM manager_company_table WHERE serial_number = $1", id)
	
	// 실행 시간 로깅
	duration := time.Since(startTime)
	log.Printf("삭제 쿼리 실행 시간: %v", duration)

	// 데이터베이스 오류 처리
	if err != nil {
		log.Printf("삭제 쿼리 오류: %v", err)
		// 외래 키 제약 조건 위반 확인
		if strings.Contains(err.Error(), "foreign key constraint") {
			http.Error(w, "연결된 데이터가 있어 삭제할 수 없습니다", http.StatusConflict)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
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
		log.Printf("삭제할 ManagerCompany 없음 - ID: %d", id)
		http.Error(w, "ManagerCompany를 찾을 수 없습니다.", http.StatusNotFound)
		return
	}

	// 성공적인 삭제 완료 - 204 No Content 응답
	log.Printf("ManagerCompany 삭제 완료 - ID: %d", id)
	w.WriteHeader(http.StatusNoContent)
}