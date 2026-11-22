@echo off
setlocal enabledelayedexpansion

rem Artemis PC 2026 - build + portable deploy
rem Adjust these two paths if Qt or Visual Studio move.

set "ROOT=%~dp0.."
set "QTDIR=E:\Qt\6.11.3\msvc2022_64"
set "VSDIR=C:\Program Files\Microsoft Visual Studio\18\Community"

set "BUILD=%ROOT%\build\build-x64-release"
set "DEPLOY=%ROOT%\dist\ArtemisPortable"

if not exist "%QTDIR%\bin\qmake.exe" (
    echo Qt not found at "%QTDIR%".
    exit /b 1
)
if not exist "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" (
    echo Visual Studio not found at "%VSDIR%".
    exit /b 1
)

call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b 1

set "PATH=%QTDIR%\bin;%PATH%"

if not exist "%ROOT%\libs\windows\lib\x64" (
    echo Downloading prebuilt dependencies...
    powershell -ExecutionPolicy Bypass -File "%ROOT%\setup-deps.ps1"
    if errorlevel 1 exit /b 1
)

if not exist "%BUILD%" mkdir "%BUILD%"

pushd "%BUILD%"
qmake "%ROOT%\moonlight-qt.pro" CONFIG+=release
if errorlevel 1 goto :error
nmake release
if errorlevel 1 goto :error
popd

rem Deploy with the same script used by CI, so the portable build always gets
rem the official VC++ runtime, licenses and checksums.
powershell -ExecutionPolicy Bypass -File "%ROOT%\scripts\deploy-artemis.ps1" -Root "%ROOT%" -QtRoot "%QTDIR%" -BuildDir "build\build-x64-release"
if errorlevel 1 goto :error

echo.
echo Build OK: %DEPLOY%\Artemis.exe
exit /b 0

:error
echo.
echo Build FAILED.
exit /b 1
