@echo off
setlocal
echo ============================================
echo   SmartFocus Dev Server Startup
echo ============================================

set "ROOT=C:\Users\SBS\Desktop\SmartFocus"
set "BACKEND_DIR=%ROOT%\backend"
set "PYTHON_EXE=%BACKEND_DIR%\venv\Scripts\python.exe"
set "ADB_EXE=C:\Users\SBS\AppData\Local\Android\Sdk\platform-tools\adb.exe"

:: 1. Start the FastAPI backend in a new window
echo [1/3] Starting FastAPI backend...
start "FastAPI Backend" cmd /k "cd /d %BACKEND_DIR% && %PYTHON_EXE% -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

:: Give uvicorn a few seconds to start
echo       Waiting for uvicorn to start...
timeout /t 4 /nobreak >nul

:: 2. Verify backend is up
echo [2/3] Checking backend health...
curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel%==0 (
    echo       Backend is UP.
) else (
    echo       WARNING: Backend may not be ready yet. Continuing anyway...
)

:: 3. Set up ADB reverse tunnel with retry logic
echo [3/3] Setting up ADB tunnel...

if not exist "%ADB_EXE%" (
    echo.
    echo  WARNING: adb.exe was not found at:
    echo  %ADB_EXE%
    echo  Please install Android SDK platform-tools.
    goto :done
)

"%ADB_EXE%" start-server >nul 2>&1

:: Wait for emulator with a timeout (max 60 seconds)
set RETRIES=0
set MAX_RETRIES=12

:wait_emulator
"%ADB_EXE%" devices | findstr /R "emulator device$" >nul 2>&1
if %errorlevel%==0 goto :emulator_found

set /a RETRIES+=1
if %RETRIES% GEQ %MAX_RETRIES% (
    echo.
    echo  WARNING: No emulator detected after 60 seconds.
    echo  Please start your Android emulator first, then run this script again.
    goto :done
)

echo       Waiting for emulator... (%RETRIES%/%MAX_RETRIES%)
timeout /t 5 /nobreak >nul
goto :wait_emulator

:emulator_found
echo       Emulator detected!

:: Small delay to let emulator fully boot
timeout /t 2 /nobreak >nul

:: Remove old reverse and set new one
"%ADB_EXE%" reverse --remove-all >nul 2>&1
"%ADB_EXE%" reverse tcp:8000 tcp:8000

if %errorlevel%==0 (
    echo.
    echo  ============================================
    echo   ALL SYSTEMS GO!
    echo  ============================================
    echo  Backend listening on : http://0.0.0.0:8000
    echo  Emulator backend     : http://localhost:8000
    echo  Swagger UI           : http://localhost:8000/docs
    echo  ADB reverse          : ACTIVE
    echo  ============================================
    echo.
    echo  You can now run the Flutter app on the emulator.
) else (
    echo.
    echo  WARNING: ADB reverse failed.
    echo  Make sure the emulator is fully booted, then try again.
)

:done
echo.
pause
