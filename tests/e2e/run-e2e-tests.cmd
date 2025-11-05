@echo off
REM E2E Test Runner Script for E-Commerce Microservices
REM This script sets up port forwarding and runs Newman tests

echo ========================================
echo E2E Test Runner for E-Commerce Services
echo ========================================
echo.

REM Check if Newman is installed
where newman >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Newman is not installed!
    echo Please install Newman using: npm install -g newman
    echo.
    pause
    exit /b 1
)

echo [INFO] Newman is installed
echo.

REM Check if running in Kubernetes or Docker Compose
echo [INFO] Checking if services are accessible...
curl -s http://localhost:8080/app/actuator/health >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] API Gateway not accessible at http://localhost:8080/app
    echo.
    echo If running in Kubernetes, start port forwarding in a separate terminal:
    echo   kubectl port-forward -n ecommerce svc/api-gateway 8080:8080
    echo.
    echo If running with Docker Compose, ensure services are running:
    echo   docker-compose ps
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "%CONTINUE%"=="y" (
        echo [INFO] Aborted by user
        exit /b 0
    )
) else (
    echo [SUCCESS] API Gateway is accessible at http://localhost:8080/app
)
echo.

REM Create results directory
if not exist "test-results" mkdir test-results

echo ========================================
echo Running E2E Tests with Newman
echo ========================================
echo.

REM Run Newman with HTML report
newman run ecommerce-e2e-tests.postman_collection.json ^
    --reporters cli,htmlextra,json ^
    --reporter-htmlextra-export test-results\e2e-report.html ^
    --reporter-json-export test-results\e2e-results.json ^
    --bail

set TEST_RESULT=%ERRORLEVEL%

echo.
echo ========================================
if %TEST_RESULT% EQU 0 (
    echo [SUCCESS] All E2E tests passed!
    echo HTML Report: tests\e2e\test-results\e2e-report.html
) else (
    echo [FAILURE] Some E2E tests failed
    echo Check the report: tests\e2e\test-results\e2e-report.html
)
echo ========================================
echo.

REM Open HTML report if tests passed
if %TEST_RESULT% EQU 0 (
    set /p OPEN_REPORT="Open HTML report? (y/n): "
    if /i "%OPEN_REPORT%"=="y" (
        start test-results\e2e-report.html
    )
)

exit /b %TEST_RESULT%
