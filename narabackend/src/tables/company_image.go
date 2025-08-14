// company_image.go
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

// CompanyImage 구조체는 company_image_table의 각 컬럼을 매핑합니다.
type CompanyImage struct {
	SerialNumber int       `json:"serial_number" db:"serial_number"`
	CompanyID    string    `json:"company_id" db:"company_id"`
	ImageName    string    `json:"image_name" db:"image_name"`
	ImagePath    string    `json:"image_path" db:"image_path"`
	ImageSize    int       `json:"image_size" db:"image_size"`
	ImageType    string    `json:"image_type" db:"image_type"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// CompanyImageRequest는 요청 시 사용되는 구조체입니다.
type CompanyImageRequest struct {
	CompanyID string `json:"company_id"`
	ImageName string `json:"image_name"`
	ImagePath string `json:"image_path"`
	ImageSize int    `json:"image_size"`
	ImageType string `json:"image_type"`
}

// RegisterCompanyImageRoutes는 company_image_table 관련 엔드포인트를 등록합니다.
func RegisterCompanyImageRoutes(r *mux.Router) {
	r.HandleFunc("/company-images", GetCompanyImages).Methods("GET")
	r.HandleFunc("/company-images/{id}", GetCompanyImage).Methods("GET")
	r.HandleFunc("/company-images", CreateCompanyImage).Methods("POST")
	r.HandleFunc("/company-images/{id}", UpdateCompanyImage).Methods("PUT")
	r.HandleFunc("/company-images/{id}", DeleteCompanyImage).Methods("DELETE")
}

// GetCompanyImages: "X-Fields" 헤더에 지정된 필드만 조회하거나 전체 필드를 조회합니다.
// URL 쿼리 파라미터를 통해 필터링 기능도 지원합니다.
func GetCompanyImages(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 허용된 필드 목록 정의
	allowedFields := []string{
		"serial_number", "company_id", "image_name", "image_path", "image_size", "image_type", "created_at", "updated_at",
	}

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
		"company_id":  "company_id",
		"image_type":  "image_type",
	}

	// URL 쿼리 파라미터에서 필터 조건 추출
	for param, dbField := range filterParams {
		if value := r.URL.Query().Get(param); value != "" {
			filters = append(filters, fmt.Sprintf("%s = $%d", dbField, paramIdx))
			args = append(args, value)
			paramIdx++
		}
	}

	// 검색 기능 추가 (image_name에 대한 부분 검색)
	if search := r.URL.Query().Get("search"); search != "" {
		filters = append(filters, fmt.Sprintf("image_name LIKE $%d", paramIdx))
		args = append(args, "%"+search+"%")
		paramIdx++
	}

	// 쿼리 구성
	query := "SELECT " + strings.Join(fields, ", ") + " FROM company_image_table"
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
			"image_name":    true,
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

// GetCompanyImage: URL 경로에서 id를 추출하여 특정 회사 이미지 정보를 조회합니다.
// strconv.Atoi를 사용하여 문자열을 정수로 변환하고 인라인 쿼리를 실행합니다.
func GetCompanyImage(w http.ResponseWriter, r *http.Request) {
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

	// 회사 이미지 데이터 구조체
	var companyImage CompanyImage
	
	// 인라인 쿼리 실행 및 체인 스타일 스캔 연산으로 성능 최적화
	err = utils.DB.QueryRowContext(ctx, `
		SELECT serial_number, company_id, image_name, image_path, image_size, image_type, created_at, updated_at
		FROM company_image_table WHERE serial_number = $1`, id).
		Scan(&companyImage.SerialNumber, &companyImage.CompanyID, &companyImage.ImageName,
			&companyImage.ImagePath, &companyImage.ImageSize, &companyImage.ImageType,
			&companyImage.CreatedAt, &companyImage.UpdatedAt)
	
	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "CompanyImage를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	
	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(companyImage)
}

// CreateCompanyImage: 새로운 회사 이미지 정보를 생성합니다.
// JSON 요청 본문을 파싱하여 데이터베이스에 INSERT 연산을 수행합니다.
func CreateCompanyImage(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// JSON 요청 본문 파싱
	var req CompanyImageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증
	if req.CompanyID == "" || req.ImageName == "" {
		http.Error(w, "필수 필드 누락", http.StatusBadRequest)
		return
	}

	// 새 회사 이미지 구조체
	var companyImage CompanyImage
	
	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("CompanyImage 생성 요청 시작: %+v", req)
	
	// INSERT 쿼리 실행 및 RETURNING을 통한 생성된 데이터 반환
	err := utils.DB.QueryRowContext(ctx, `
		INSERT INTO company_image_table (company_id, image_name, image_path, image_size, image_type, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING serial_number, company_id, image_name, image_path, image_size, image_type, created_at, updated_at`,
		req.CompanyID, req.ImageName, req.ImagePath, req.ImageSize, req.ImageType).
		Scan(&companyImage.SerialNumber, &companyImage.CompanyID, &companyImage.ImageName,
			&companyImage.ImagePath, &companyImage.ImageSize, &companyImage.ImageType,
			&companyImage.CreatedAt, &companyImage.UpdatedAt)

	// 실행 시간 및 오류 로깅
	duration := time.Since(startTime)
	log.Printf("쿼리 실행 시간: %v", duration)

	if err != nil {
		log.Printf("DB 오류: %v", err)
		if strings.Contains(err.Error(), "duplicate key") {
			http.Error(w, "이미 존재하는 회사 이미지입니다", http.StatusBadRequest)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// 201 Created 상태로 생성된 데이터 반환
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(companyImage)
}

// UpdateCompanyImage: 기존 회사 이미지 정보를 업데이트합니다.
// URL 경로의 ID와 JSON 요청 본문의 데이터를 사용하여 UPDATE 연산을 수행합니다.
func UpdateCompanyImage(w http.ResponseWriter, r *http.Request) {
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

	// JSON 요청 본문 파싱
	var req CompanyImageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 업데이트된 회사 이미지 구조체
	var companyImage CompanyImage
	
	// UPDATE 쿼리 실행 및 RETURNING을 통한 업데이트된 데이터 반환
	err = utils.DB.QueryRowContext(ctx, `
		UPDATE company_image_table SET
			company_id = COALESCE(NULLIF($2, ''), company_id),
			image_name = COALESCE(NULLIF($3, ''), image_name),
			image_path = COALESCE(NULLIF($4, ''), image_path),
			image_size = COALESCE($5, image_size),
			image_type = COALESCE(NULLIF($6, ''), image_type),
			updated_at = CURRENT_TIMESTAMP
		WHERE serial_number = $1
		RETURNING serial_number, company_id, image_name, image_path, image_size, image_type, created_at, updated_at`,
		id, req.CompanyID, req.ImageName, req.ImagePath, req.ImageSize, req.ImageType).
		Scan(&companyImage.SerialNumber, &companyImage.CompanyID, &companyImage.ImageName,
			&companyImage.ImagePath, &companyImage.ImageSize, &companyImage.ImageType,
			&companyImage.CreatedAt, &companyImage.UpdatedAt)

	// 에러 처리 - 레코드가 없는 경우와 일반적인 데이터베이스 오류 구분
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "CompanyImage를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	// JSON 응답 전송
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(companyImage)
}

// DeleteCompanyImage: 특정 회사 이미지를 삭제합니다.
// URL 경로에서 ID를 추출하여 해당 레코드를 데이터베이스에서 삭제합니다.
func DeleteCompanyImage(w http.ResponseWriter, r *http.Request) {
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

	// DELETE 쿼리 실행
	result, err := utils.DB.ExecContext(ctx, "DELETE FROM company_image_table WHERE serial_number = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 영향받은 행 수 확인
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 삭제된 레코드가 없는 경우 404 에러 반환
	if rowsAffected == 0 {
		http.Error(w, "CompanyImage를 찾을 수 없습니다.", http.StatusNotFound)
		return
	}

	// 204 No Content 상태 반환
	w.WriteHeader(http.StatusNoContent)
}
