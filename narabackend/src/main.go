// main.go
package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"

	"narabackend/src/tables"
	"narabackend/src/utils"
)

// db는 전역 변수로 room.go 등에서 사용됩니다.
var db *sql.DB

func init() {
	// 로그형식 날짜, 시간, 파일명(짧은 형식)과 라인 번호 표시
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	// UTF-8 출력을 위한 설정
	log.SetOutput(os.Stdout)
}

func main() {
	var err error

	// 프로젝트 루트 디렉토리 찾기
	rootDir, err := utils.FindProjectRoot()
	if err != nil {
		log.Fatalf("프로젝트 루트 디렉토리를 찾을 수 없습니다: %v", err)
	}

	// .env 파일 경로
	envPath := filepath.Join(rootDir, ".env")
	log.Printf("환경 변수 파일 경로: %s", envPath)

	// .env 파일 로드
	if err := godotenv.Overload(envPath); err != nil {
		log.Printf("경고: .env 파일 로드 실패: %v", err)
		log.Println("시스템 환경 변수를 사용합니다.")
	}

	// .env 파일이 로드되었거나 시스템에 설정된 환경 변수 사용
	databaseURL := os.Getenv("DATABASE_URL")
	log.Printf("데이터베이스 URL: %s", utils.MaskSensitiveURL(databaseURL))
	if databaseURL == "" {
		log.Fatal("DATABASE_URL 환경변수가 설정되어 있지 않습니다.")
	}

	db, err = sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatalf("DB 연결 실패: %v", err)
	}
	defer db.Close()

	// DB 연결 풀링 최적화
	db.SetMaxOpenConns(50)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	// DB Ping 시 컨텍스트를 사용하여 타임아웃 적용
	log.Printf("🔗 [INIT] 데이터베이스 연결 테스트 시작...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		log.Fatalf("❌ [INIT] DB ping 실패: %v", err)
	}
<<<<<<< HEAD
	log.Printf("✅ [INIT] 데이터베이스 연결 성공!")
=======
	log.Printf("데이터베이스 연결 성공!")
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521

	// tables 패키지에 DB 연결 전달
	utils.DB = db
	log.Printf("utils.DB에 데이터베이스 연결 설정 완료")

	// tables 패키지에 작업 큐 함수 전달
	utils.SetEnqueueJobFunc(utils.EnqueueJob)

	// 비동기 작업 큐(worker) 시작
	utils.StartJobWorker()

	// 라우터 초기화
	r := mux.NewRouter()
	// room_table 관련 라우트는 tables/room.go에서 등록합니다.
	tables.RegisterRoomRoutes(r)

	// seat_table 관련 라우트 등록 필요
	tables.RegisterSeatRoutes(r)

	// company_table 관련 라우트 등록
	tables.RegisterCompanyRoutes(r)

	// manager_table 관련 라우트 등록
	log.Printf("🛠️  [INIT] Manager 라우트 등록 중...")
	tables.RegisterManagerRoutes(r)
	log.Printf("Manager 라우트 등록 완료")

	// user_table 관련 라우트 등록
	tables.RegisterUserRoutes(r)

	// company_image_table 관련 라우트 등록
	tables.RegisterCompanyImageRoutes(r)

	// manager_access_table 관련 라우트 등록
	tables.RegisterManagerAccessRoutes(r)

	// manager_company_table 관련 라우트 등록
	tables.RegisterManagerCompanyRoutes(r)

	// 로깅 미들웨어와 CORS 미들웨어를 함께 적용
	handler := utils.LoggingMiddleware(utils.CorsMiddleware(r))
	http.Handle("/", handler)

	log.Printf("🚀 [INIT] 서버가 :8080 포트에서 실행 중입니다.")
	log.Printf("📡 [INIT] API 엔드포인트:")
	log.Printf("   - GET /managers (매니저 목록 조회)")
	log.Printf("   - GET /managers/{id} (특정 매니저 조회)")
	log.Printf("🔄 [INIT] 요청 대기 중...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
