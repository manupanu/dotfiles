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
    Write-Warning "Windows Developer Mode is DISABLED. Symlinks might require Admin or fail."
    Write-Host "You can enable it in: Settings > Update & Security > For developers > Developer Mode"
    Write-Host "Or run this command in an Admin PowerShell:"
    Write-Host "reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' /t REG_DWORD /f /v 'AllowDevelopmentSettings' /d 1" -ForegroundColor Yellow
}

# Run the manager
python "$PSScriptRoot\main.py"
