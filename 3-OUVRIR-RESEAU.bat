@echo off
setlocal EnableExtensions
title VendIA Reseau Telephone
cd /d "%~dp0"

echo.
echo Ouvre le port 8765 pour le telephone (Admin requis).
echo.
pause

net session >NUL 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b 0
)

netsh advfirewall firewall delete rule name="VendIA Gateway 8765" >NUL 2>&1
netsh advfirewall firewall add rule name="VendIA Gateway 8765" dir=in action=allow protocol=TCP localport=8765 profile=any enable=yes
echo OK regle pare-feu 8765

powershell -NoProfile -Command "Get-NetConnectionProfile | ForEach-Object { try { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private; Write-Host ('Private: ' + $_.Name) } catch {} }"

echo.
echo Ensuite : 2-LANCER.bat puis URL telephone affichee.
pause
exit /b 0