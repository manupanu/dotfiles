# Install Pi packages from settings.json on Windows

$ErrorActionPreference = "Stop"

if (-not (Get-Command pi -ErrorAction SilentlyContinue)) {
    Write-Host "Pi not found — installing Pi first..."
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $piScript = Join-Path $scriptDir "run_onchange_00_install-pi.ps1"
    if (Test-Path $piScript) {
        & $piScript
    } else {
        Write-Host "✗ Pi install script not found." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Installing Pi packages from settings..."
pi update --extensions