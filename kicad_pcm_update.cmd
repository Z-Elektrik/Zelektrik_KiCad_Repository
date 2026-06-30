@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo   ZElektrik KiCad PCM AUTO UPDATER
echo ==========================================
echo.

REM ===== CONFIG =====
set REPO_FILE=repository.json
set PKG_FILE=packages-v1.json

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
    ') do (
        set ZIP_HASH=%%a
    )

    echo     !ZIP_HASH!

    echo.
    echo [3] Updating packages-v1.json...

    powershell -NoProfile -Command "$j=Get-Content '%PKG_FILE%' -Raw | ConvertFrom-Json; $j.packages[0].versions[0].download_sha256='!ZIP_HASH!'; $j | ConvertTo-Json -Depth 20 | Set-Content '%PKG_FILE%'"

    del LIB.zip
)

echo.
echo [4] Calculating packages-v1.json SHA256...

for /f %%a in ('
powershell -NoProfile -Command "(Get-FileHash '%PKG_FILE%' -Algorithm SHA256).Hash.ToLower()"
') do (
    set PKG_HASH=%%a
)

echo     !PKG_HASH!

echo.
echo [5] Updating repository.json...

powershell -NoProfile -Command "$j=Get-Content '%REPO_FILE%' -Raw | ConvertFrom-Json; $j.packages.sha256='!PKG_HASH!'; $j.packages.update_timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $j.packages.update_time_utc=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'); $j | ConvertTo-Json -Depth 20 | Set-Content '%REPO_FILE%'"

echo.
echo ==========================================
echo DONE
echo ==========================================
echo.
echo git add .
echo git commit -m "Update PCM metadata"
echo git push
echo.

pause