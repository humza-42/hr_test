@echo off
echo ========================================
echo HR System Mock Server
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if node_modules exists
if not exist "node_modules" (
    echo [INFO] Installing dependencies...
    call npm install
    echo.
)

echo [INFO] Starting JSON Server on port 5000...
echo [INFO] Mock API will be available at: http://localhost:5000/api
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Start JSON Server
call npm start
