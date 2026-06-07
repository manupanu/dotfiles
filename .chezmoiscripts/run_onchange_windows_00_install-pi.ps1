# Install Pi coding agent on Windows (nvm-windows + npm)

$ErrorActionPreference = "Stop"

if (Get-Command pi -ErrorAction SilentlyContinue) {
    Write-Host "✓ Pi already installed"
    exit 0
}

# Ensure node is available
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Write-Host "No Node.js found — installing latest LTS via nvm..."
        nvm install lts
        nvm use lts
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "No Node.js found — installing nvm via scoop..."
        scoop install nvm
        nvm install lts
        nvm use lts
    } else {
        Write-Host "✗ No node/nvm/scoop found. Install scoop first: https://scoop.sh" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Installing Pi..."
npm install -g @earendil-works/pi-coding-agent

Write-Host "✓ Pi installed"
Write-Host "Run 'pi login' to set up API keys."