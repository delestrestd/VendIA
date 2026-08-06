@echo off
chcp 65001 >NUL
setlocal EnableDelayedExpansion
title VendIA — Diagnostic
cd /d "%~dp0"
echo.
echo ============================================================
echo   VENDIA — DIAGNOSTIC (lis les [OK] / [MANQUE] / [ERREUR])
echo ============================================================
echo.
set "ERR=0"

echo [1] Fichiers
if exist "ollama\ollama.exe" (echo     [OK] ollama\ollama.exe) else (echo     [MANQUE] ollama\ollama.exe — lance 1-INSTALLER.bat & set ERR=1)
if exist "ollama\models" (echo     [OK] ollama\models\) else (echo     [MANQUE] ollama\models\ & set ERR=1)
if exist "vendia_gateway.py" (echo     [OK] vendia_gateway.py) else (echo     [MANQUE] vendia_gateway.py & set ERR=1)
if exist "index.html" (echo     [OK] index.html) else (echo     [MANQUE] index.html & set ERR=1)
echo.

echo [2] Python
python --version 2>NUL
if errorlevel 1 (
  echo     [ERREUR] Python introuvable. Installe Python 3 depuis python.org
  echo              Coche "Add python.exe to PATH"
  set ERR=1
) else (
  echo     [OK] Python dans le PATH
)
echo.

echo [3] Ollama port 11435
curl.exe -s -m 3 http://127.0.0.1:11435/api/version
if errorlevel 1 (
  echo.
  echo     [ARRETE] Ollama ne repond pas. Lance 2-LANCER.bat
  set ERR=1
) else (
  echo.
  echo     [OK] Ollama repond
)
echo.

echo [4] Modele moondream
if exist "ollama\ollama.exe" (
  set "OLLAMA_HOST=127.0.0.1:11435"
  set "OLLAMA_MODELS=%~dp0ollama\models"
  "ollama\ollama.exe" list 2>NUL | find /I "moondream" >NUL
  if errorlevel 1 (
    echo     [MANQUE] moondream — lance 1-INSTALLER.bat
    set ERR=1
  ) else (
    echo     [OK] moondream listé
  )
)
echo.

echo [5] Passerelle port 8765
curl.exe -s -m 3 http://127.0.0.1:8765/vendia/health
if errorlevel 1 (
  echo.
  echo     [ARRETE] Passerelle 8765 ne repond pas. Lance 2-LANCER.bat
  set ERR=1
) else (
  echo.
  echo     [OK] Passerelle repond
)
echo.

echo [6] Page app (localhost)
curl.exe -s -m 3 -o NUL -w "     HTTP %%{http_code}\n" http://127.0.0.1:8765/
echo.

echo [7] Acces reseau local (comme le telephone)
set "LAN_IP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R /C:"IPv4"') do (
  set "CAND=%%A"
  set "CAND=!CAND: =!"
  echo !CAND! | findstr /R "^192\.|^10\.|^172\." >NUL
  if not errorlevel 1 if not defined LAN_IP set "LAN_IP=!CAND!"
)
if defined LAN_IP (
  echo     IP detectee : !LAN_IP!
  curl.exe -s -m 3 -o NUL -w "     http://!LAN_IP!:8765/  HTTP %%{http_code}\n" http://!LAN_IP!:8765/
  echo     (si HTTP 000 depuis le PC, serveur eteint ou mauvaise IP)
) else (
  echo     [ATTENTION] Pas d'IP LAN 192/10/172 trouvee
)
echo.

echo [8] Pare-feu VendIA
netsh advfirewall firewall show rule name="VendIA Gateway 8765" >NUL 2>&1
if errorlevel 1 (
  echo     [MANQUE] Regle pare-feu — lance 3-OUVRIR-RESEAU.bat en Admin
  set ERR=1
) else (
  echo     [OK] Regle "VendIA Gateway 8765" presente
)
echo.

echo ============================================================
if "%ERR%"=="0" (
  echo   RESULTAT : tout semble OK
  echo   PC  : http://127.0.0.1:8765/
  if defined LAN_IP echo   Tel : http://!LAN_IP!:8765/
) else (
  echo   RESULTAT : il manque des etapes
  echo.
  echo   ORDRE A SUIVRE :
  echo     1^) 1-INSTALLER.bat     ^(une seule fois^)
  echo     2^) 3-OUVRIR-RESEAU.bat ^(Admin — telephone^)
  echo     3^) 2-LANCER.bat        ^(a chaque usage^)
  echo     4^) PC : http://127.0.0.1:8765/
  echo        Tel: http://IP:8765/  ^(affichee par 2-LANCER^)
)
echo ============================================================
echo.
pause
