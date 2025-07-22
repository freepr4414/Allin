package tables

import (
	"database/sql"
	"fmt"
	"log"
)

// CreateCompanyTable 좌석 관리 테이블 및 인덱스를 생성합니다.
// 함수 이름을 대문자로 시작하여 외부에서 접근 가능하게 만듭니다.
// 업체 정보 테이블
func CreateCompanyTable(db *sql.DB) error {
	log.Println("company_table 테이블을 생성합니다...")

	// 테이블 생성
	createBaseTableQuery := `CREATE TABLE IF NOT EXISTS company_table();`

	_, err := db.Exec(createBaseTableQuery)
	if err != nil {
		return err
	}
	log.Println("company_table 테이블 기본 구조 생성 완료")

	tableName := "company_table"
	alterPrefix := fmt.Sprintf("ALTER TABLE %s ADD COLUMN IF NOT EXISTS ", tableName)

	// 각 필드 개별 추가
	fieldDefinitions := []string{
		//회사 아이디, 나라스마트가 부여함. 중복 불가.
		"company_id TEXT NOT NULL PRIMARY KEY",
		// 관리자 아이디
		//"manager_id TEXT REFERENCES manager_table(manager_id)",
		// 업체명
		"business_name TEXT NOT NULL",
		// 지역번호(전화 지역번호)
		"region_number TEXT NOT NULL",
		// 사업자번호
		"business_number TEXT",
		// 대표자명
		"representative_name  TEXT",
		// 우편번호
		"postal_code TEXT",
		// 주소
		"address TEXT",
		// 주소 상세
		"address_detail TEXT",
		// 업태
		"business_type TEXT",
		// 종목
		"business_item TEXT",
		// 전화번호
		"phone TEXT",
		// 이메일
		"email TEXT",
		// 웹사이트 주소
		"website_url TEXT",
		// 블로그 주소
		"blog_url TEXT",
		// 로고 URL(파일 위치 주소)
		"logo_url TEXT",
		// 설명
		"description TEXT",
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
		log.Printf("company_table 필드 추가 진행 중: %d/%d 완료", i+1, len(fieldQueries))
		// }
	}

	// 인덱스 생성 쿼리 목록
	indexQueries := []string{
		`CREATE INDEX IF NOT EXISTS idx_business_name ON company_table (business_name);`,
		`CREATE INDEX IF NOT EXISTS idx_business_number ON company_table (business_number);`,
		`CREATE INDEX IF NOT EXISTS idx_representative_name ON company_table (representative_name);`,
	}

	// 인덱스 생성 실행
	for _, query := range indexQueries {
		_, err = db.Exec(query)
		if err != nil {
			return err
		}
	}

	log.Println("company_table 테이블과 인덱스가 성공적으로 생성되었습니다.")
	return nil
}
