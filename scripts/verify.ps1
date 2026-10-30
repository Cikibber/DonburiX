# Runs the DonburiX mobile quality gates.
# Agent sessions in this workspace have no shell tool; run this from a normal terminal.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root 'apps/mobile'

Write-Host "[verify] repo:   $root"
Write-Host "[verify] mobile: $mobile"

if (-not (Test-Path $mobile)) {
    throw "[verify] missing directory: $mobile"
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    throw "[verify] flutter is not on PATH. Install Flutter or open a shell where 'flutter --version' works."
}
Write-Host "[verify] flutter: $($flutter.Source)"

function Invoke-Gate {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )

    Write-Host ""
    Write-Host "[verify] ==> $Name" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "[verify] FAILED: $Name (exit $LASTEXITCODE)"
    }
    Write-Host "[verify] ok: $Name" -ForegroundColor Green
}

Push-Location $mobile
try {
    Invoke-Gate 'flutter pub get' { flutter pub get }
    Invoke-Gate 'dart format check' { dart format --output=none --set-exit-if-changed lib test }
    Invoke-Gate 'flutter analyze' { flutter analyze }
    Invoke-Gate 'flutter test' { flutter test --coverage }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "[verify] ALL GATES PASSED" -ForegroundColor Green
