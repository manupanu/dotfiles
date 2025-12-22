# Dotfiles Bootstrap Script for Windows

# Ensure Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Installing via winget..." -ForegroundColor Cyan
    winget install Python.Python.3
}

# Developer Mode Check
$devModeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$devMode = Get-ItemProperty -Path $devModeKey -Name "AllowDevelopmentSettings" -ErrorAction SilentlyContinue

if ($null -eq $devMode -or $devMode.AllowDevelopmentSettings -ne 1) {
    Write-Error "Windows Developer Mode is DISABLED. Symlinks require Developer Mode to be created without Administrator privileges."
    Write-Host "Please enable it in: Settings > Update & Security > For developers > Developer Mode" -ForegroundColor Cyan
    Write-Host "Or run this command in an Admin PowerShell:" -ForegroundColor Cyan
    Write-Host "reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' /t REG_DWORD /f /v 'AllowDevelopmentSettings' /d 1" -ForegroundColor Yellow
    exit 1
}

# Run the manager
python "$PSScriptRoot\main.py"
