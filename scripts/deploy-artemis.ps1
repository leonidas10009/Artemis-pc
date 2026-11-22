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
Copy-Item (Join-Path $Root "LICENSE") $Deploy
Copy-Item (Join-Path $Root "THIRD_PARTY_NOTICES.md") $Deploy

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

# Copy the VC++ runtime from the official redistributable directory. Do not
# copy it from System32: that is not a supported redistributable source and can
# mix runtime versions.
$crtSource = $null
if ($env:VCToolsRedistDir) {
    $crtSource = Get-ChildItem (Join-Path $env:VCToolsRedistDir "x64") -Directory -Filter "Microsoft.VC*.CRT" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $crtSource) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = (& $vswhere -latest -property installationPath 2>$null).Trim()
        if ($vsPath) {
            $redistRoot = Join-Path $vsPath "VC\Redist\MSVC"
            if (Test-Path $redistRoot) {
                foreach ($versionDir in (Get-ChildItem $redistRoot -Directory | Sort-Object Name -Descending)) {
                    $candidate = Get-ChildItem (Join-Path $versionDir.FullName "x64") -Directory -Filter "Microsoft.VC*.CRT" -ErrorAction SilentlyContinue |
                        Select-Object -First 1 -ExpandProperty FullName
                    if ($candidate) {
                        $crtSource = $candidate
                        break
                    }
                }
            }
        }
    }
}

if (-not $crtSource -or -not (Test-Path $crtSource)) {
    throw "VC++ redistributable CRT directory not found. Install the Visual Studio C++ workload or run from a Developer prompt."
}

Copy-Item (Join-Path $crtSource "*.dll") $Deploy -Force

New-Item -ItemType File -Force -Path (Join-Path $Deploy "portable.dat") | Out-Null

$version = (Get-Content (Join-Path $Root "app\version.txt") -Raw).Trim()
$zip = Join-Path $Release "Artemis-$version-win64.zip"
if (Test-Path $zip) {
    Remove-Item $zip -Force
}
Compress-Archive -Path (Join-Path $Deploy "*") -DestinationPath $zip -CompressionLevel Optimal

# Build provenance. The release workflow publishes these files next to the
# assets so users can verify what produced the binaries.
$commit = "unknown"
try {
    $commit = (& git -C $Root rev-parse --short HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $commit) {
        $commit = "unknown"
    }
    else {
        $dirty = (& git -C $Root status --porcelain 2>$null)
        if ($dirty) {
            $commit = "$commit-dirty"
        }
    }
} catch {
    $commit = "unknown"
}

$qtVersion = (& (Join-Path $QtBin "qmake.exe") -query QT_VERSION 2>$null).Trim()
$msvcVersion = $env:VCToolsVersion
if (-not $msvcVersion) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = (& $vswhere -latest -property installationPath 2>$null).Trim()
        $msvcRoot = Join-Path $vsPath "VC\Tools\MSVC"
        if (Test-Path $msvcRoot) {
            $msvcVersion = (Get-ChildItem $msvcRoot -Directory |
                Sort-Object Name -Descending | Select-Object -First 1).Name
        }
    }
}
if (-not $msvcVersion) {
    $msvcVersion = "unknown"
}

$buildInfo = @"
Product: Artemis PC 2026
Version: $version
Commit: $commit
Build date (UTC): $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
Qt: $qtVersion
MSVC: $msvcVersion
"@
Set-Content -Path (Join-Path $Release "BUILD_INFO.txt") -Value $buildInfo -Encoding UTF8

$zipHash = (Get-FileHash $zip -Algorithm SHA256).Hash
"$zipHash  $(Split-Path $zip -Leaf)" | Set-Content -Path (Join-Path $Release "SHA256SUMS.txt") -Encoding ASCII

Write-Host "Portable build: $zip"
Write-Host "SHA256: $zipHash"
Write-Host "Build info: $(Join-Path $Release 'BUILD_INFO.txt')"
