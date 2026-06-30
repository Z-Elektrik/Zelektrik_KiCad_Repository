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
REM OPTIONAL: UPDATE LIB ZIP SHA
REM ====================================================

echo.
set /p DOZIP=Update LIB.zip SHA256? (y/n):

if /i "!DOZIP!"=="y" (

    echo.
    echo [1] Downloading LIB.zip...

    curl -L -o LIB.zip ^
    https://github.com/Z-Elektrik/LIB/archive/refs/heads/main.zip

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

    powershell -NoProfile -ExecutionPolicy Bypass -Command "$j=Get-Content '%PKG_FILE%' -Raw | ConvertFrom-Json; $j.packages[0].versions[0].download_sha256='!ZIP_HASH!'; $j | ConvertTo-Json -Depth 20 -Compress | Set-Content -Encoding utf8 '%PKG_FILE%'"

    del LIB.zip
)

REM ====================================================
REM STEP: HASH MUST BE FROM HTTP VERSION (IMPORTANT)
REM ====================================================

echo.
echo [4] Downloading remote packages-v1.json for SHA check...

curl -L -o remote_packages.json "%REMOTE_URL%"

if not exist remote_packages.json (
    echo ERROR: cannot download remote packages-v1.json
    pause
    exit /b 1
)

echo.
echo [5] Calculating remote SHA256...

for /f %%a in ('
    powershell -NoProfile -Command "(Get-FileHash 'remote_packages.json' -Algorithm SHA256).Hash.ToLower()"
') do set PKG_HASH=%%a

echo     !PKG_HASH!

REM ====================================================
REM UPDATE repository.json
REM ====================================================

echo.
echo [6] Updating repository.json...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$j=Get-Content '%REPO_FILE%' -Raw | ConvertFrom-Json; $j.packages.sha256='!PKG_HASH!'; $j.packages.update_timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $j.packages.update_time_utc=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'); $j | ConvertTo-Json -Depth 20 -Compress | Set-Content -Encoding utf8 '%REPO_FILE%'"

del remote_packages.json

echo.
echo ==========================================
echo DONE - PCM repository updated correctly
echo ==========================================
echo.
echo NEXT:
echo git add .
echo git commit -m "Update PCM metadata"
echo git push
echo.

pause