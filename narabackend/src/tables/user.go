// user.go
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

// User 구조체는 user_table의 각 컬럼을 매핑합니다.
type User struct {
	SerialNumber  int       `json:"serial_number" db:"serial_number"`
	Name          string    `json:"name" db:"name"`
	Password      string    `json:"password" db:"password"`
	Email         string    `json:"email" db:"email"`
	Phone         string    `json:"phone" db:"phone"`
	Address       string    `json:"address" db:"address"`
	BirthDate     string    `json:"birth_date" db:"birth_date"`
	Gender        int       `json:"gender" db:"gender"`
	TermsAgreed   bool      `json:"terms_agreed" db:"terms_agreed"`
	PrivacyAgreed bool      `json:"privacy_agreed" db:"privacy_agreed"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// UserRequest는 요청 시 사용되는 구조체입니다.
type UserRequest struct {
	Name          string `json:"name"`
	Password      string `json:"password"`
	Email         string `json:"email"`
	Phone         string `json:"phone"`
	Address       string `json:"address"`
	BirthDate     string `json:"birth_date"`
	Gender        int    `json:"gender"`
	TermsAgreed   bool   `json:"terms_agreed"`
	PrivacyAgreed bool   `json:"privacy_agreed"`
}

// RegisterUserRoutes는 user_table 관련 엔드포인트를 등록합니다.
func RegisterUserRoutes(r *mux.Router) {
	r.HandleFunc("/users", GetUsers).Methods("GET")
	r.HandleFunc("/users/{id}", GetUser).Methods("GET")
	r.HandleFunc("/users/email/{email}", GetUserByEmail).Methods("GET")
	r.HandleFunc("/users", CreateUser).Methods("POST")
	r.HandleFunc("/users/{id}", UpdateUser).Methods("PUT")
	r.HandleFunc("/users/{id}/password", UpdateUserPassword).Methods("PUT")
	r.HandleFunc("/users/{id}", DeleteUser).Methods("DELETE")
}

// GetUsers: "X-Fields" 헤더에 지정된 필드만 조회하거나 전체 필드를 조회합니다.
// URL 쿼리 파라미터를 통해 필터링 기능도 지원합니다.
func GetUsers(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	allowedFields := []string{
		"serial_number", "name", "password", "email", "phone", "address", "birth_date",
		"gender", "terms_agreed", "privacy_agreed", "created_at", "updated_at",
	}

	// 필드 선택 처리
	fieldsHeader := r.Header.Get("X-Fields")
	var fields []string
	if fieldsHeader != "" {
		requested := strings.Split(fieldsHeader, ",")
		allowedSet := make(map[string]bool)
		for _, f := range allowedFields {
			allowedSet[f] = true
		}
		for _, f := range requested {
			f = strings.TrimSpace(f)
			if allowedSet[f] {
				fields = append(fields, f)
			}
		}
		if len(fields) == 0 {
			fields = allowedFields
		}
	} else {
		fields = allowedFields
	}

	// 필터링 조건 처리
	filters := []string{}
	args := []interface{}{}
	paramIdx := 1

	// 지원하는 필터 파라미터 목록
	filterParams := map[string]string{
		"name":   "name",
		"email":  "email",
		"phone":  "phone",
		"gender": "gender",
	}

	// URL 쿼리 파라미터에서 필터 조건 추출
	for param, dbField := range filterParams {
		if value := r.URL.Query().Get(param); value != "" {
			filters = append(filters, fmt.Sprintf("%s = $%d", dbField, paramIdx))
			args = append(args, value)
			paramIdx++
		}
	}

	// 검색 기능 추가 (name, email에 대한 부분 검색)
	if search := r.URL.Query().Get("search"); search != "" {
		filters = append(filters, fmt.Sprintf("(name LIKE $%d OR email LIKE $%d)", paramIdx, paramIdx+1))
		args = append(args, "%"+search+"%", "%"+search+"%")
		paramIdx += 2
	}

	// 쿼리 구성
	query := "SELECT " + strings.Join(fields, ", ") + " FROM user_table"
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
			"name":          true,
			"email":         true,
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

// GetUser: 단일 user를 전체 필드로 조회합니다.
func GetUser(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// URL 파라미터에서 사용자 ID 추출
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	var user User
	err = utils.DB.QueryRowContext(ctx, `
		SELECT serial_number, name, password, email, phone, address, birth_date, gender, terms_agreed, privacy_agreed, created_at, updated_at
		FROM user_table WHERE serial_number = $1`, id).
		Scan(&user.SerialNumber, &user.Name, &user.Password, &user.Email, &user.Phone, &user.Address,
			&user.BirthDate, &user.Gender, &user.TermsAgreed, &user.PrivacyAgreed, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// GetUserByEmail: 이메일로 사용자를 조회합니다.
func GetUserByEmail(w http.ResponseWriter, r *http.Request) {
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	vars := mux.Vars(r)
	email := vars["email"]

	if email == "" {
		http.Error(w, "이메일이 필요합니다", http.StatusBadRequest)
		return
	}

	var user User
	err := utils.DB.QueryRowContext(ctx, `
		SELECT serial_number, name, password, email, phone, address, birth_date, gender, terms_agreed, privacy_agreed, created_at, updated_at
		FROM user_table WHERE email = $1`, email).
		Scan(&user.SerialNumber, &user.Name, &user.Password, &user.Email, &user.Phone, &user.Address,
			&user.BirthDate, &user.Gender, &user.TermsAgreed, &user.PrivacyAgreed, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// CreateUser: 새로운 user를 생성합니다.
func CreateUser(w http.ResponseWriter, r *http.Request) {
	// 요청 컨텍스트에 타임아웃 설정
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	// 요청 데이터 파싱
	var req UserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	// 필수 필드 검증
	if req.Name == "" || req.Email == "" || req.Password == "" {
		http.Error(w, "필수 필드 누락", http.StatusBadRequest)
		return
	}

	// 필수 약관 동의 확인
	if !req.TermsAgreed || !req.PrivacyAgreed {
		http.Error(w, "필수 약관 동의 필요", http.StatusBadRequest)
		return
	}

	// 새 사용자 구조체
	var user User
	
	// 시작 시간 로깅
	startTime := time.Now()
	log.Printf("User 생성 요청 시작: %+v", req)
	
	err := utils.DB.QueryRowContext(ctx, `
		INSERT INTO user_table (name, password, email, phone, address, birth_date, gender, terms_agreed, privacy_agreed, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING serial_number, name, password, email, phone, address, birth_date, gender, terms_agreed, privacy_agreed, created_at, updated_at`,
		req.Name, req.Password, req.Email, req.Phone, req.Address, req.BirthDate, req.Gender, req.TermsAgreed, req.PrivacyAgreed).
		Scan(&user.SerialNumber, &user.Name, &user.Password, &user.Email, &user.Phone, &user.Address,
			&user.BirthDate, &user.Gender, &user.TermsAgreed, &user.PrivacyAgreed, &user.CreatedAt, &user.UpdatedAt)

	// 실행 시간 및 오류 로깅
	duration := time.Since(startTime)
	log.Printf("쿼리 실행 시간: %v", duration)

	if err != nil {
		log.Printf("DB 오류: %v", err)
		if strings.Contains(err.Error(), "duplicate key") {
			http.Error(w, "이미 존재하는 이메일입니다", http.StatusBadRequest)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

// UpdateUser: user를 업데이트합니다.
func UpdateUser(w http.ResponseWriter, r *http.Request) {
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	var req UserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	var user User
	err = utils.DB.QueryRowContext(ctx, `
		UPDATE user_table SET
			name = COALESCE(NULLIF($2, ''), name),
			email = COALESCE(NULLIF($3, ''), email),
			phone = COALESCE(NULLIF($4, ''), phone),
			address = COALESCE(NULLIF($5, ''), address),
			birth_date = COALESCE(NULLIF($6, ''), birth_date),
			gender = COALESCE($7, gender),
			updated_at = CURRENT_TIMESTAMP
		WHERE serial_number = $1
		RETURNING serial_number, name, password, email, phone, address, birth_date, gender, terms_agreed, privacy_agreed, created_at, updated_at`,
		id, req.Name, req.Email, req.Phone, req.Address, req.BirthDate, req.Gender).
		Scan(&user.SerialNumber, &user.Name, &user.Password, &user.Email, &user.Phone, &user.Address,
			&user.BirthDate, &user.Gender, &user.TermsAgreed, &user.PrivacyAgreed, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User를 찾을 수 없습니다.", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// UpdateUserPassword: 사용자 비밀번호를 업데이트합니다.
func UpdateUserPassword(w http.ResponseWriter, r *http.Request) {
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	var req struct {
		CurrentPassword string `json:"current_password"`
		NewPassword     string `json:"new_password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "잘못된 요청 데이터", http.StatusBadRequest)
		return
	}

	if req.NewPassword == "" {
		http.Error(w, "새 비밀번호가 필요합니다", http.StatusBadRequest)
		return
	}

	result, err := utils.DB.ExecContext(ctx, `
		UPDATE user_table SET password = $2, updated_at = CURRENT_TIMESTAMP 
		WHERE serial_number = $1 AND password = $3`,
		id, req.NewPassword, req.CurrentPassword)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		http.Error(w, "현재 비밀번호가 일치하지 않거나 사용자를 찾을 수 없습니다.", http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// DeleteUser: user를 삭제합니다.
func DeleteUser(w http.ResponseWriter, r *http.Request) {
	timeout := time.Duration(consts.DEFAULT_QUERY_TIMEOUT) * time.Second
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "잘못된 id", http.StatusBadRequest)
		return
	}

	result, err := utils.DB.ExecContext(ctx, "DELETE FROM user_table WHERE serial_number = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		http.Error(w, "User를 찾을 수 없습니다.", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
