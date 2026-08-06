@echo off
REM ============================================================================
REM  Pack IA VendIA UNIQUEMENT (ne touche pas DataChef)
REM  Port 11435 · modeles dans .\ollama\models
REM ============================================================================
setlocal EnableDelayedExpansion
set "ROOT=%~dp0"
cd /d "%ROOT%"
set "VENDIA_PORT=11435"
set "OLLAMA_DIR=%ROOT%ollama"
set "OLLAMA_MODELS=%OLLAMA_DIR%\models"
set "ZIP=%ROOT%_tmp_ollama.zip"
set "URL=https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"

if not exist "%OLLAMA_DIR%" mkdir "%OLLAMA_DIR%"
if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%"

if not exist "%OLLAMA_DIR%\ollama.exe" (
  echo Telechargement Ollama portable VendIA...
  curl -L --retry 3 -o "%ZIP%" "%URL%"
  if errorlevel 1 (
    echo Echec telechargement.
    pause
    exit /b 1
  )
  echo Extraction...
  powershell -NoProfile -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%OLLAMA_DIR%' -Force"
  del /q "%ZIP%" 2>NUL
) else (
  echo ollama.exe deja present ^(VendIA^).
)

set "OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!"
set "OLLAMA_ORIGINS=*"
set "OLLAMA_MODELS=%OLLAMA_MODELS%"

curl -s -m 1 http://127.0.0.1:!VENDIA_PORT!/api/version >NUL 2>&1
if errorlevel 1 (
  start "VendIA-Ollama" /MIN cmd /c "set OLLAMA_HOST=127.0.0.1:!VENDIA_PORT!&& set OLLAMA_MODELS=%OLLAMA_MODELS%&& set OLLAMA_ORIGINS=*&& "%OLLAMA_DIR%\ollama.exe" serve"
  timeout /t 3 /nobreak >NUL
)

echo.
echo Telechargement modele vision moondream ^(~1.7 Go^) dans le dossier VendIA...
"%OLLAMA_DIR%\ollama.exe" pull moondream
echo.
echo Modeles VendIA :
"%OLLAMA_DIR%\ollama.exe" list
echo.
echo Port VendIA : !VENDIA_PORT!  ^(DataChef reste sur 11434^)
echo Utilise "Lancer VendIA.bat" au quotidien.
pause
endlocal
