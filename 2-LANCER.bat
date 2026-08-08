@echo off
setlocal EnableExtensions
title VendIA Lancer - Mobile
cd /d "%~dp0"

echo.
echo ============================================================
echo   VENDIA - ALLUMER LE CERVEAU PC POUR LE TELEPHONE
echo ============================================================
echo.
echo   Le PC heberge l IA. Le telephone prend les photos.
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

echo [A] Ollama (IA sur le PC)...
curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OLLAMA_OK
echo     Demarrage...
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
echo     OK
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
"%EXE%" list 2>NUL | find /I "moondream" >NUL
if not errorlevel 1 goto MODEL_OK
echo     Pull moondream...
"%EXE%" pull moondream
:MODEL_OK
echo.

echo [B] Passerelle pour le telephone...
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
echo [ERREUR] Passerelle KO
pause
exit /b 1
:GW_OK
echo     OK
echo.
curl.exe -s -m 5 "http://127.0.0.1:%WEB_PORT%/vendia/health"
echo.
echo.
echo ############################################################
echo #
echo #   SUR TON TELEPHONE (meme Wi-Fi) :
echo #
echo #      http://%LAN_IP%:%WEB_PORT%/
echo #
echo #   OU scanne le QR ouvert sur le PC
echo #
echo ############################################################
echo.
echo   Si le tel ne charge rien :
echo     1) 3-OUVRIR-RESEAU.bat en Administrateur
echo     2) Relance 2-LANCER.bat
echo.
echo Ouverture de la page QR sur le PC...
start "" "http://127.0.0.1:%WEB_PORT%/phone"
pause
exit /b 0

:NO_EXE
echo [ERREUR] ollama\ollama.exe manquant - lance 1-INSTALLER.bat
pause
exit /b 1
:NO_PY
echo [ERREUR] Python manquant dans le PATH
pause
exit /b 1