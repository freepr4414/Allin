package tables

import (
	"database/sql"
	"fmt"
	"log"
)

// CreateManagerTable 좌석 관리 테이블 및 인덱스를 생성합니다.
// 함수 이름을 대문자로 시작하여 외부에서 접근 가능하게 만듭니다.
// 매니저 정보 테이블
func CreateManagerTable(db *sql.DB) error {
	log.Println("manager_table 테이블을 생성합니다...")

	// 테이블 생성
	createBaseTableQuery := `CREATE TABLE IF NOT EXISTS manager_table ();`

	_, err := db.Exec(createBaseTableQuery)
	if err != nil {
		return err
	}
	log.Println("manager_table 테이블 기본 구조 생성 완료")

	tableName := "manager_table"
	alterPrefix := fmt.Sprintf("ALTER TABLE %s ADD COLUMN IF NOT EXISTS ", tableName)

	// 각 필드 개별 추가
	fieldDefinitions := []string{
		// 매니저 아이디
		"manager_id TEXT NOT NULL PRIMARY KEY",
		// 비밀번호
		"password TEXT NOT NULL",
		// 이름
		"name TEXT NOT NULL",
		// 이메일
		"email TEXT NOT NULL",
		// super_admin(전체업체관리자)
		"super_admin BOOLEAN DEFAULT FALSE",
		// admin(복수업체관리자)
		"admin BOOLEAN DEFAULT FALSE",
		// 역할(점주=1, 관리자=2)
		"role SMALLINT DEFAULT 1",
		// 전화번호
		"phone TEXT",
		// 비밀번호 초기화 토큰
		"password_reset_token TEXT",
		// 비밀번호 초기화 만료 시간
		"password_reset_expires TIMESTAMP",
		// 비밀번호 변경 시간
		"last_password_change TIMESTAMP",
		// 메모
		"notes TEXT",
		// 생성일
		"created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
		// 수정일
		"updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
	}

	// 각 필드 추가 쿼리 생성
	fieldQueries := make([]string, len(fieldDefinitions))
	for i, field := range fieldDefinitions {
		fieldQueries[i] = alterPrefix + field + ";"
	}

	// 각 필드 추가 실행 및 진행 상황 로깅
	for i, query := range fieldQueries {
		_, err = db.Exec(query)
		if err != nil {
			return err
		}
		// if (i+1)%5 == 0 || i == len(fieldQueries)-1 {
		log.Printf("manager_table 필드 추가 진행 중: %d/%d 완료", i+1, len(fieldQueries))
		// }
	}

	// 인덱스 생성 쿼리 목록
	indexQueries := []string{
		`CREATE INDEX IF NOT EXISTS idx_business_name ON manager_table (business_name);`,
		`CREATE INDEX IF NOT EXISTS idx_business_number ON manager_table (business_number);`,
		`CREATE INDEX IF NOT EXISTS idx_representative_name ON manager_table (representative_name);`,
	}

	// 인덱스 생성 실행
	for _, query := range indexQueries {
		_, err = db.Exec(query)
		if err != nil {
			return err
		}
	}

	log.Println("manager_table 테이블과 인덱스가 성공적으로 생성되었습니다.")
	return nil
}
