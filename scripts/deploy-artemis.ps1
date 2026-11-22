param(
    [string]$Root = "",
    [string]$QtRoot = "C:\Qt\6.11.3\msvc2022_64",
    [string]$BuildDir = "build\ci",
    [string]$Config = "release"
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$QtBin = Join-Path $QtRoot "bin"
$BuildPath = Join-Path $Root $BuildDir
$Deploy = Join-Path $Root "dist\ArtemisPortable"
$Release = Join-Path $Root "Release"
$Exe = Join-Path $BuildPath "app\$Config\Artemis.exe"

if (-not (Test-Path $Exe)) {
    throw "Artemis.exe not found at $Exe"
}

if (Test-Path $Deploy) {
    Remove-Item $Deploy -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Deploy | Out-Null
New-Item -ItemType Directory -Force -Path $Release | Out-Null

Copy-Item (Join-Path $Root "libs\windows\lib\x64\*.dll") $Deploy
Copy-Item (Join-Path $BuildPath "AntiHooking\$Config\AntiHooking.dll") $Deploy
Copy-Item (Join-Path $Root "app\SDL_GameControllerDB\gamecontrollerdb.txt") $Deploy
Copy-Item $Exe $Deploy
Copy-Item (Join-Path $Root "README.md") $Deploy
Copy-Item (Join-Path $Root "MEMORIA_ARTEMIS_PC.md") $Deploy
Copy-Item (Join-Path $Root "LEEME.txt") $Deploy

$runtimeDlls = @(
    "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll", "msvcp140_atomic_wait.dll",
    "msvcp140_codecvt_ids.dll", "vcruntime140.dll", "vcruntime140_1.dll",
    "vcruntime140_threads.dll", "concrt140.dll"
)
foreach ($dll in $runtimeDlls) {
    $source = Join-Path $env:SystemRoot "System32\$dll"
    if (Test-Path $source) {
        Copy-Item $source $Deploy
    }
}

& (Join-Path $QtBin "windeployqt.exe") `
    --dir $Deploy --release --qmldir (Join-Path $Root "app\gui") `
    --no-opengl-sw --no-compiler-runtime --no-sql `
    --no-system-d3d-compiler --no-system-dxc-compiler --no-ffmpeg `
    --skip-plugin-types qmltooling,generic `
    --no-quickcontrols2fusion --no-quickcontrols2imagine --no-quickcontrols2universal `
    --no-quickcontrols2fusionstyleimpl --no-quickcontrols2imaginestyleimpl `
    --no-quickcontrols2universalstyleimpl --no-quickcontrols2windowsstyleimpl `
    --no-quickcontrols2fluentwinui3styleimpl `
    (Join-Path $Deploy "Artemis.exe")
if ($LASTEXITCODE -ne 0) {
    throw "windeployqt failed"
}

New-Item -ItemType File -Force -Path (Join-Path $Deploy "portable.dat") | Out-Null

$version = (Get-Content (Join-Path $Root "app\version.txt") -Raw).Trim()
$zip = Join-Path $Release "Artemis-$version-win64.zip"
if (Test-Path $zip) {
    Remove-Item $zip -Force
}
Compress-Archive -Path (Join-Path $Deploy "*") -DestinationPath $zip -CompressionLevel Optimal

Write-Host "Portable build: $zip"
Write-Host "SHA256: $((Get-FileHash $zip -Algorithm SHA256).Hash)"
