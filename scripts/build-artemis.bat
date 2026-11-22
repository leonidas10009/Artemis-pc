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

if exist "%DEPLOY%" rmdir /s /q "%DEPLOY%"
mkdir "%DEPLOY%"

copy "%ROOT%\libs\windows\lib\x64\*.dll" "%DEPLOY%" >nul
copy "%BUILD%\AntiHooking\release\AntiHooking.dll" "%DEPLOY%" >nul
copy "%ROOT%\app\SDL_GameControllerDB\gamecontrollerdb.txt" "%DEPLOY%" >nul
copy "%BUILD%\app\release\Artemis.exe" "%DEPLOY%" >nul

windeployqt --dir "%DEPLOY%" --release --qmldir "%ROOT%\app\gui" ^
  --no-opengl-sw --no-compiler-runtime --no-sql ^
  --no-system-d3d-compiler --no-system-dxc-compiler --no-ffmpeg ^
  --skip-plugin-types qmltooling,generic ^
  --no-quickcontrols2fusion --no-quickcontrols2imagine --no-quickcontrols2universal ^
  --no-quickcontrols2fusionstyleimpl --no-quickcontrols2imaginestyleimpl ^
  --no-quickcontrols2universalstyleimpl --no-quickcontrols2windowsstyleimpl ^
  --no-quickcontrols2fluentwinui3styleimpl ^
  "%DEPLOY%\Artemis.exe"
if errorlevel 1 goto :error

rem Copy the Visual C++ runtime DLLs so the portable build works on clean PCs
for %%F in (msvcp140.dll msvcp140_1.dll msvcp140_2.dll msvcp140_atomic_wait.dll msvcp140_codecvt_ids.dll vcruntime140.dll vcruntime140_1.dll vcruntime140_threads.dll concrt140.dll) do (
    if exist "%SystemRoot%\System32\%%F" copy "%SystemRoot%\System32\%%F" "%DEPLOY%" >nul
)

rem Portable mode: settings live next to Artemis.exe
type nul > "%DEPLOY%\portable.dat"

echo.
echo Build OK: %DEPLOY%\Artemis.exe
exit /b 0

:error
echo.
echo Build FAILED.
exit /b 1
