@echo off
REM =============================================================================
REM HYDRA-UMC DSI (Flutter) - run_dev.bat
REM Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
REM GPL-3.0 - see LICENSE
REM
REM Desktop simulation mode - see run_dev.sh's own header comment.
REM =============================================================================

echo =============================================================================
echo HYDRA-UMC DSI (Flutter) - run_dev.bat
echo Runs this app in desktop simulation mode against a real or local HYDRA-UMC
echo STUDIO server (hot-reload dev loop - stays running until closed).
echo Copyright (C) 2026 JuanenRac (Electro Hobby 3D) ^<electrohobby3d@gmail.com^>
echo GPL-3.0 - see LICENSE
echo =============================================================================
echo.

setlocal

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] flutter was not found on PATH. Install the Flutter SDK
    echo         ^(https://docs.flutter.dev/get-started/install^) and add its
    echo         bin\ directory to PATH, then re-run this script.
    pause
    exit /b 1
)

echo Starting HYDRA-UMC DSI in desktop simulation mode (-d windows)...
echo Point it at a real or local HYDRA-UMC STUDIO server from the login screen
echo (cd HYDRA-UMC-STUDIO ^&^& npm run dev, then 127.0.0.1:3000 here).
call flutter run -d windows
endlocal
