@echo off
REM FreeTDS Windows Build Script (x64 Release and Debug)
REM Run from Visual Studio Developer Command Prompt
REM
REM Usage: build-windows.cmd [VS_VERSION] [OPENSSL_PATH]
REM   VS_VERSION: 2017, 2019, or 2022 (default: 2022)
REM   OPENSSL_PATH: Path to OpenSSL installation (optional)

setlocal enabledelayedexpansion

set VS_VERSION=%1
if "%VS_VERSION%"=="" set VS_VERSION=2022

set OPENSSL_PATH=%2

set SCRIPT_DIR=%~dp0
set SOURCE_DIR=%SCRIPT_DIR%..
set BUILD_DIR_RELEASE=%SOURCE_DIR%\build-x64-release
set OUTPUT_DIR=%SOURCE_DIR%\output

echo ========================================
echo FreeTDS Windows Build (x64)
echo ========================================
echo Source Directory: %SOURCE_DIR%
echo Visual Studio Version: %VS_VERSION%
echo.

REM Determine generator
if "%VS_VERSION%"=="2022" (
    set GENERATOR=Visual Studio 17 2022
) else if "%VS_VERSION%"=="2019" (
    set GENERATOR=Visual Studio 16 2019
) else if "%VS_VERSION%"=="2017" (
    set GENERATOR=Visual Studio 15 2017
) else (
    echo Unsupported Visual Studio version: %VS_VERSION%
    exit /b 1
)

REM Check for cmake
where cmake >nul 2>&1
if errorlevel 1 (
    echo CMake not found. Please install CMake or add it to PATH.
    exit /b 1
)

REM Create directories
if not exist "%BUILD_DIR_RELEASE%" mkdir "%BUILD_DIR_RELEASE%"
if not exist "%OUTPUT_DIR%\include\freetds" mkdir "%OUTPUT_DIR%\include\freetds"
if not exist "%OUTPUT_DIR%\lib\x64\Release" mkdir "%OUTPUT_DIR%\lib\x64\Release"
if not exist "%OUTPUT_DIR%\lib\x64\Debug" mkdir "%OUTPUT_DIR%\lib\x64\Debug"
if not exist "%OUTPUT_DIR%\bin\x64\Release" mkdir "%OUTPUT_DIR%\bin\x64\Release"
if not exist "%OUTPUT_DIR%\bin\x64\Debug" mkdir "%OUTPUT_DIR%\bin\x64\Debug"

REM Build CMake options
set CMAKE_OPTIONS=-G "%GENERATOR%" -A x64 -DWITH_OPENSSL=ON -DBUILD_SHARED_LIB=ON
if not "%OPENSSL_PATH%"=="" (
    set CMAKE_OPTIONS=%CMAKE_OPTIONS% -DOPENSSL_ROOT_DIR="%OPENSSL_PATH%"
)

REM Configure
echo.
echo ========================================
echo Configuring...
echo ========================================
cd /d "%BUILD_DIR_RELEASE%"
cmake %CMAKE_OPTIONS% "%SOURCE_DIR%"
if errorlevel 1 (
    echo CMake configuration failed.
    exit /b 1
)

REM Build Release
echo.
echo ========================================
echo Building Release...
echo ========================================
cmake --build . --config Release
if errorlevel 1 (
    echo Release build failed.
    exit /b 1
)

REM Build Debug
echo.
echo ========================================
echo Building Debug...
echo ========================================
cmake --build . --config Debug
if errorlevel 1 (
    echo Debug build failed.
    exit /b 1
)

REM Copy headers
echo.
echo ========================================
echo Copying files...
echo ========================================

REM Source headers
for %%f in (bkpublic.h cspublic.h cstypes.h ctpublic.h sqldb.h sqlfront.h sybdb.h sybfront.h syberror.h) do (
    if exist "%SOURCE_DIR%\include\%%f" copy /y "%SOURCE_DIR%\include\%%f" "%OUTPUT_DIR%\include\" >nul
)

REM FreeTDS headers
for %%f in (export.h server.h tds.h proto.h bytes.h configs.h convert.h data.h encodings.h iconv.h macros.h stream.h tls.h bool.h alloca.h pushvis.h popvis.h thread.h time.h checks.h unused.h) do (
    if exist "%SOURCE_DIR%\include\freetds\%%f" copy /y "%SOURCE_DIR%\include\freetds\%%f" "%OUTPUT_DIR%\include\freetds\" >nul
)

REM Generated headers
if exist "%BUILD_DIR_RELEASE%\include\config.h" copy /y "%BUILD_DIR_RELEASE%\include\config.h" "%OUTPUT_DIR%\include\" >nul
if exist "%BUILD_DIR_RELEASE%\include\tds_sysdep_public.h" copy /y "%BUILD_DIR_RELEASE%\include\tds_sysdep_public.h" "%OUTPUT_DIR%\include\" >nul
if exist "%BUILD_DIR_RELEASE%\include\freetds\version.h" copy /y "%BUILD_DIR_RELEASE%\include\freetds\version.h" "%OUTPUT_DIR%\include\freetds\" >nul
if exist "%BUILD_DIR_RELEASE%\include\freetds\sysdep_types.h" copy /y "%BUILD_DIR_RELEASE%\include\freetds\sysdep_types.h" "%OUTPUT_DIR%\include\freetds\" >nul

REM Release binaries
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.dll" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.dll" "%OUTPUT_DIR%\bin\x64\Release\" >nul
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.lib" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.lib" "%OUTPUT_DIR%\lib\x64\Release\" >nul
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.pdb" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Release\freetds.pdb" "%OUTPUT_DIR%\bin\x64\Release\" >nul

REM Debug binaries
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.dll" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.dll" "%OUTPUT_DIR%\bin\x64\Debug\" >nul
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.lib" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.lib" "%OUTPUT_DIR%\lib\x64\Debug\" >nul
if exist "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.pdb" copy /y "%BUILD_DIR_RELEASE%\src\sharedlib\Debug\freetds.pdb" "%OUTPUT_DIR%\bin\x64\Debug\" >nul

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Output directory: %OUTPUT_DIR%
echo.

cd /d "%SCRIPT_DIR%"
endlocal
