@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo   ZElektrik KiCad PCM AUTO UPDATER
echo ==========================================
echo.

REM ===== CONFIG =====
set REPO_FILE=repository.json
set PKG_FILE=packages-v1.json
set REMOTE_URL=https://z-elektrik.github.io/Zelektrik_KiCad_Repository/packages-v1.json

if not exist "%REPO_FILE%" (
    echo ERROR: repository.json not found
    pause
    exit /b 1
)

if not exist "%PKG_FILE%" (
    echo ERROR: packages-v1.json not found
    pause
    exit /b 1
)

REM ====================================================
REM OPTIONAL LIB ZIP UPDATE (SAFE FLOW)
REM ====================================================

set /p DOZIP=Update LIB.zip SHA256? (y/n):

if /i not "!DOZIP!"=="y" goto SKIP_LIB

echo.
echo [1] Downloading LIB.zip...

curl -L -o LIB.zip https://github.com/Z-Elektrik/LIB/archive/refs/heads/main.zip

if errorlevel 1 (
    echo ERROR downloading LIB.zip
    pause
    exit /b 1
)

echo.
echo [2] Calculating LIB.zip SHA256...

for /f %%a in ('
powershell -NoProfile -Command "(Get-FileHash 'LIB.zip' -Algorithm SHA256).Hash.ToLower()"
') do set ZIP_HASH=%%a

echo     !ZIP_HASH!

echo.
echo [3] Updating packages-v1.json...

rem powershell -NoProfile -Command "$j=Get-Content '%PKG_FILE%' -Raw | ConvertFrom-Json; $j.packages[0].versions[0].download_sha256='!ZIP_HASH!'; $json=$j | ConvertTo-Json -Depth 20 -Compress; [System.IO.File]::WriteAllText('%PKG_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"
powershell -NoProfile -Command "$j=Get-Content '%PKG_FILE%' -Raw | ConvertFrom-Json; $j.packages[0].versions[0].download_sha256='!ZIP_HASH!'; $json=$j | ConvertTo-Json -Depth 20; [System.IO.File]::WriteAllText('%PKG_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"
powershell -NoProfile -Command "$t=[System.IO.File]::ReadAllText('%PKG_FILE%'); $t=$t -replace \"`r`n\",\"`n\"; [System.IO.File]::WriteAllText('%PKG_FILE%',$t,(New-Object System.Text.UTF8Encoding($false)))"

del LIB.zip

:SKIP_LIB

REM ====================================================
REM STEP: DOWNLOAD HTTP VERSION FOR SHA
REM ====================================================

echo.
echo [4] Downloading remote packages-v1.json...

curl -L -o remote.json "%REMOTE_URL%"

if not exist remote.json (
    echo ERROR downloading remote JSON
    pause
    exit /b 1
)

echo.
echo [5] Calculating SHA256 (HTTP version)...

for /f %%a in ('
powershell -NoProfile -Command "(Get-FileHash 'remote.json' -Algorithm SHA256).Hash.ToLower()"
') do set PKG_HASH=%%a

echo     !PKG_HASH!

REM ====================================================
REM UPDATE repository.json (UTF-8 NO BOM SAFE)
REM ====================================================

echo.
echo [6] Updating repository.json...

rem powershell -NoProfile -Command "$j=Get-Content '%REPO_FILE%' -Raw | ConvertFrom-Json; $j.packages.sha256='!PKG_HASH!'; $j.packages.update_timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $j.packages.update_time_utc=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'); $json=$j | ConvertTo-Json -Depth 20 -Compress; [System.IO.File]::WriteAllText('%REPO_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"
powershell -NoProfile -Command "$j=Get-Content '%REPO_FILE%' -Raw | ConvertFrom-Json; $j.packages.sha256='!PKG_HASH!'; $j.packages.update_timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $j.packages.update_time_utc=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'); $json=$j | ConvertTo-Json -Depth 20; [System.IO.File]::WriteAllText('%REPO_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"
powershell -NoProfile -Command "$t=[System.IO.File]::ReadAllText('%REPO_FILE%'); $t=$t -replace \"`r`n\",\"`n\"; [System.IO.File]::WriteAllText('%REPO_FILE%',$t,(New-Object System.Text.UTF8Encoding($false)))"
del remote.json

echo.
echo ==========================================
echo DONE - KiCad PCM repository updated
echo ==========================================
echo.

pause