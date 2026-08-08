@echo off
setlocal EnableExtensions
title VendIA Lancer
cd /d "%~dp0"

echo.
echo ============================================================
echo   VENDIA - ETAPE 2 / 2 - LANCER LE SERVEUR
echo ============================================================
echo.

set "VENDIA_PORT=11435"
set "WEB_PORT=8765"
set "EXE=%CD%\ollama\ollama.exe"
set "OLLAMA_MODELS=%CD%\ollama\models"
set "LAN_IP=127.0.0.1"

if not exist "%EXE%" goto NO_EXE

python --version >NUL 2>&1
if errorlevel 1 goto NO_PY

for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /C:"IPv4"') do (
  set "LAN_IP=%%A"
  goto GOT_IP
)
:GOT_IP
set "LAN_IP=%LAN_IP: =%"

echo [A] Ollama...
curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OLLAMA_OK

echo     Demarrage Ollama...
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"
start "VendIA-Ollama" cmd /k "cd /d "%CD%" && set OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%EXE%" serve"

set W=0
:WAIT_O
timeout /t 1 /nobreak >NUL
curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OLLAMA_OK
set /a W+=1
if %W% LSS 40 goto WAIT_O
echo [ERREUR] Ollama ne repond pas.
pause
exit /b 1

:OLLAMA_OK
echo     OK Ollama
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
"%EXE%" list 2>NUL | find /I "moondream" >NUL
if not errorlevel 1 goto MODEL_OK
echo     Pull moondream...
"%EXE%" pull moondream
:MODEL_OK
echo.

echo [B] Passerelle...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%WEB_PORT% " ^| findstr LISTENING') do taskkill /PID %%P /F >NUL 2>&1
timeout /t 1 /nobreak >NUL

start "VendIA-Gateway" cmd /k "cd /d "%CD%" && python vendia_gateway.py --port %WEB_PORT% --bind 0.0.0.0 --ollama 127.0.0.1:%VENDIA_PORT%"

set W=0
:WAIT_G
timeout /t 1 /nobreak >NUL
curl.exe -s -m 3 "http://127.0.0.1:%WEB_PORT%/" >NUL 2>&1
if not errorlevel 1 goto GW_OK
set /a W+=1
if %W% LSS 20 goto WAIT_G
echo [ERREUR] Passerelle KO - regarde fenetre VendIA-Gateway
pause
exit /b 1

:GW_OK
echo     OK Passerelle
echo.
curl.exe -s -m 5 "http://127.0.0.1:%WEB_PORT%/vendia/health"
echo.
echo.
echo ============================================================
echo   SERVEUR PRET
echo ============================================================
echo   PC        : http://127.0.0.1:%WEB_PORT%/
echo   Telephone : http://%LAN_IP%:%WEB_PORT%/
echo   Si tel KO : 3-OUVRIR-RESEAU.bat en Admin
echo ============================================================
start "" "http://127.0.0.1:%WEB_PORT%/"
pause
exit /b 0

:NO_EXE
echo [ERREUR] ollama\ollama.exe introuvable dans :
echo   %CD%
echo Lance d abord 1-INSTALLER.bat
dir ollama 2>NUL
pause
exit /b 1

:NO_PY
echo [ERREUR] Python introuvable. Installe Python 3 + Add to PATH.
pause
exit /b 1