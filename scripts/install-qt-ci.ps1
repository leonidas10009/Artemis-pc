param(
    [string]$Target = "C:\Qt\6.11.3\msvc2022_64"
)

$ErrorActionPreference = "Stop"

if (Test-Path (Join-Path $Target "bin\qmake.exe")) {
    Write-Host "Qt already installed at $Target"
    if ($env:GITHUB_PATH) { Add-Content $env:GITHUB_PATH (Join-Path $Target "bin") }
    exit 0
}

$base = "https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt6_6113/qt6_6113_msvc2022_64/qt.qt6.6113.win64_msvc2022_64"
$prefix = "6.11.3-0-202610220312"
$archives = @(
    "qtbase-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "qtsvg-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "qtdeclarative-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "qtdoc-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "qttools-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "qttranslations-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
    "d3dcompiler_47-x64.7z",
    "opengl32sw-64-mesa_11_2_2-signed_sha256.7z"
)

$sevenZip = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source
if (-not $sevenZip) {
    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
}
if (-not (Test-Path $sevenZip)) {
    throw "7-Zip not found. Install 7-Zip or make 7z.exe available in PATH."
}

$tmpRoot = $env:RUNNER_TEMP
if (-not $tmpRoot) { $tmpRoot = $env:TEMP }
$downloadDir = Join-Path $tmpRoot "qt-downloads"
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
New-Item -ItemType Directory -Force -Path $Target | Out-Null

foreach ($archive in $archives) {
    $fileName = $prefix + $archive
    $path = Join-Path $downloadDir $fileName
    if (-not (Test-Path $path)) {
        Write-Host "Downloading $archive"
        curl.exe -sS -L -f -o $path "$base/$fileName"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download $archive"
        }
    }

    Write-Host "Extracting $archive"
    & $sevenZip x -y "-o$Target" $path | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to extract $archive"
    }
}

if (-not (Test-Path (Join-Path $Target "bin\qmake.exe"))) {
    throw "Qt installation did not produce qmake.exe"
}

if ($env:GITHUB_PATH) {
    Add-Content $env:GITHUB_PATH (Join-Path $Target "bin")
}

Write-Host "Qt 6.11.3 ready at $Target"
