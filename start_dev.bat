@echo off
echo ============================================
echo   SmartFocus Dev Server Startup
echo ============================================

:: 1. Start the FastAPI backend in a new window
echo [1/2] Starting FastAPI backend...
start "FastAPI Backend" cmd /k "cd /d C:\Users\SBS\Desktop\SmartFocus\backend && venv\Scripts\activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

:: Give uvicorn 3 seconds to start
timeout /t 3 /nobreak >nul

:: 2. Set up the ADB reverse tunnel (emulator localhost -> PC localhost)
echo [2/2] Setting up ADB tunnel (emulator port forwarding)...
"C:\Users\SBS\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000

if %errorlevel%==0 (
    echo.
    echo  Backend running at  : http://localhost:8000
    echo  Swagger UI          : http://localhost:8000/docs
    echo  Emulator tunnel     : ACTIVE (localhost:8000 in emulator = your PC backend)
    echo.
    echo  You can now run: flutter run
) else (
    echo.
    echo  WARNING: ADB tunnel failed. Make sure your emulator is running first,
    echo  then run this script again.
)

pause
