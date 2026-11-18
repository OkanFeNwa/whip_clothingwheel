@echo off
setlocal
echo ------------------------------------------------------------
echo  whip_clothingwheel - add the shirt glyph to whip_core
echo  Manual only: run this after every whip_core update.
echo ------------------------------------------------------------
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-core-shirt.ps1" -Manual
if errorlevel 1 (
    echo.
    echo Patch failed. Check the message above.
    pause
    exit /b 1
)
echo.
pause
