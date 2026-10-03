@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo ============================================================
echo  BinPy Builder  (.py -^> .binpy)
echo ============================================================
echo.

set "PYS=%~1"

if "%PYS%"=="" (
    echo Available .py files:
    echo.
    set "COUNT=0"
    for %%F in ("%SCRIPT_DIR%*.py") do (
        set /a COUNT+=1
        echo   !COUNT!. %%~nxF
        set "FILE_!COUNT!=%%~nxF"
    )
    if !COUNT!==0 echo   (no .py files found)
    echo.
    set /p "PYS=Enter .py file name or number: "
)

REM --- Trim spaces ---
for /f "tokens=* delims= " %%A in ("!PYS!") do set "PYS=%%A"

REM --- If number chosen, get file name from list ---
set "ISNUM=1"
for /f "delims=0123456789" %%A in ("!PYS!") do set "ISNUM="
if defined ISNUM if defined FILE_!PYS! set "PYS=!FILE_%PYS%!"

REM --- Add .py extension if missing ---
if /I not "!PYS:~-3!"==".py" set "PYS=!PYS!.py"

REM --- Resolve full path of the .py ---
set "FULLPATH="
for %%F in ("!PYS!") do set "FULLPATH=%%~fF"

if not defined FULLPATH (
    echo.
    echo [ERROR] Cannot resolve path for: !PYS!
    pause
    exit /b 1
)

if not exist "!FULLPATH!" (
    echo.
    echo [ERROR] File not found: !FULLPATH!
    pause
    exit /b 1
)

where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python not found in PATH.
    pause
    exit /b 1
)

REM --- File name without extension ---
for %%F in ("!FULLPATH!") do set "NAME=%%~nF"

REM --- Output .binpy next to the batch file ---
set "BINPY=%SCRIPT_DIR%!NAME!.binpy"

REM --- Ask before overwriting an existing file ---
if exist "!BINPY!" (
    echo.
    echo [WARN] File already exists: !BINPY!
    set "OVERWRITE="
    set /p "OVERWRITE=Overwrite? (y/N): "
    if /I not "!OVERWRITE!"=="y" (
        echo Cancelled.
        pause
        exit /b 0
    )
)

echo.
echo ============================================================
echo  Building: !FULLPATH!
echo ============================================================
echo  Output:   !BINPY!
echo ============================================================
echo.

echo [1/2] Encoding Python source to binary text...
python "%SCRIPT_DIR%binpy.py" build "!FULLPATH!" "!BINPY!"
if errorlevel 1 goto :fail

echo.
echo [2/2] Verifying round-trip...
python "%SCRIPT_DIR%verify.py" "!FULLPATH!" "!BINPY!"
if errorlevel 1 goto :fail

echo.
echo ============================================================
echo  DONE
echo ============================================================
echo  .binpy file: !BINPY!
echo.
echo  Next step:
echo    compile.bat !NAME!
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Failed. Code: %errorlevel%
pause
exit /b %errorlevel%