#Requires -Version 5.1
# Installs the CLI tools referenced by the PowerShell profile/aliases via scoop.
# Safe to re-run: skips any tool whose command is already on PATH, and tolerates
# scoop exiting non-zero for tools that are already installed.

$ErrorActionPreference = "Stop"

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "scoop not found, skipping package install."
    exit 0
}

# Some packages (e.g. yazi) live in the "extras" bucket rather than "main".
$buckets = @("main", "extras")
$knownBuckets = @(scoop bucket list | ForEach-Object { $_.Name })
foreach ($bucket in $buckets) {
    if ($knownBuckets -notcontains $bucket) {
        Write-Host "Adding scoop bucket: $bucket"
        scoop bucket add $bucket
    }
}

# Package name, the command it exposes on PATH once installed, and the bucket
# it lives in (for logging/reference only; scoop resolves it automatically).
$packages = @(
    @{ Name = "starship"; Command = "starship"; Bucket = "main" },
    @{ Name = "zoxide"; Command = "zoxide"; Bucket = "main" },
    @{ Name = "fzf"; Command = "fzf"; Bucket = "main" },
    @{ Name = "yazi"; Command = "yazi"; Bucket = "extras" },
    @{ Name = "git"; Command = "git"; Bucket = "main" },
    @{ Name = "gh"; Command = "gh"; Bucket = "main" }
)

foreach ($pkg in $packages) {
    if (Get-Command $pkg.Command -ErrorAction SilentlyContinue) {
        Write-Host "$($pkg.Name) already available on PATH, skipping."
        continue
    }

    Write-Host "Installing $($pkg.Name) (bucket: $($pkg.Bucket))..."
    try {
        scoop install $pkg.Name
    } catch {
        Write-Host "Warning: scoop install for $($pkg.Name) failed: $_" -ForegroundColor Yellow
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: scoop install for $($pkg.Name) exited with code $LASTEXITCODE" -ForegroundColor Yellow
    }
}
