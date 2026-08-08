@echo off
setlocal EnableExtensions
title VendIA Diagnostic
cd /d "%~dp0"

echo.
echo ============================================================
echo   VENDIA DIAGNOSTIC
echo ============================================================
echo   Dossier : %CD%
echo.

echo [1] ollama.exe
if exist "ollama\ollama.exe" (echo     OK) else (echo     MANQUE - lance 1-INSTALLER.bat)

echo [2] models
if exist "ollama\models" (echo     OK) else (echo     MANQUE)

echo [3] Python
python --version 2>NUL
if errorlevel 1 (echo     MANQUE) else (echo     OK)

echo [4] Ollama port 11435
curl.exe -s -m 3 "http://127.0.0.1:11435/api/version"
if errorlevel 1 (echo. & echo     ARRETE) else (echo. & echo     OK)

echo [5] Gateway port 8765
curl.exe -s -m 3 "http://127.0.0.1:8765/vendia/health"
if errorlevel 1 (echo. & echo     ARRETE) else (echo. & echo     OK)

echo.
echo Si tout KO : 1-INSTALLER.bat puis 2-LANCER.bat
echo.
pause
exit /b 0