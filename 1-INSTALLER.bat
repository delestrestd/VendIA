@echo off
chcp 65001 >NUL
title VendIA — Etape 1 / 2 : Installer l'IA
cd /d "%~dp0"
setlocal EnableDelayedExpansion

echo.
echo ============================================================
echo   ETAPE 1 / 2 — INSTALLER L'IA SUR CE PC
echo ============================================================
echo.
echo   Ceci telecharge :
echo     - Ollama portable  dans  ollama\
echo     - Modele moondream dans  ollama\models\  (~1,7 Go)
echo.
echo   Duree : 5 a 30 min selon la connexion.
echo   A faire UNE SEULE FOIS (ou si tu reinstalles).
echo.
echo   DataChef n'est PAS touche (port 11434 reste libre).
echo ============================================================
echo.
pause

set "ROOT=%~dp0"
set "VENDIA_PORT=11435"
set "OLLAMA_DIR=%ROOT%ollama"
set "OLLAMA_MODELS=%OLLAMA_DIR%\models"
set "ZIP=%ROOT%_tmp_ollama.zip"
set "URL=https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"

echo.
echo [1/4] Dossiers...
if not exist "%OLLAMA_DIR%" mkdir "%OLLAMA_DIR%"
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"
echo       OK
echo.

echo [2/4] Binaire Ollama...
if exist "%OLLAMA_DIR%\ollama.exe" (
  echo       Deja present : ollama\ollama.exe
) else (
  echo       Telechargement depuis GitHub...
  curl.exe -L --retry 5 --retry-delay 2 -o "%ZIP%" "%URL%"
  if errorlevel 1 (
    echo.
    echo [ERREUR] Telechargement rate. Verifie Internet puis relance.
    pause
    exit /b 1
  )
  echo       Extraction...
  powershell -NoProfile -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%OLLAMA_DIR%' -Force"
  del /q "%ZIP%" 2>NUL
  if not exist "%OLLAMA_DIR%\ollama.exe" (
    echo [ERREUR] ollama.exe introuvable apres extraction.
    pause
    exit /b 1
  )
  echo       OK — ollama.exe installe
)
echo.

echo [3/4] Demarrage temporaire d'Ollama (port %VENDIA_PORT%)...
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
set "OLLAMA_MODELS=%OLLAMA_MODELS%"
set "OLLAMA_ORIGINS=*"

curl.exe -s -m 2 http://127.0.0.1:%VENDIA_PORT%/api/version >NUL 2>&1
if errorlevel 1 (
  start "VendIA-Ollama-Install" /MIN cmd /c "set OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%OLLAMA_DIR%\ollama.exe" serve"
  set /a W=0
  :wait_ol
  timeout /t 1 /nobreak >NUL
  curl.exe -s -m 2 http://127.0.0.1:%VENDIA_PORT%/api/version >NUL 2>&1
  if not errorlevel 1 goto ol_ready
  set /a W+=1
  if !W! LSS 40 goto wait_ol
  echo [ERREUR] Ollama ne demarre pas. Relance en tant qu'admin ou desactive l'antivirus temporairement.
  pause
  exit /b 1
)
:ol_ready
echo       Ollama repond sur 127.0.0.1:%VENDIA_PORT%
echo.

echo [4/4] Telechargement du modele vision moondream (~1,7 Go)...
echo       Laisse cette fenetre ouverte jusqu'a la fin.
echo.
"%OLLAMA_DIR%\ollama.exe" pull moondream
if errorlevel 1 (
  echo.
  echo [ERREUR] Echec pull moondream. Relance 1-INSTALLER.bat.
  pause
  exit /b 1
)

echo.
echo Modeles installes :
"%OLLAMA_DIR%\ollama.exe" list
echo.

echo ============================================================
echo   ETAPE 1 TERMINEE
echo ============================================================
echo.
echo   Prochaine etape :
echo     Double-clic sur   2-LANCER.bat
echo.
echo   Puis ouvre dans le navigateur :
echo     http://127.0.0.1:8765/
echo ============================================================
echo.
pause
endlocal
