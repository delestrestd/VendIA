@echo off
chcp 65001 >NUL
setlocal EnableExtensions
title VendIA - Etape 1 Installer l IA
cd /d "%~dp0"

echo.
echo ============================================================
echo   ETAPE 1 / 2 - INSTALLER L IA SUR CE PC
echo ============================================================
echo.
echo   Telecharge si besoin :
echo     - Ollama portable  dans  ollama\
echo     - Modele moondream dans  ollama\models\  (environ 1.7 Go)
echo.
echo   A faire UNE SEULE FOIS (ou si reinstall).
echo   DataChef n est PAS touche (port 11434).
echo ============================================================
echo.
pause

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "VENDIA_PORT=11435"
set "OLLAMA_DIR=%ROOT%\ollama"
set "OLLAMA_MODELS=%OLLAMA_DIR%\models"
set "ZIP=%ROOT%\_tmp_ollama.zip"
set "URL=https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
set "EXE=%OLLAMA_DIR%\ollama.exe"

echo.
echo [1/4] Dossiers...
if not exist "%OLLAMA_DIR%" mkdir "%OLLAMA_DIR%"
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"
echo       OK : %OLLAMA_DIR%
echo.

echo [2/4] Binaire Ollama...
if exist "%EXE%" goto OLLAMA_OK

echo       Telechargement depuis GitHub...
echo       URL  : %URL%
echo       Vers : %ZIP%
curl.exe -L --retry 5 --retry-delay 2 -o "%ZIP%" "%URL%"
if errorlevel 1 goto DL_FAIL
if not exist "%ZIP%" goto DL_FAIL

echo       Extraction...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%OLLAMA_DIR%' -Force"
del /q "%ZIP%" 2>NUL

if not exist "%EXE%" goto EXE_FAIL
echo       OK - ollama.exe installe
goto OLLAMA_OK

:DL_FAIL
echo.
echo [ERREUR] Telechargement rate.
echo          Verifie Internet, antivirus, puis relance.
echo          ZIP attendu : %ZIP%
pause
exit /b 1

:EXE_FAIL
echo [ERREUR] ollama.exe introuvable apres extraction dans :
echo          %OLLAMA_DIR%
pause
exit /b 1

:OLLAMA_OK
echo       Deja pret : %EXE%
echo.

echo [3/4] Demarrage temporaire d Ollama (port %VENDIA_PORT%)...
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
set "OLLAMA_MODELS=%OLLAMA_MODELS%"
set "OLLAMA_ORIGINS=*"

curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OL_READY

echo       Lancement ollama serve...
start "VendIA-Ollama-Install" /MIN cmd /c "set OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%EXE%" serve"

set /a W=0
:WAIT_OL
timeout /t 1 /nobreak >NUL
curl.exe -s -m 2 "http://127.0.0.1:%VENDIA_PORT%/api/version" >NUL 2>&1
if not errorlevel 1 goto OL_READY
set /a W+=1
if %W% LSS 45 goto WAIT_OL

echo [ERREUR] Ollama ne demarre pas sur le port %VENDIA_PORT%.
echo          Ferme les autres Ollama, ou relance en admin.
pause
exit /b 1

:OL_READY
echo       OK - Ollama repond sur 127.0.0.1:%VENDIA_PORT%
echo.

echo [4/4] Modele vision moondream...
"%EXE%" list 2>NUL | find /I "moondream" >NUL
if not errorlevel 1 (
  echo       Deja present : moondream
  goto DONE
)

echo       Telechargement moondream (environ 1.7 Go) - laisse cette fenetre ouverte...
"%EXE%" pull moondream
if errorlevel 1 (
  echo.
  echo [ERREUR] Echec pull moondream. Relance 1-INSTALLER.bat
  pause
  exit /b 1
)

:DONE
echo.
echo Modeles installes :
set "OLLAMA_HOST=127.0.0.1:%VENDIA_PORT%"
"%EXE%" list
echo.
echo ============================================================
echo   ETAPE 1 TERMINEE
echo ============================================================
echo.
echo   Suite :
echo     1. Double-clic  2-LANCER.bat
echo     2. Navigateur   http://127.0.0.1:8765/
echo.
echo   Telephone : meme Wi-Fi + IP affichee par 2-LANCER
echo   Si tel bloque : 3-OUVRIR-RESEAU.bat en Administrateur
echo ============================================================
echo.
pause
endlocal
exit /b 0
