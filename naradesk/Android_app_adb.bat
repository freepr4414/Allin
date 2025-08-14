@echo off
chcp 65001 >nul
echo ==================================== 마우스 우클릭후 Run Code 로 실행
echo     Allin 프로젝트 자동 실행 스크립트
echo ====================================
echo.

echo [1/4] Android 디바이스 연결 확인...
adb devices
if %errorlevel% neq 0 (
    echo ❌ ADB가 설치되지 않았거나 PATH에 없습니다.
    pause
    exit /b 1
)

echo.
echo [2/4] ADB Reverse 터널링 설정...
adb reverse --remove-all >nul 2>&1
adb reverse tcp:8080 tcp:8080
if %errorlevel% neq 0 (
    echo ❌ ADB reverse 설정에 실패했습니다. 디바이스가 연결되어 있는지 확인하세요.
    pause
    exit /b 1
)

echo ✅ ADB reverse 터널링 설정 완료
adb reverse --list
