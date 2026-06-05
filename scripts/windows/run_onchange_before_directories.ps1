# Create necessary directories on Windows

$dirs = @(
    "$env:USERPROFILE\scoop\shims",
    "$env:USERPROFILE\.config",
    "$env:USERPROFILE\.local\bin"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host "Created required directories"