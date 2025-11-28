@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo User-level g++ (MinGW-w64) Installer
echo (No admin rights required)
echo ==========================================
echo.

:: 1) Check if g++ already exists (in current session OR user PATH)
where g++ >nul 2>&1
if not errorlevel 1 (
    echo g++ is already available in PATH.
    g++ --version
    echo Installation already complete. Exiting.
    pause
    exit /b 0
)

:: Also check user PATH registry (for new sessions)
for /f "tokens=2* delims= " %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| findstr /i "g++"') do (
    where g++ >nul 2>&1
    if not errorlevel 1 (
        echo g++ is in user PATH (will work in new command prompts).
        echo Close/reopen this window to use it, or run: g++ --version
        pause
        exit /b 0
    )
)

echo Continuing with installation...

:: 2) Set the full path here - EDIT THIS LINE
set "ZIP_PATH=C:\Users\User\Desktop\Codigo\C++\g++ installer\mingw64.zip"

if not exist "%ZIP_PATH%" (
    echo.
    echo File not found: %ZIP_PATH%
    echo Please check the ZIP_PATH variable in this script and try again.
    pause
    exit /b 1
)

:: 3) Choose install directory under user profile
set "INSTALL_DIR=%USERPROFILE%\mingw64"
echo.
echo Install directory: %INSTALL_DIR%

if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

:: 4) Extract zip using PowerShell (Windows 10+)
echo.
echo Extracting archive...
powershell -NoLogo -NoProfile -Command ^
 "Add-Type -AssemblyName 'System.IO.Compression.FileSystem';" ^
 "try {[System.IO.Compression.ZipFile]::ExtractToDirectory('%ZIP_PATH%', '%INSTALL_DIR%'); exit 0} catch {exit 1}"

if errorlevel 1 (
    echo.
    echo Extraction failed. Make sure the file is a valid .zip archive.
    pause
    exit /b 1
)

:: 5) Detect bin folder (more thorough search)
set "MINGW_BIN="

if exist "%INSTALL_DIR%\mingw64\bin\g++.exe" (
    set "MINGW_BIN=%INSTALL_DIR%\mingw64\bin"
) else if exist "%INSTALL_DIR%\bin\g++.exe" (
    set "MINGW_BIN=%INSTALL_DIR%\bin"
) else (
    for /d %%D in ("%INSTALL_DIR%\*") do (
        if exist "%%D\mingw64\bin\g++.exe" (
            set "MINGW_BIN=%%D\mingw64\bin"
            goto found_bin
        )
        if exist "%%D\bin\g++.exe" (
            set "MINGW_BIN=%%D\bin"
            goto found_bin
        )
    )
    :: Even deeper search for common toolchain layouts
    for /d %%D in ("%INSTALL_DIR%\*\*") do (
        if exist "%%D\bin\g++.exe" (
            set "MINGW_BIN=%%D\bin"
            goto found_bin
        )
    )
)

:found_bin
if not defined MINGW_BIN (
    echo.
    echo Could not find g++.exe under: %INSTALL_DIR%
    echo Please check your zip file contains compiler binaries.
    pause
    exit /b 1
)

echo.
echo Found g++ in: %MINGW_BIN%

:: 6) Update user PATH (HKCU, no admin)
echo.
echo Updating user PATH (no admin)...

set "OLD_USER_PATH="
for /f "tokens=2* delims= " %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "OLD_USER_PATH=%%B"
)

if not defined OLD_USER_PATH (
    set "NEW_PATH=%MINGW_BIN%"
) else (
    echo !OLD_USER_PATH! | find /i "%MINGW_BIN%" >nul
    if errorlevel 1 (
        set "NEW_PATH=!OLD_USER_PATH!;%MINGW_BIN%"
    ) else (
        set "NEW_PATH=!OLD_USER_PATH!"
    )
)

setx Path "%NEW_PATH%" >nul

:: Update current session PATH
set "PATH=%PATH%;%MINGW_BIN%"

:: 7) Final verification
echo.
echo Verifying installation...
if exist "%MINGW_BIN%\g++.exe" (
    "%MINGW_BIN%\g++.exe" --version
    echo.
    echo SUCCESS: g++ installed! Open NEW command prompt to use everywhere.
) else (
    echo g++.exe not found after extraction. Check your zip file.
)

echo.
echo Done. Test in new command prompt:
echo g++ --version
echo g++ main.cpp -o main.exe
echo.
pause
endlocal
