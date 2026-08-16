[CmdletBinding()]
param(
    [string]$OutputPath,
    # Defaults keep the documented S140 bridge invocation unchanged. The USB
    # HID milestone builds the same way with a different binary and feature.
    [ValidateSet('ukf-xiao-s140-bridge', 'ukf-xiao-usb-hid', 'ukf-xiao-ble-probe')]
    [string]$Binary = 'ukf-xiao-s140-bridge',
    [string]$Features
)

$ErrorActionPreference = 'Stop'
$crateRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Resolve-Path (Join-Path $crateRoot '..\..')
$manifestPath = Join-Path $repoRoot 'Cargo.toml'
$targetDirectory = Join-Path $repoRoot 'target'
$targetTriple = 'thumbv7em-none-eabihf'
$binaryName = $Binary
if (-not $Features) {
    $Features = switch ($Binary) {
        'ukf-xiao-usb-hid' { 'xiao-usb-hid-hardware' }
        'ukf-xiao-ble-probe' { 'xiao-ble-hardware' }
        default { 's140-hardware' }
    }
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot "target\$targetTriple\release\$binaryName.uf2"
}
$output = [System.IO.Path]::GetFullPath($OutputPath)
$rawBinary = [System.IO.Path]::ChangeExtension($output, '.bin')
$elf = Join-Path $repoRoot "target\$targetTriple\release\$binaryName"

# Build from a temporary directory and point Cargo at this worktree explicitly.
# Cargo merges `.cargo/config.toml` files from the current directory and every
# ancestor. A linked worktree can therefore inherit a stale `rustflags` entry
# from the parent checkout even when this worktree's config is correct. The
# firmware build script is the single owner of `-Tlink.x`; keeping Cargo
# outside the repository hierarchy prevents a second linker argument from
# being inherited while `--manifest-path` and `--target-dir` keep all inputs
# and outputs tied to this worktree.
$cargoIsolationDirectory = [System.IO.Path]::GetTempPath()
Push-Location $cargoIsolationDirectory
try {
    & cargo build --release `
        --manifest-path $manifestPath `
        --target-dir $targetDirectory `
        --target $targetTriple -p ukf-nrf52840-ble-usb --features $Features `
        --bin $binaryName
    if ($LASTEXITCODE -ne 0) { throw 'cross-compilation failed' }
}
finally {
    Pop-Location
}

$rustSysroot = (& rustc --print sysroot).Trim()
$objcopy = Get-ChildItem -Path (Join-Path $rustSysroot 'lib\rustlib') `
    -Recurse -Filter 'llvm-objcopy.exe' | Select-Object -First 1
if (-not $objcopy) {
    throw 'llvm-objcopy not found; run: rustup component add llvm-tools'
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
& $objcopy.FullName -O binary $elf $rawBinary
if ($LASTEXITCODE -ne 0) { throw 'ELF-to-binary conversion failed' }

$python = Get-Command py -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python -ErrorAction Stop }
& $python.Source (Join-Path $PSScriptRoot 'xiao_uf2.py') pack $rawBinary $output
if ($LASTEXITCODE -ne 0) { throw 'UF2 packaging failed' }
& $python.Source (Join-Path $PSScriptRoot 'xiao_uf2.py') check $output
if ($LASTEXITCODE -ne 0) { throw 'UF2 validation failed' }

Write-Host "Host-only artifact created: $output"
Write-Warning 'This image has not yet passed physical BLE/USB validation; preserve CURRENT.UF2 before writing.'
