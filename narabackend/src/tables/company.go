// company.go
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

// Company 구조체는 company_table의 각 컬럼을 매핑합니다.
type Company struct {
	CompanyCode string    `json:"company_code" db:"company_code"`
	CompanyName string    `json:"company_name" db:"company_name"`
	Phone       string    `json:"phone" db:"phone"`
	Address     string    `json:"address" db:"address"`
	Email       string    `json:"email" db:"email"`
	Website     string    `json:"website" db:"website"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// CompanyRequest는 요청 시 사용되는 구조체입니다.
type CompanyRequest struct {
	CompanyCode string `json:"company_code"`
	CompanyName string `json:"company_name"`
	Phone       string `json:"phone"`
	Address     string `json:"address"`
	Email       string `json:"email"`
	Website     string `json:"website"`
}

// RegisterCompanyRoutes는 company_table 관련 엔드포인트를 등록합니다.
func RegisterCompanyRoutes(r *mux.Router) {
	r.HandleFunc("/companies", GetCompanies).Methods("GET")
	r.HandleFunc("/companies/{company_code}", GetCompany).Methods("GET")
	r.HandleFunc("/companies", CreateCompany).Methods("POST")
	r.HandleFunc("/companies/{company_code}", UpdateCompany).Methods("PUT", "PATCH")
	r.HandleFunc("/companies/{company_code}", DeleteCompany).Methods("DELETE")
}

// GetCompanies: "X-Fields" 헤더에 지정된 필드만 조회하거나 전체 필드를 조회합니다.
// URL 쿼리 파라미터를 통해 필터링과 검색 기능도 지원합니다.
func GetCompanies(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 허용된 필드 목록 정의
	allowedFields := []string{
		"company_code", "company_name", "phone", "address", "email", "website", "created_at", "updated_at",
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

	// 필터링 조건 처리
	filters := []string{}
	args := []interface{}{}
	paramIdx := 1

	// 지원하는 필터 파라미터 목록
	filterParams := map[string]string{
		"company_code": "company_code",
	}

	// URL 쿼리 파라미터에서 필터 조건 추출
	for param, dbField := range filterParams {
		if value := r.URL.Query().Get(param); value != "" {
			filters = append(filters, fmt.Sprintf("%s = $%d", dbField, paramIdx))
			args = append(args, value)
			paramIdx++
		}
	}

	// 검색 기능 추가 (company_name에 대한 부분 검색)
	if search := r.URL.Query().Get("search"); search != "" {
		filters = append(filters, fmt.Sprintf("company_name LIKE $%d", paramIdx))
		args = append(args, "%"+search+"%")
		paramIdx++
	}

	// 쿼리 구성
	query := "SELECT " + strings.Join(fields, ", ") + " FROM company_table"
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
			"company_code": true,
			"company_name": true,
			"created_at":   true,
		}

		if allowedSortFields[sort] {
			query += fmt.Sprintf(" ORDER BY %s %s", sort, direction)
		}
	} else {
		// 기본 정렬은 company_code 기준
		query += " ORDER BY company_code ASC"
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

// GetCompany: URL 경로에서 company_code를 추출하여 특정 회사 정보를 조회합니다.
// 회사 코드로 직접 조회하며 인라인 쿼리를 실행합니다.
func GetCompany(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 경로에서 company_code 파라미터 추출 및 검증
	vars := mux.Vars(r)
	companyCode := vars["company_code"]
	if companyCode == "" {
		http.Error(w, "잘못된 company_code", http.StatusBadRequest)
		return
	}

	// 회사 데이터 구조체
	var company Company
	
	// 인라인 쿼리 실행 및 체인 스타일 스캔 연산으로 성능 최적화
	err := utils.DB.QueryRowContext(ctx, `
		SELECT company_code, company_name, phone, address, email, website, created_at, updated_at
		FROM company_table WHERE company_code = $1`, companyCode).
		Scan(&company.CompanyCode, &company.CompanyName, &company.Phone, &company.Address,
			&company.Email, &company.Website, &company.CreatedAt, &company.UpdatedAt)
	
	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Company를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	
	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(company)
}

// CreateCompany: 새로운 회사 정보를 생성합니다.
// JSON 요청 본문을 파싱하여 데이터베이스에 INSERT 연산을 수행합니다.
func CreateCompany(w http.ResponseWriter, r *http.Request) {
	// JSON 요청 본문 파싱
	var req CompanyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 디코딩 오류: %v", err)
		http.Error(w, "잘못된 JSON 형식", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증
	if req.CompanyCode == "" || req.CompanyName == "" {
		http.Error(w, "필수 필드가 누락되었습니다 (company_code, company_name)", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("Company 생성 요청 시작: %+v", req)

	// INSERT 쿼리 정의 및 RETURNING을 통한 생성된 데이터 반환
	query := `
		INSERT INTO company_table (
			company_code, company_name, phone, address, email, website, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
		)
		RETURNING company_code, company_name, phone, address, email, website, created_at, updated_at
	`

	// 새 회사 구조체 및 쿼리 실행
	var company Company
	err := utils.DB.QueryRowContext(ctx, query,
		req.CompanyCode, req.CompanyName, req.Phone, req.Address, req.Email, req.Website,
	).Scan(&company.CompanyCode, &company.CompanyName, &company.Phone, &company.Address,
		&company.Email, &company.Website, &company.CreatedAt, &company.UpdatedAt)

	// 실행 시간 및 오류 로깅
	duration := time.Since(startTime)
	log.Printf("쿼리 실행 시간: %v", duration)

	if err != nil {
		log.Printf("회사 생성 오류: %v", err)
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique constraint") {
			http.Error(w, "이미 존재하는 회사 코드입니다", http.StatusConflict)
		} else {
			http.Error(w, "회사 생성 실패", http.StatusInternalServerError)
		}
		return
	}

	// 201 Created 상태로 생성된 데이터 반환
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(company)
}

// UpdateCompany: 기존 회사 정보를 업데이트합니다.
// URL 경로의 company_code와 JSON 요청 본문의 데이터를 사용하여 UPDATE 연산을 수행합니다.
func UpdateCompany(w http.ResponseWriter, r *http.Request) {
	// URL 경로에서 company_code 파라미터 추출 및 검증
	vars := mux.Vars(r)
	companyCode := vars["company_code"]

	if companyCode == "" {
		http.Error(w, "회사 코드가 필요합니다", http.StatusBadRequest)
		return
	}

	// JSON 요청 본문 파싱
	var req CompanyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("JSON 디코딩 오류: %v", err)
		http.Error(w, "잘못된 JSON 형식", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// UPDATE 쿼리 정의 - COALESCE와 NULLIF를 사용한 선택적 업데이트
	query := `
		UPDATE company_table SET
			company_name = COALESCE(NULLIF($2, ''), company_name),
			phone = COALESCE(NULLIF($3, ''), phone),
			address = COALESCE(NULLIF($4, ''), address),
			email = COALESCE(NULLIF($5, ''), email),
			website = COALESCE(NULLIF($6, ''), website),
			updated_at = CURRENT_TIMESTAMP
		WHERE company_code = $1
		RETURNING company_code, company_name, phone, address, email, website, created_at, updated_at
	`

	// 업데이트된 회사 구조체 및 쿼리 실행
	var company Company
	err := utils.DB.QueryRowContext(ctx, query,
		companyCode, req.CompanyName, req.Phone, req.Address, req.Email, req.Website,
	).Scan(&company.CompanyCode, &company.CompanyName, &company.Phone, &company.Address,
		&company.Email, &company.Website, &company.CreatedAt, &company.UpdatedAt)

	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "회사를 찾을 수 없습니다", http.StatusNotFound)
		} else {
			log.Printf("회사 업데이트 오류: %v", err)
			http.Error(w, "회사 업데이트 실패", http.StatusInternalServerError)
		}
		return
	}

	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(company)
}

// DeleteCompany: 특정 회사를 삭제합니다.
// URL 경로에서 company_code를 추출하여 해당 회사 레코드를 트랜잭션으로 안전하게 삭제합니다.
func DeleteCompany(w http.ResponseWriter, r *http.Request) {
	// URL 경로에서 company_code 파라미터 추출 및 검증
	vars := mux.Vars(r)
	companyCode := vars["company_code"]

	if companyCode == "" {
		http.Error(w, "회사 코드가 필요합니다", http.StatusBadRequest)
		return
	}

	// 요청 컨텍스트에 타임아웃 설정
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 트랜잭션 시작 - 데이터 일관성 보장
	tx, err := utils.DB.BeginTx(ctx, nil)
	if err != nil {
		log.Printf("트랜잭션 시작 오류: %v", err)
		http.Error(w, "삭제 작업 시작 실패", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// 먼저 해당 회사가 존재하는지 확인
	var exists bool
	err = tx.QueryRowContext(ctx, "SELECT EXISTS(SELECT 1 FROM company_table WHERE company_code = $1)", companyCode).Scan(&exists)
	if err != nil {
		log.Printf("회사 존재 확인 오류: %v", err)
		http.Error(w, "회사 확인 실패", http.StatusInternalServerError)
		return
	}

	if !exists {
		http.Error(w, "회사를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// 회사가 존재하지 않으면 404 반환
	if !exists {
		http.Error(w, "삭제할 회사를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// 회사 삭제 실행
	result, err := tx.ExecContext(ctx, "DELETE FROM company_table WHERE company_code = $1", companyCode)
	if err != nil {
		log.Printf("회사 삭제 오류: %v", err)
		http.Error(w, "회사 삭제 실패", http.StatusInternalServerError)
		return
	}

	// 영향받은 행 수 확인
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("영향받은 행 수 확인 오류: %v", err)
		http.Error(w, "삭제 결과 확인 실패", http.StatusInternalServerError)
		return
	}

	// 실제로 삭제된 행이 없는 경우 (이론적으로는 발생하지 않아야 함)
	if rowsAffected == 0 {
		http.Error(w, "삭제할 회사를 찾을 수 없습니다", http.StatusNotFound)
		return
	}

	// 트랜잭션 커밋으로 변경사항 확정
	if err = tx.Commit(); err != nil {
		log.Printf("트랜잭션 커밋 오류: %v", err)
		http.Error(w, "삭제 작업 완료 실패", http.StatusInternalServerError)
		return
	}

	// 204 No Content 상태 반환
	w.WriteHeader(http.StatusNoContent)
}
