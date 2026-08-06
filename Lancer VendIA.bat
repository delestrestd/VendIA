@echo off
REM ============================================================================
REM  VendIA — un seul lanceur (Wi-Fi + 4G/5G)
REM  - Ollama 11435 (isole, pas DataChef)
REM  - Passerelle 8765 (app + proxy IA)
REM  - Tunnel Cloudflare auto (URL dans vendia_runtime.json)
REM  L'app detecte Wi-Fi vs mobile et choisit le bon chemin.
REM ============================================================================
setlocal EnableDelayedExpansion
set "ROOT=%~dp0"
cd /d "%ROOT%"

set "VENDIA_PORT=11435"
set "WEB_PORT=8765"
set "OLLAMA_MODELS=%ROOT%ollama\models"
set "OLLAMA_EXE=%ROOT%ollama\ollama.exe"

if not exist "%OLLAMA_EXE%" (
  echo [ERREUR] ollama manquant — lance telecharger-ia-portable.bat
  pause
  exit /b 1
)
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"

set "LAN_IP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R /C:"IPv4"') do (
  set "CAND=%%A"
  set "CAND=!CAND: =!"
  echo !CAND! | findstr /R "^192\.|^10\.|^172\." >NUL
  if not errorlevel 1 if not defined LAN_IP set "LAN_IP=!CAND!"
)
if not defined LAN_IP set "LAN_IP=127.0.0.1"

REM --- Ollama ---
curl -s -m 1 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
if errorlevel 1 (
  echo [VendIA] Ollama 0.0.0.0:!VENDIA_PORT! ...
  start "VendIA-Ollama" /MIN cmd /c "set OLLAMA_HOST=0.0.0.0:!VENDIA_PORT!&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%OLLAMA_EXE%" serve"
  timeout /t 4 /nobreak >NUL
)

set "OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!"
"%OLLAMA_EXE%" list 2>NUL | find /I "moondream" >NUL
if errorlevel 1 (
  echo [info] Pull moondream...
  "%OLLAMA_EXE%" pull moondream
)

REM --- Gateway ---
curl -s -m 1 http://127.0.0.1:!WEB_PORT!/vendia/runtime.json >NUL 2>&1
if errorlevel 1 (
  curl -s -m 1 http://127.0.0.1:!WEB_PORT!/ >NUL 2>&1
)
curl -s -m 1 http://127.0.0.1:!WEB_PORT!/ >NUL 2>&1
if errorlevel 1 (
  echo [VendIA] Passerelle 8765 ...
  start "VendIA-Gateway" /MIN cmd /c "cd /d "%ROOT%" && python vendia_gateway.py --port !WEB_PORT! --bind 0.0.0.0 --ollama 127.0.0.1:!VENDIA_PORT!"
  timeout /t 2 /nobreak >NUL
)

REM Runtime initial (LAN) avant tunnel
python -c "from pathlib import Path; import json,socket,time;\
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);\
s.connect(('8.8.8.8',80)); ip=s.getsockname()[0]; s.close();\
Path(r'%ROOT%vendia_runtime.json').write_text(json.dumps({'updatedAt':time.strftime('%Y-%m-%dT%H:%M:%S'),'lanUrl':'http://%%s:8765'%%ip,'lanIp':ip,'gatewayPort':8765,'ollamaPort':11435,'publicUrl':None,'sameOriginV1':True,'tunnel':'pending'},indent=2),encoding='utf-8')" 2>NUL

REM --- Tunnel en arriere-plan (4G/5G) ---
echo [VendIA] Tunnel distant auto ^(4G/5G^) ...
start "VendIA-Tunnel" /MIN cmd /c "cd /d "%ROOT%" && python vendia_tunnel.py"

echo.
echo ============================================================
echo   VENDIA pret — l'app s'adapte Wi-Fi / 4G toute seule
echo ============================================================
echo.
echo   1) Ouvre l'app ^(PC ou telephone^) :
echo        http://!LAN_IP!:8765/
echo        http://127.0.0.1:8765/
echo.
echo   2) Sur le telephone : une fois en Wi-Fi maison, ouvre le lien
echo      ci-dessus. L'app memorise le tunnel pour la 4G/5G.
echo.
echo   3) Reglages -^> Ollama local -^> Detecter -^> Enregistrer
echo      ^(ou laisse l'auto-config au demarrage^)
echo.
echo   URL 4G : regarde la fenetre "VendIA-Tunnel" ou vendia_runtime.json
echo   DataChef : non touche.
echo ============================================================
echo.

start "" "http://127.0.0.1:!WEB_PORT!/"
timeout /t 6 /nobreak >NUL

REM Affiche l'URL publique si deja la
if exist "%ROOT%vendia_runtime.json" (
  echo --- vendia_runtime.json ---
  type "%ROOT%vendia_runtime.json"
  echo.
)

echo Laisse Ollama / Gateway / Tunnel en arriere-plan pendant l'usage.
timeout /t 5 /nobreak >NUL
endlocal
