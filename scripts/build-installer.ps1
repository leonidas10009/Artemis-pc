param(
    [string]$Root = "",
    [string]$BuildDir = "build\build-x64-release",
    [string]$DeployDir = "dist\ArtemisPortable",
    [string]$Config = "release"
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$version = (Get-Content (Join-Path $Root "app\version.txt") -Raw).Trim()
$deployPath = Join-Path $Root $DeployDir
$buildPath = Join-Path $Root $BuildDir
$staging = Join-Path $Root "build\wix-deploy"
$installerDir = Join-Path $Root "dist\installer"
$releaseDir = Join-Path $Root "Release"

if (-not (Test-Path (Join-Path $buildPath "app\$Config\Artemis.exe"))) {
    throw "Artemis.exe not found. Compile the app first."
}
if (-not (Test-Path $deployPath)) {
    throw "Deploy folder not found. Run scripts\deploy-artemis.ps1 first."
}

$msbuild = (Get-Command msbuild.exe -ErrorAction SilentlyContinue).Source
if (-not $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -requires Microsoft.Component.MSBuild -property installationPath
        if ($vsPath) {
            $msbuild = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        }
    }
}
if (-not $msbuild -or -not (Test-Path $msbuild)) {
    throw "MSBuild not found. Install Visual Studio with the C++ workload or run from a Developer prompt."
}

if (Test-Path $staging) {
    Remove-Item $staging -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $staging | Out-Null
New-Item -ItemType Directory -Force -Path $installerDir | Out-Null
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

# The MSI adds Artemis.exe itself and must not include the portable marker/docs.
robocopy $deployPath $staging /E /XF Artemis.exe portable.dat README.md MEMORIA_ARTEMIS_PC.md LEEME.txt /NFL /NDL /NJH /NJS /NP | Out-Null

$env:DEPLOY_FOLDER = $staging
$env:BUILD_FOLDER = $buildPath
$env:BUILD_ROOT = (Join-Path $Root "build")
$env:BUILD_CONFIG = $Config
$env:INSTALLER_FOLDER = $installerDir

Write-Host "Building MSI..."
& $msbuild (Join-Path $Root "wix\Moonlight\Moonlight.wixproj") /restore "/p:Configuration=$Config" /p:Platform=x64 /v:minimal
if ($LASTEXITCODE -ne 0) {
    throw "MSI build failed"
}

Write-Host "Building setup EXE..."
& $msbuild (Join-Path $Root "wix\MoonlightSetup\MoonlightSetup.wixproj") /restore "/p:Configuration=$Config" /p:Platform=x64 /v:minimal
if ($LASTEXITCODE -ne 0) {
    throw "Setup build failed"
}

$installer = Join-Path $installerDir "ArtemisSetup.exe"
if (-not (Test-Path $installer)) {
    throw "ArtemisSetup.exe was not generated"
}

$out = Join-Path $releaseDir "ArtemisSetup-$version-win64.exe"
Copy-Item $installer $out -Force
$installerHash = (Get-FileHash $out -Algorithm SHA256).Hash
$sumsPath = Join-Path $releaseDir "SHA256SUMS.txt"
"$installerHash  $(Split-Path $out -Leaf)" | Add-Content -Path $sumsPath -Encoding ASCII
Write-Host "Installer: $out"
Write-Host "SHA256: $installerHash"
