@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo   ZElektrik KiCad PCM AUTO UPDATER
echo ==========================================
echo.

REM ===== CONFIG =====
set REPO_FILE=repository.json
set PKG_FILE=packages-v1.json

if not exist "repository_template.json" (
    echo ERROR: repository_template.json not found
    pause
    exit /b 1
)

if not exist "packages-v1_template.json" (
    echo ERROR: packages-v1_template.json not found
    pause
    exit /b 1
)

echo [0] Creating fresh JSON files from templates...

copy /Y repository_template.json repository.json >nul
copy /Y packages-v1_template.json packages-v1.json >nul

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
echo [2a] Calculating LIB.zip size...

for %%A in (LIB.zip) do set ZIP_SIZE=%%~zA

echo     !ZIP_SIZE! bytes

echo.
echo [2b] Calculating install size (ZIP entries sum)...

for /f %%a in ('
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead('LIB.zip'); $s=($z.Entries | Measure-Object Length -Sum).Sum; $z.Dispose(); Write-Output $s"
') do set INSTALL_SIZE=%%a

if not defined INSTALL_SIZE set INSTALL_SIZE=0
if "!INSTALL_SIZE!"=="" set INSTALL_SIZE=0

echo     !INSTALL_SIZE! bytes

echo.
echo [3] Updating packages-v1.json...

powershell -NoProfile -Command "$j=Get-Content '%PKG_FILE%' -Raw | ConvertFrom-Json; $v=$j.packages[0].versions[0]; $v.download_sha256='!ZIP_HASH!'; $v.download_size=!ZIP_SIZE!; $v.install_size=!INSTALL_SIZE!; $json=$j | ConvertTo-Json -Depth 20; [System.IO.File]::WriteAllText('%PKG_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"

REM normalize LF
powershell -NoProfile -Command "$t=[System.IO.File]::ReadAllText('%PKG_FILE%'); $t=$t -replace '`r`n','`n'; [System.IO.File]::WriteAllText('%PKG_FILE%',$t,(New-Object System.Text.UTF8Encoding($false)))"

del LIB.zip

:SKIP_LIB

REM ====================================================
REM CALCULATE SHA256 OF LOCAL packages-v1.json
REM ====================================================

echo.
echo [4] Calculating SHA256 of local packages-v1.json...

for /f %%a in ('
powershell -NoProfile -Command "(Get-FileHash '%PKG_FILE%' -Algorithm SHA256).Hash.ToLower()"
') do set PKG_HASH=%%a

echo     !PKG_HASH!

REM ====================================================
REM UPDATE repository.json
REM ====================================================

echo.
echo [5] Updating repository.json...

powershell -NoProfile -Command "$j=Get-Content '%REPO_FILE%' -Raw | ConvertFrom-Json; $j.packages.sha256='!PKG_HASH!'; $j.packages.update_timestamp=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); $j.packages.update_time_utc=(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'); $json=$j | ConvertTo-Json -Depth 20; [System.IO.File]::WriteAllText('%REPO_FILE%',$json,(New-Object System.Text.UTF8Encoding($false)))"

REM normalize LF
powershell -NoProfile -Command "$t=[System.IO.File]::ReadAllText('%REPO_FILE%'); $t=$t -replace '`r`n','`n'; [System.IO.File]::WriteAllText('%REPO_FILE%',$t,(New-Object System.Text.UTF8Encoding($false)))"

echo.
echo ==========================================
echo DONE - KiCad PCM repository updated
echo ==========================================
echo.

pause