@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   ZElektrik KiCad PCM AUTO UPDATER
echo ==========================================
echo.

REM ===== CONFIG =====
set REPO_URL=https://z-elektrik.github.io/Zelektrik_KiCad_Repository
set JSON_URL=%REPO_URL%/packages-v1.json

set REPO_FILE=repository.json
set PKG_FILE=packages-v1.json

REM ===== DOWNLOAD latest packages-v1.json =====
echo [1] Downloading packages-v1.json...
curl -L -o %PKG_FILE% %JSON_URL%

if not exist %PKG_FILE% (
    echo ERROR: cannot download packages-v1.json
    pause
    exit /b 1
)

REM ===== SHA256 packages-v1.json =====
echo [2] Calculating SHA256 of packages-v1.json...

for /f "tokens=2 delims=:" %%a in ('certutil -hashfile %PKG_FILE% SHA256 ^| findstr /r "^[0-9a-f]"') do set PKG_HASH=%%a
set PKG_HASH=%PKG_HASH: =%

echo     %PKG_HASH%

REM ===== UPDATE repository.json =====
echo [3] Updating repository.json...

powershell -NoProfile -Command "$json = Get-Content '%REPO_FILE%' -Raw; $json = $json -replace '\"sha256\"\s*:\s*\"[a-f0-9]*\"', '\"sha256\": \"%PKG_HASH%\"'; Set-Content -Path '%REPO_FILE%' -Value $json"

REM ===== OPTIONAL LIB ZIP HASH =====
echo.
set /p DOZIP=Do you want update LIB.zip SHA256? (y/n): 

if /i "%DOZIP%"=="y" (
    echo [4] Downloading LIB zip...
    curl -L -o LIB.zip https://github.com/Z-Elektrik/LIB/archive/refs/heads/main.zip

    echo [5] Calculating LIB.zip SHA256...

    for /f "tokens=2 delims=:" %%a in ('certutil -hashfile LIB.zip SHA256 ^| findstr /r "^[0-9a-f]"') do set ZIP_HASH=%%a
    set ZIP_HASH=%ZIP_HASH: =%

    echo     %ZIP_HASH%

    echo [6] Updating packages-v1.json...

    powershell -NoProfile -Command "$json = Get-Content '%PKG_FILE%' -Raw; $json = $json -replace '\"download_sha256\"\s*:\s*\"[a-f0-9]*\"', '\"download_sha256\": \"%ZIP_HASH%\"'; Set-Content -Path '%PKG_FILE%' -Value $json"
)

echo.
echo ==========================================
echo DONE - JSON files updated
echo ==========================================
pause