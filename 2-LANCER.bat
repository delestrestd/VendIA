@echo off
chcp 65001 >NUL
title VendIA — Etape 2 / 2 : Lancer le serveur
cd /d "%~dp0"
setlocal EnableDelayedExpansion

echo.
echo ============================================================
echo   ETAPE 2 / 2 — LANCER LE SERVEUR (PC + TELEPHONE)
echo ============================================================
echo.
echo   1. Demarre Ollama     (modele sur ce PC, port 11435)
echo   2. Demarre la passerelle (app web, port 8765)
echo   3. Ouvre le navigateur
echo.
echo   NE FERME PAS cette fenetre pendant que tu utilises VendIA.
echo ============================================================
echo.

set "ROOT=%~dp0"
set "VENDIA_PORT=11435"
set "WEB_PORT=8765"
set "OLLAMA_EXE=%ROOT%ollama\ollama.exe"
set "OLLAMA_MODELS=%ROOT%ollama\models"
set "LOG=%ROOT%vendia_start.log"

echo === VendIA start %DATE% %TIME% === > "%LOG%"

REM --- Pre-requis ---
if not exist "%OLLAMA_EXE%" (
  echo [ERREUR] Ollama non installe.
  echo          Double-clic d'abord sur  1-INSTALLER.bat
  echo.
  pause
  exit /b 1
)

python --version >NUL 2>&1
if errorlevel 1 (
  echo [ERREUR] Python introuvable dans le PATH.
  echo          Installe Python 3 depuis https://www.python.org/downloads/
  echo          Coche "Add python.exe to PATH", puis relance.
  echo.
  pause
  exit /b 1
)

REM --- IP telephone ---
set "LAN_IP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R /C:"IPv4"') do (
  set "CAND=%%A"
  set "CAND=!CAND: =!"
  echo !CAND! | findstr /R "^192\.|^10\.|^172\." >NUL
  if not errorlevel 1 if not defined LAN_IP set "LAN_IP=!CAND!"
)
if not defined LAN_IP set "LAN_IP=127.0.0.1"

echo [A] Ollama (IA sur le disque)...
REM Arrete un ancien Ollama VendIA s'il est zombie (optionnel, soft)
curl.exe -s -m 2 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
if errorlevel 1 (
  echo     Demarrage Ollama...
  start "VendIA-Ollama" cmd /c "title VendIA-Ollama && set OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%OLLAMA_EXE%" serve && pause"
  set /a W=0
  :wait_o
  timeout /t 1 /nobreak >NUL
  curl.exe -s -m 2 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
  if not errorlevel 1 goto o_ok
  set /a W+=1
  if !W! LSS 35 goto wait_o
  echo [ERREUR] Ollama ne repond toujours pas sur le port !VENDIA_PORT!.
  echo          Ferme les autres apps qui bloquent le port, relance 0-DIAGNOSTIC.bat
  echo Ollama FAIL >> "%LOG%"
  pause
  exit /b 1
) else (
  echo     Deja en marche.
)
:o_ok
echo     [OK] http://127.0.0.1:!VENDIA_PORT!

set "OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!"
"%OLLAMA_EXE%" list 2>NUL | find /I "moondream" >NUL
if errorlevel 1 (
  echo     [ATTENTION] moondream absent — telechargement...
  "%OLLAMA_EXE%" pull moondream
) else (
  echo     [OK] modele moondream present
)
echo.

echo [B] Passerelle web (app + proxy)...
REM Tue l'ancien process sur 8765 s'il existe
for /f "tokens=5" %%P in ('netstat -ano 2^>NUL ^| findstr ":%WEB_PORT% " ^| findstr LISTENING') do (
  echo     Arret ancien PID %%P sur port !WEB_PORT!...
  taskkill /PID %%P /F >NUL 2>&1
)
timeout /t 1 /nobreak >NUL

start "VendIA-Gateway" cmd /c "title VendIA-Gateway && cd /d "%ROOT%" && python vendia_gateway.py --port !WEB_PORT! --bind 0.0.0.0 --ollama 127.0.0.1:!VENDIA_PORT! && pause"
set /a W=0
:wait_g
timeout /t 1 /nobreak >NUL
curl.exe -s -m 3 http://127.0.0.1:!WEB_PORT!/ >NUL 2>&1
if not errorlevel 1 goto g_ok
set /a W+=1
if !W! LSS 20 goto wait_g
echo [ERREUR] Passerelle 8765 ne repond pas.
echo          Regarde la fenetre "VendIA-Gateway" pour le message d'erreur.
echo Gateway FAIL >> "%LOG%"
pause
exit /b 1
:g_ok
echo     [OK] http://127.0.0.1:!WEB_PORT!/
echo.

echo [C] Sante IA...
curl.exe -s -m 5 http://127.0.0.1:!WEB_PORT!/vendia/health
echo.
echo.

REM Runtime pour telephone
python -c "from pathlib import Path; import json,socket,time;\
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);\
s.connect(('8.8.8.8',80)); ip=s.getsockname()[0]; s.close();\
Path(r'%ROOT%vendia_runtime.json').write_text(json.dumps({'updatedAt':time.strftime('%%Y-%%m-%%dT%%H:%%M:%%S'),'lanUrl':'http://%%s:8765'%%ip,'lanIp':ip,'gatewayPort':8765,'ollamaPort':11435,'publicUrl':None,'sameOriginV1':True},indent=2),encoding='utf-8')" 2>NUL

REM --- Rappel pare-feu ---
netsh advfirewall firewall show rule name="VendIA Gateway 8765" >NUL 2>&1
if errorlevel 1 (
  echo.
  echo [ATTENTION] Pare-feu : regle VendIA absente.
  echo             Si le TELEPHONE ne charge pas la page, lance une fois :
  echo               3-OUVRIR-RESEAU.bat   ^(clic droit -^> Admin^)
  echo.
)

echo ============================================================
echo   SERVEUR PRET
echo ============================================================
echo.
echo   SUR LE PC (navigateur) :
echo      http://127.0.0.1:8765/
echo.
echo   SUR LE TELEPHONE (meme Wi-Fi que le PC) :
echo      http://!LAN_IP!:8765/
echo.
echo   Si le telephone ne charge RIEN :
echo      1) PC et tel sur le MEME Wi-Fi (pas le partage 4G du tel)
echo      2) Lance  3-OUVRIR-RESEAU.bat  en Administrateur
echo      3) Relance 2-LANCER.bat puis reessaie l'URL telephone
echo.
echo   CONTROLE PC :
echo      http://127.0.0.1:8765/vendia/health
echo.
echo   Garde ouvertes : VendIA-Ollama + VendIA-Gateway
echo ============================================================
echo.
echo Ouverture du navigateur (PC)...
start "" "http://127.0.0.1:!WEB_PORT!/"

echo.
echo Laisse CETTE fenetre ouverte (ou minimise-la).
echo Appuie sur une touche pour quitter le script
echo (Ollama et Gateway continuent en arriere-plan).
echo.
pause
endlocal
