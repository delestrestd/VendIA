@echo off
chcp 65001 >NUL
title VendIA — Ouvrir le reseau (telephone)
cd /d "%~dp0"

echo.
echo ============================================================
echo   OUVRIR L'ACCES TELEPHONE (port 8765)
echo ============================================================
echo.
echo   Windows bloque souvent le Wi-Fi "Public".
echo   Ce script :
echo     1) Cree une regle pare-feu TCP 8765 (VendIA)
echo     2) Propose de passer le reseau en Prive
echo.
echo   Une fenetre UAC "Administrateur" va s'ouvrir : accepte.
echo ============================================================
echo.
pause

REM Relance en admin si besoin
net session >NUL 2>&1
if errorlevel 1 (
  echo Elevation admin...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b 0
)

echo.
echo [1/3] Regle pare-feu TCP 8765...
netsh advfirewall firewall delete rule name="VendIA Gateway 8765" >NUL 2>&1
netsh advfirewall firewall add rule name="VendIA Gateway 8765" dir=in action=allow protocol=TCP localport=8765 profile=any enable=yes
if errorlevel 1 (
  echo     [ERREUR] netsh a echoue.
) else (
  echo     [OK] Port 8765 ouvert (tous profils : Domaine/Prive/Public)
)

echo.
echo [2/3] Profil reseau actuel...
powershell -NoProfile -Command "Get-NetConnectionProfile | Format-Table Name,NetworkCategory,IPv4Connectivity -AutoSize"

echo.
echo [3/3] Passage en reseau PRIVE (recommande pour le telephone)...
powershell -NoProfile -Command ^
  "$p = Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' }; ^
   foreach ($x in $p) { ^
     try { Set-NetConnectionProfile -InterfaceIndex $x.InterfaceIndex -NetworkCategory Private; Write-Host ('[OK] ' + $x.Name + ' -> Private') } ^
     catch { Write-Host ('[ATTENTION] Impossible de changer ' + $x.Name + ' : ' + $_.Exception.Message) } ^
   }"

echo.
echo ============================================================
echo   TERMINE
echo ============================================================
echo.
echo   Ensuite :
echo     1) Double-clic  2-LANCER.bat   (serveur allume)
echo     2) Sur le telephone (meme Wi-Fi) :
echo          http://IP-DU-PC:8765/
echo        (l'IP s'affiche dans 2-LANCER.bat)
echo.
echo   Test depuis le PC :
echo     http://127.0.0.1:8765/     = toujours
echo     http://192.168.x.x:8765/   = comme le telephone
echo ============================================================
echo.
pause
