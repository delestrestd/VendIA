@echo off
setlocal EnableExtensions
title VendIA Installer
cd /d "%~dp0"

echo.
echo ============================================================
echo   VENDIA - ETAPE 1 / 2 - INSTALLER L IA
echo ============================================================
echo.
echo   Telecharge si besoin Ollama + modele moondream.
echo   Une seule fois. DataChef non touche (port 11434).
echo.
pause

set "VENDIA_PORT=11435"
set "OLLAMA_DIR=%CD%\ollama"
set "OLLAMA_MODELS=%OLLAMA_DIR%\models"
set "EXE=%OLLAMA_DIR%\ollama.exe"
set "ZIP=%CD%\_tmp_ollama.zip"
set "URL=https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"

echo.
echo [1/4] Dossiers...
if not exist "%OLLAMA_DIR%" mkdir "%OLLAMA_DIR%"
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"
echo       OK
echo.

echo [2/4] Binaire Ollama...
if exist "%EXE%" goto HAVE_EXE

echo       Telechargement Ollama...
curl.exe -L --retry 5 --retry-delay 2 -o "%ZIP%" "%URL%"
if errorlevel 1 goto FAIL_DL
if not exist "%ZIP%" goto FAIL_DL

echo       Extraction...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%OLLAMA_DIR%' -Force"
if exist "%ZIP%" del /q "%ZIP%"

if not exist "%EXE%" goto FAIL_EXE
echo       OK ollama.exe installe
goto HAVE_EXE

:FAIL_DL
echo [ERREUR] Telechargement rate. Verifie Internet.
pause
exit /b 1

:FAIL_EXE
echo [ERREUR] ollama.exe introuvable apres extraction.
pause
exit /b 1

:HAVE_EXE
echo       Pret : %EXE%
echo.

echo [3/4] Demarrage Ollama port %VENDIA_PORT%...
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
set "OLLAMA_MODELS=%OLLAMA_MODELS%"
set "OLLAMA_ORIGINS=*"

curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OL_UP

start "VendIA-Ollama" /MIN cmd /c "set OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%EXE%" serve"

set W=0
:WAIT_OL
timeout /t 1 /nobreak >NUL
curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OL_UP
set /a W+=1
if %W% LSS 45 goto WAIT_OL
echo [ERREUR] Ollama ne demarre pas.
pause
exit /b 1

:OL_UP
echo       OK Ollama en ligne
echo.

echo [4/4] Modele moondream...
"%EXE%" list 2>NUL | find /I "moondream" >NUL
if not errorlevel 1 goto HAVE_MODEL

echo       Pull moondream (environ 1.7 Go)...
"%EXE%" pull moondream
if errorlevel 1 (
  echo [ERREUR] pull moondream echoue.
  pause
  exit /b 1
)

:HAVE_MODEL
echo       OK moondream
echo.
echo Modeles :
"%EXE%" list
echo.
echo ============================================================
echo   ETAPE 1 TERMINEE - lance ensuite 2-LANCER.bat
echo ============================================================
pause
exit /b 0