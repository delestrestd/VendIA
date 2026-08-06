@echo off
REM ============================================================================
REM  VendIA — modele IA sur CET ordinateur + app pour PC / telephone
REM
REM  Architecture :
REM    [Photo tel/PC] --> passerelle :8765 --> Ollama :11435 (moondream sur disque)
REM
REM  Le modele ne quitte pas le PC. Telephone = meme Wi-Fi (ou tunnel 4G).
REM ============================================================================
setlocal EnableDelayedExpansion
set "ROOT=%~dp0"
cd /d "%ROOT%"

set "VENDIA_PORT=11435"
set "WEB_PORT=8765"
set "OLLAMA_MODELS=%ROOT%ollama\models"
set "OLLAMA_EXE=%ROOT%ollama\ollama.exe"

echo.
echo ============================================================
echo   VendIA — demarrage (IA hebergee sur ce PC)
echo ============================================================
echo.

if not exist "%OLLAMA_EXE%" (
  echo [ERREUR] ollama\ollama.exe manquant.
  echo          Lance d'abord : telecharger-ia-portable.bat
  echo.
  pause
  exit /b 1
)
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"

REM --- IP LAN (telephone) ---
set "LAN_IP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R /C:"IPv4"') do (
  set "CAND=%%A"
  set "CAND=!CAND: =!"
  echo !CAND! | findstr /R "^192\.|^10\.|^172\." >NUL
  if not errorlevel 1 if not defined LAN_IP set "LAN_IP=!CAND!"
)
if not defined LAN_IP set "LAN_IP=127.0.0.1"

REM --- Ollama : ecoute locale (la passerelle proxy tout) ---
curl.exe -s -m 2 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
if errorlevel 1 (
  echo [1/3] Demarrage Ollama sur le port !VENDIA_PORT! ...
  start "VendIA-Ollama" /MIN cmd /c "set OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%OLLAMA_EXE%" serve"
  set /a WAIT=0
  :wait_ollama
  timeout /t 1 /nobreak >NUL
  curl.exe -s -m 2 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
  if not errorlevel 1 goto ollama_ok
  set /a WAIT+=1
  if !WAIT! LSS 25 goto wait_ollama
  echo [ERREUR] Ollama ne repond pas sur !VENDIA_PORT!.
  pause
  exit /b 1
) else (
  echo [1/3] Ollama deja actif ^(port !VENDIA_PORT!^)
)
:ollama_ok

REM --- Modele moondream ---
set "OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!"
"%OLLAMA_EXE%" list 2>NUL | find /I "moondream" >NUL
if errorlevel 1 (
  echo [info] Telechargement moondream dans ollama\models ...
  "%OLLAMA_EXE%" pull moondream
) else (
  echo [info] Modele moondream present sur le disque.
)

REM --- Passerelle : redemarre proprement pour charger le code a jour ---
echo [2/3] Passerelle app + proxy IA ^(port !WEB_PORT!^) ...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%WEB_PORT% " ^| findstr LISTENING') do (
  echo        Arret ancien process PID %%P sur !WEB_PORT! ...
  taskkill /PID %%P /F >NUL 2>&1
)
timeout /t 1 /nobreak >NUL
start "VendIA-Gateway" /MIN cmd /c "cd /d "%ROOT%" && python vendia_gateway.py --port !WEB_PORT! --bind 0.0.0.0 --ollama 127.0.0.1:!VENDIA_PORT!"
set /a WAIT=0
:wait_gw
timeout /t 1 /nobreak >NUL
curl.exe -s -m 2 http://127.0.0.1:!WEB_PORT!/vendia/health >NUL 2>&1
if not errorlevel 1 goto gw_ok
set /a WAIT+=1
if !WAIT! LSS 15 goto wait_gw
echo [ERREUR] Passerelle 8765 indisponible. Python installe ?
python --version
pause
exit /b 1
:gw_ok
echo        Passerelle OK.

REM --- Runtime LAN (telephone) ---
python -c "from pathlib import Path; import json,socket,time;\
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);\
s.connect(('8.8.8.8',80)); ip=s.getsockname()[0]; s.close();\
Path(r'%ROOT%vendia_runtime.json').write_text(json.dumps({'updatedAt':time.strftime('%%Y-%%m-%%dT%%H:%%M:%%S'),'lanUrl':'http://%%s:8765'%%ip,'lanIp':ip,'gatewayPort':8765,'ollamaPort':11435,'publicUrl':None,'sameOriginV1':True,'v1':'http://%%s:8765/v1'%%ip},indent=2),encoding='utf-8')" 2>NUL

REM --- Tunnel optionnel 4G (arriere-plan, non bloquant) ---
echo [3/3] Tunnel 4G/5G en arriere-plan (optionnel) ...
start "VendIA-Tunnel" /MIN cmd /c "cd /d "%ROOT%" && python vendia_tunnel.py"

echo.
echo ============================================================
echo   PRET — le modele reste sur CET ordinateur
echo ============================================================
echo.
echo   PC        :  http://127.0.0.1:!WEB_PORT!/
echo   Telephone :  http://!LAN_IP!:!WEB_PORT!/
echo                ^(meme Wi-Fi que le PC^)
echo.
echo   Sante IA  :  http://127.0.0.1:!WEB_PORT!/vendia/health
echo.
echo   Laisse les fenetres Ollama / Gateway ouvertes pendant l'usage.
echo   DataChef (11434) n'est pas touche.
echo ============================================================
echo.

REM Affiche health
curl.exe -s http://127.0.0.1:!WEB_PORT!/vendia/health
echo.
echo.

start "" "http://127.0.0.1:!WEB_PORT!/"
timeout /t 4 /nobreak >NUL
endlocal
