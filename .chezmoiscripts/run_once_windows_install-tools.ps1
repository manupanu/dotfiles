# Install Starship and zoxide via scoop on Windows

$ErrorActionPreference = "Stop"

$tools = @(
    @{ Name = "starship"; Scoop = "starship" },
    @{ Name = "zoxide";  Scoop = "zoxide" }
)

foreach ($tool in $tools) {
    if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
        Write-Host "✓ $($tool.Name) already installed"
    } else {
        Write-Host "Installing $($tool.Name)..."
        scoop install $tool.Scoop
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Failed to install $($tool.Name)" -ForegroundColor Red
            exit 1
        }
        Write-Host "✓ $($tool.Name) installed"
    }
}