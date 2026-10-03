@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo ============================================================
echo  BinPy Compiler
echo ============================================================
echo.

set "BINPY=%~1"

if "%BINPY%"=="" (
    echo Available .binpy files:
    echo.
    set "COUNT=0"
    for %%F in ("%SCRIPT_DIR%*.binpy") do (
        set /a COUNT+=1
        echo   !COUNT!. %%~nxF
        set "FILE_!COUNT!=%%~nxF"
    )
    if !COUNT!==0 echo   (no .binpy files found)
    echo.
    set /p "BINPY=Enter .binpy file name or number: "
)

REM --- Trim spaces ---
for /f "tokens=* delims= " %%A in ("!BINPY!") do set "BINPY=%%A"

REM --- If number chosen, get file name from list ---
set "ISNUM=1"
for /f "delims=0123456789" %%A in ("!BINPY!") do set "ISNUM="
if defined ISNUM if defined FILE_!BINPY! set "BINPY=!FILE_%BINPY%!"

REM --- Add .binpy extension if missing ---
if /I not "!BINPY:~-6!"==".binpy" set "BINPY=!BINPY!.binpy"

REM --- Resolve full path of the .binpy ---
set "FULLPATH="
for %%F in ("!BINPY!") do set "FULLPATH=%%~fF"

if not defined FULLPATH (
    echo.
    echo [ERROR] Cannot resolve path for: !BINPY!
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

REM --- Output folder for build artifacts ---
set "OUTDIR=%SCRIPT_DIR%compile"
if not exist "!OUTDIR!" mkdir "!OUTDIR!"

set "RESTORED=!OUTDIR!\!NAME!_restored.py"

echo.
echo ============================================================
echo  Compiling: !FULLPATH!
echo ============================================================
echo  Output dir: !OUTDIR!
echo ============================================================
echo.

set "MAKE_EXE="
set /p "MAKE_EXE=Build .exe too? (y/N): "
if /I "!MAKE_EXE!"=="y" (set "MAKE_EXE=exe") else (set "MAKE_EXE=")

echo [1/3] Restoring Python source...
python "%SCRIPT_DIR%binpy.py" restore "!FULLPATH!" "!RESTORED!"
if errorlevel 1 goto :fail

echo.
echo [2/3] Compiling to .pyc...
python "%SCRIPT_DIR%binpy.py" compile "!RESTORED!"
if errorlevel 1 goto :fail

if /I "!MAKE_EXE!"=="exe" (
    echo.
    echo [3/3] Building .exe with PyInstaller...

    python -c "import PyInstaller" >nul 2>nul
    if errorlevel 1 (
        echo [WARN] PyInstaller not found, installing...
        python -m pip install --quiet --disable-pip-version-check pyinstaller
    )

    python -m PyInstaller --onefile --noconfirm --clean --distpath "!OUTDIR!\dist" --workpath "!OUTDIR!\build" --specpath "!OUTDIR!" "!RESTORED!"
    if errorlevel 1 goto :fail

    echo.
    echo [OK] EXE: !OUTDIR!\dist\!NAME!_restored.exe
) else (
    echo.
    echo [3/3] Skipping .exe build.
)

echo.
echo ============================================================
echo  DONE
echo ============================================================
echo  Folder:          !OUTDIR!
echo  Restored Python: !OUTDIR!\!NAME!_restored.py
echo  Compiled .pyc:   !OUTDIR!\__pycache__\!NAME!_restored.*.pyc
if /I "!MAKE_EXE!"=="exe" echo  EXE file:        !OUTDIR!\dist\!NAME!_restored.exe
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Failed. Code: %errorlevel%
pause
exit /b %errorlevel%