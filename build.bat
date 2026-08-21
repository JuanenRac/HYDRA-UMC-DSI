@echo off
REM =============================================================================
REM HYDRA-UMC DSI (Flutter) - build.bat
REM Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
REM GPL-3.0 - see LICENSE
REM
REM Builds the Windows desktop target - see build.sh's own header comment
REM for why this is the verification target on this machine and
REM build_linux.sh for the real CM5/Linux deployment target.
REM =============================================================================

setlocal

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] flutter was not found on PATH. Install the Flutter SDK
    echo         ^(https://docs.flutter.dev/get-started/install^) and add its
    echo         bin\ directory to PATH, then re-run this script.
    exit /b 1
)

echo [1/2] flutter pub get
call flutter pub get
if errorlevel 1 exit /b 1

echo [2/2] flutter build windows
call flutter build windows
if errorlevel 1 exit /b 1

echo.
echo Build complete: build\windows\x64\runner\Release\hydra_umc_dsi.exe
echo (Windows build - development/verification only. For the real CM5
echo  target, run build_linux.sh on an actual Linux machine.)
endlocal
