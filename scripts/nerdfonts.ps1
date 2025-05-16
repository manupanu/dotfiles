# Install Scoop if not already installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Scoop not found. Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
} else {
    Write-Host "Scoop is already installed."
}

# Ensure git is installed (required for buckets)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing git via Scoop..."
    scoop install git
} else {
    Write-Host "Git is already installed."
}

# Add nerd-fonts bucket if not already added
if (-not (scoop bucket list | Select-String 'nerd-fonts')) {
    Write-Host "Adding nerd-fonts bucket..."
    scoop bucket add nerd-fonts
} else {
    Write-Host "nerd-fonts bucket already added."
}

# Install JetBrainsMono Nerd Font (correct manifest name is 'jetbrainsmono-nf')
if (-not (scoop list | Select-String 'jetbrainsmono-nf')) {
    Write-Host "Installing JetBrainsMono Nerd Font..."
    scoop install jetbrainsmono-nf
} else {
    Write-Host "JetBrainsMono Nerd Font is already installed."
}