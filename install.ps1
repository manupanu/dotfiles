# Dotfiles One-Line Installer for Windows

$dotfilesDir = Join-Path $HOME ".dotfiles"
$repoUrl = "https://github.com/manupanu/dotfiles.git"

Write-Host "==> Starting dotfiles installation..." -ForegroundColor Blue

# Check for git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Error: git is not installed. Please install git first." -ForegroundColor Red
    exit 1
}

# Clone or update repo
if (Test-Path $dotfilesDir) {
    Write-Host "==> Dotfiles directory already exists at $dotfilesDir. Updating..." -ForegroundColor Blue
    Set-Location $dotfilesDir
    git pull
} else {
    Write-Host "==> Cloning dotfiles to $dotfilesDir..." -ForegroundColor Blue
    git clone $repoUrl $dotfilesDir
    Set-Location $dotfilesDir
}

# Run bootstrap
if (Test-Path ".\bootstrap.ps1") {
    Write-Host "==> Running bootstrap script..." -ForegroundColor Blue
    & ".\bootstrap.ps1"
} else {
    Write-Host "Error: bootstrap.ps1 not found in $dotfilesDir" -ForegroundColor Red
    exit 1
}

Write-Host "==> Installation complete!" -ForegroundColor Green
