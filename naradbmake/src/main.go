package main

import (
	"database/sql"
	"log"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"

	// 로컬 패키지 경로 수정
	"naradbmake/src/tables"
	"naradbmake/src/util"
)

func init() {
	// 로그형식 날짜, 시간, 파일명(짧은 형식)과 라인 번호 표시
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	// UTF-8 출력을 위한 설정
	log.SetOutput(os.Stdout)
}

func main() {
	// 1. 기본 postgres DB로 연결
	defaultConnStr := "host=localhost dbname=postgres user=postgres password='postgres' sslmode=disable"
	defaultDB, err := sql.Open("postgres", defaultConnStr)
	if err != nil {
		log.Fatalf("기본 DB 연결 오류: %v", err)
	}
	defer defaultDB.Close()

	if err = defaultDB.Ping(); err != nil {
		log.Fatalf("기본 DB 연결 테스트 실패: %v", err)
	}
	log.Println("기본 DB 연결 성공")

	// DB 존재 여부 확인
	var exists bool
	err = defaultDB.QueryRow("SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = 'naradb')").Scan(&exists)
	if err != nil {
		log.Fatalf("DB 존재 여부 확인 오류: %v", err)
	}

	// naradbuser 사용자 존재 여부 확인
	var userExists bool
	err = defaultDB.QueryRow("SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = 'naradbuser')").Scan(&userExists)
	if err != nil {
		log.Fatalf("사용자 존재 여부 확인 오류: %v", err)
	}

	// 사용자가 존재하지 않으면 생성
	if !userExists {
		log.Println("naradbuser 사용자가 존재하지 않아 새로 생성합니다.")
		_, err = defaultDB.Exec("CREATE USER naradbuser WITH PASSWORD 'nara323399!!'")
		if err != nil {
			log.Fatalf("사용자 생성 오류: %v", err)
		}
		log.Println("naradbuser 사용자가 생성되었습니다.")
	}

	// DB가 존재하지 않으면 생성
	if !exists {
		log.Println("naradb 데이터베이스가 존재하지 않아 새로 생성합니다.")
		_, err = defaultDB.Exec("CREATE DATABASE naradb")
		if err != nil {
			log.Fatalf("DB 생성 오류: %v", err)
		}

		// 중요: 사용자에게 권한 부여
		// CONNECT: 데이터베이스에 연결할 수 있는 권한
		// CREATE: 데이터베이스 내에 새 스키마를 생성할 수 있는 권한
		// TEMPORARY: 임시 테이블을 생성할 수 있는 권한
		_, err = defaultDB.Exec("GRANT ALL PRIVILEGES ON DATABASE naradb TO naradbuser")
		if err != nil {
			log.Fatalf("권한 부여 오류: %v", err)
		}

		log.Println("naradb 데이터베이스가 생성되었고, 권한이 부여되었습니다.")
	}

	// naradb에 연결하여 스키마 권한 부여
	naradbConnStr := "host=localhost dbname=naradb user=postgres password='postgres' sslmode=disable"
	naraDB, err := sql.Open("postgres", naradbConnStr)
	if err != nil {
		log.Fatalf("naradb 연결 오류: %v", err)
	}
	defer naraDB.Close()

	if err = naraDB.Ping(); err != nil {
		log.Fatalf("naradb 연결 테스트 실패: %v", err)
	}

	// public 스키마에 대한 권한 부여
	_, err = naraDB.Exec("GRANT ALL PRIVILEGES ON SCHEMA public TO naradbuser")
	if err != nil {
		log.Printf("public 스키마 권한 부여 오류 (무시 가능): %v", err)
	}

	// 앞으로 생성될 테이블에도 권한 적용
	_, err = naraDB.Exec("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO naradbuser")
	if err != nil {
		log.Printf("앞으로 생성될 테이블 권한 부여 오류 (무시 가능): %v", err)
	}

	naraDB.Close()

	// 기본 DB 연결 닫기
	defaultDB.Close()

	// 프로젝트 루트 디렉토리 찾기
	rootDir, err := util.FindProjectRoot()
	if err != nil {
		log.Fatalf("프로젝트 루트 디렉토리를 찾을 수 없습니다: %v", err)
	}

	// .env 파일 경로
	envPath := filepath.Join(rootDir, ".env")
	log.Printf("환경 변수 파일 경로: %s", envPath)

	// 환경 변수 로드
	if err := godotenv.Overload(envPath); err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	//DATABASE_URL 읽기
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		log.Fatal("DATABASE_URL 환경변수가 설정되어 있지 않습니다.")
	}

	//naraDB 연결
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("DB 연결 오류: %v", err)
	}
	defer db.Close()

	// 연결 테스트
	if err = db.Ping(); err != nil {
		log.Fatalf("naradb DB 연결 테스트 실패: %v", err)
	}

	//========================================================================
	// 테이블 생성 (의존성 순서대로)
	
	// 1. 독립 테이블들 먼저 생성
	err = tables.CreateManagerTable(db)
	if err != nil {
		log.Fatalf("manager_table 생성 오류: %v", err)
	}
	
	err = tables.CreateCompanyTable(db)
	if err != nil {
		log.Fatalf("company_table 생성 오류: %v", err)
	}
	
	err = tables.CreateUserTable(db)
	if err != nil {
		log.Fatalf("user_table 생성 오류: %v", err)
	}
	
	err = tables.CreateRoomTable(db)
	if err != nil {
		log.Fatalf("room_table 생성 오류: %v", err)
	}
	
	err = tables.CreateSeatTable(db)
	if err != nil {
		log.Fatalf("seat_table 생성 오류: %v", err)
	}
	
	// 2. 의존성이 있는 테이블들 나중에 생성
	err = tables.CreateCompanyImageTable(db)
	if err != nil {
		log.Fatalf("company_image_table 생성 오류: %v", err)
	}
	
	err = tables.CreateManagerAccessTable(db)
	if err != nil {
		log.Fatalf("manager_access_table 생성 오류: %v", err)
	}

	log.Println("naradb 생성이 완료되었습니다.")

	//------------------------------------------------------------------------
	// 사용자에게 권한 부여.  테이블에 대한 권한 (SELECT, INSERT, UPDATE, DELETE 등)
	// <주의> (테이블이 존재해야 함. 테이블 생성후 해야함.)
	_, err = db.Exec("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO naradbuser")
	if err != nil {
		log.Fatalf("모든 테이블 권한 부여 오류: %v", err)
	}
	log.Println("naradbuser에게 모든 테이블 권한이 부여되었습니다.")

}
