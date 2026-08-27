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

echo =============================================================================
echo HYDRA-UMC DSI (Flutter) - build.bat
echo Builds the Windows desktop target (dev-machine verification build - bumps
echo the app version, then runs flutter build windows^).
echo Copyright (C) 2026 JuanenRac (Electro Hobby 3D) ^<electrohobby3d@gmail.com^>
echo GPL-3.0 - see LICENSE
echo =============================================================================
echo.

setlocal
python "%~dp0bump_manifest_version.py"
if errorlevel 1 ( echo VERSION BUMP FAILED. & pause & exit /b 1 )

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] flutter was not found on PATH. Install the Flutter SDK
    echo         ^(https://docs.flutter.dev/get-started/install^) and add its
    echo         bin\ directory to PATH, then re-run this script.
    goto :fail
)

echo [1/3] flutter pub get
call flutter pub get
if errorlevel 1 goto :fail

echo [2/3] dart run tool/bump_version.dart
call dart run tool/bump_version.dart
if errorlevel 1 goto :fail

echo [3/3] flutter build windows
call flutter build windows
if errorlevel 1 goto :fail

echo.
echo Build complete: build\windows\x64\runner\Release\hydra_umc_dsi.exe
echo (Windows build - development/verification only. For the real CM5
echo  target, run build_linux.sh on an actual Linux machine.)
echo.
echo Build finished successfully.
pause
endlocal
exit /b 0

:fail
echo.
echo Build FAILED.
pause
endlocal
exit /b 1
