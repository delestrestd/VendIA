@echo off
chcp 65001 >NUL
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

echo [6] Page app
curl.exe -s -m 3 -o NUL -w "     HTTP %%{http_code}\n" http://127.0.0.1:8765/
echo.

echo ============================================================
if "%ERR%"=="0" (
  echo   RESULTAT : tout semble OK
  echo   Ouvre : http://127.0.0.1:8765/
) else (
  echo   RESULTAT : il manque des etapes
  echo.
  echo   ORDRE A SUIVRE :
  echo     1^) Double-clic  1-INSTALLER.bat   ^(une seule fois^)
  echo     2^) Double-clic  2-LANCER.bat      ^(a chaque usage^)
  echo     3^) Navigateur   http://127.0.0.1:8765/
)
echo ============================================================
echo.
pause
