@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
    echo Virtual environment .venv was not found.
    exit /b 1
)

set PY=.venv\Scripts\python.exe
%PY% -m PyInstaller -y MachineCostPro.spec || exit /b 1
%PY% -m PyInstaller -y Updater.spec || exit /b 1

if not exist "dist\MachineCostPro" mkdir "dist\MachineCostPro"
copy /Y "dist\MachineCostProUpdater\MachineCostProUpdater.exe" "dist\MachineCostPro\MachineCostProUpdater.exe" >nul
copy /Y "latest.json" "dist\MachineCostPro\latest.json" >nul

powershell -NoProfile -Command "if (Test-Path 'dist\MachineCostPro.zip') { Remove-Item -LiteralPath 'dist\MachineCostPro.zip' -Force }; Compress-Archive -Path 'dist\MachineCostPro\*' -DestinationPath 'dist\MachineCostPro.zip' -Force"

echo Build complete:
echo dist\MachineCostPro
echo dist\MachineCostPro.zip
