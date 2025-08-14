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
		`CREATE INDEX IF NOT EXISTS idx_manager_id ON manager_table (manager_id);`,
	}

	// 인덱스 생성 실행
	for _, query := range indexQueries {
		_, err = db.Exec(query)
		if err != nil {
			return err
		}
	}

	log.Println("manager_table 테이블과 인덱스가 성공적으로 생성되었습니다.")

	// 기본 관리자 데이터 삽입
	log.Println("기본 관리자 데이터를 삽입합니다...")
	
	// 기본 관리자가 이미 존재하는지 확인
	var exists bool
	checkQuery := `SELECT EXISTS(SELECT 1 FROM manager_table WHERE manager_id = $1);`
	err = db.QueryRow(checkQuery, "qqqq").Scan(&exists)
	if err != nil {
		return fmt.Errorf("기본 관리자 존재 확인 중 오류: %v", err)
	}

	// 기본 관리자가 존재하지 않는 경우에만 삽입
	if !exists {
		insertQuery := `
			INSERT INTO manager_table (
				manager_id, 
				password, 
				name, 
				email, 
				super_admin, 
				admin, 
				role, 
				phone, 
				notes,
				created_at, 
				updated_at
			) VALUES (
				$1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
			);`

		_, err = db.Exec(insertQuery,
			"qqqq",                    // manager_id
			"1111",                    // password (실제 환경에서는 해시화 필요)
			"기본 관리자",              // name
			"admin@example.com",       // email
			true,                      // super_admin
			true,                      // admin
			2,                         // role (관리자=2)
			"010-0000-0000",          // phone
			"시스템 기본 관리자 계정",  // notes
		)

		if err != nil {
			return fmt.Errorf("기본 관리자 데이터 삽입 중 오류: %v", err)
		}

		log.Println("기본 관리자 데이터가 성공적으로 삽입되었습니다.")
		log.Println("  - manager_id: qqqq")
		log.Println("  - password: 1111")
		log.Println("  - name: 기본 관리자")
		log.Println("  - email: admin@example.com")
		log.Println("  - super_admin: true")
		log.Println("  - admin: true")
		log.Println("  - role: 2 (관리자)")
	} else {
		log.Println("기본 관리자(qqqq)가 이미 존재합니다. 건너뜁니다.")
	}

	return nil
}
