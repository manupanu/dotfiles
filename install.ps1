#Requires -Version 5.1

<#
.SYNOPSIS
Installs dotfiles by copying them based on links.conf, respecting OS specifiers.
#>

# --- OS Detection ---
# PowerShell Core ($PSVersionTable.PSEdition == 'Core') has $IsLinux, $IsMacOs, $IsWindows
# Windows PowerShell ($PSVersionTable.PSEdition == 'Desktop') only runs on Windows.
$CurrentOS = ""
if ($PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core') {
    if ($IsLinux) { $CurrentOS = "linux" }
    elseif ($IsMacOS) { $CurrentOS = "macos" }
    elseif ($IsWindows) { $CurrentOS = "windows" }
    else { Write-Warning "Unsupported OS in PowerShell Core."; $CurrentOS = "unknown" }
} elseif ($env:OS -eq 'Windows_NT') {
    $CurrentOS = "windows"
} else {
     Write-Warning "Cannot determine OS or unsupported OS."; $CurrentOS = "unknown"
}
# --- End OS Detection ---


# Get the directory where the script is located (repo root)
$RepoRoot = $PSScriptRoot
$ConfigFile = Join-Path -Path $RepoRoot -ChildPath "links.conf"

Write-Host "Starting dotfiles installation for OS: $CurrentOS ..."

# Check if config file exists
if (-not (Test-Path -Path $ConfigFile -PathType Leaf)) {
    Write-Error "Configuration file not found at $ConfigFile"
    exit 1
}

# Read the config file line by line
Get-Content -Path $ConfigFile | ForEach-Object {
    $line = $_.Trim()

    # Skip empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
        return # Skip to next line in ForEach-Object
    }

    # --- OS Filtering Logic ---
    $targetOSes = @("all") # Default to all
    $configPart = $line
    $osSpecifier = $null

    # Check if line contains an OS specifier [...] using regex
    if ($line -match '^(.*)\s*\[([^\]]+)\]\s*$') { # Match [...], allowing spaces around brackets
        $configPart = $matches[1].Trim()
        $osSpecifier = $matches[2]
        $targetOSes = $osSpecifier.Split(',') | ForEach-Object { $_.Trim().ToLower() }
    }

    # Check if the current OS matches the target OSes for this line
    $applyLine = $false
    if (($targetOSes -contains "all") -or ($targetOSes -contains $CurrentOS)) {
        $applyLine = $true
    }

    if (-not $applyLine) {
        # Write-Host "Skipping line for $CurrentOS: $line" # Optional debug
        return # Skip this line if OS doesn't match
    }
    # --- End OS Filtering Logic ---

    # Split the configPart into source and target at the first ':'
    $parts = $configPart.Split(':', 2)
    if ($parts.Count -ne 2) {
        Write-Warning "Skipping invalid line format: $line"
        return
    }

    $repoPath = $parts[0].Trim()
    $targetPathRaw = $parts[1].Trim()

    # Construct absolute source path
    $absSourcePath = Join-Path -Path $RepoRoot -ChildPath $repoPath

    # Expand ~ in target path (basic replacement)
    $expandedTargetPath = $targetPathRaw.Replace('~', $HOME)

    # Resolve potential relative paths in target after expansion
    try {
         # Try resolving first to handle existing paths robustly
        $resolvedPath = Resolve-Path -Path $expandedTargetPath -ErrorAction SilentlyContinue
        if ($resolvedPath) {
            $expandedTargetPath = $resolvedPath.Path
        } elseif (-not ([System.IO.Path]::IsPathRooted($expandedTargetPath))) {
             # If Resolve-Path failed (likely doesn't exist) and path isn't rooted, join with HOME
             # Handle cases like ~/file.txt or ~/.config/file.txt
             $relativePart = $targetPathRaw # Start with the original tilde path
             if ($relativePart.StartsWith("~")) {
                 $relativePart = $relativePart.Substring(1) # Remove ~
             }
             if ($relativePart.StartsWith("/") -or $relativePart.StartsWith("\")) {
                  $relativePart = $relativePart.Substring(1) # Remove leading slash
             }
             $expandedTargetPath = Join-Path -Path $HOME -ChildPath $relativePart
        }
        # If still not rooted after joining with HOME (e.g. target was just 'file.txt'), make it relative to HOME
        if (-not ([System.IO.Path]::IsPathRooted($expandedTargetPath))) {
             $expandedTargetPath = Join-Path -Path $HOME -ChildPath $expandedTargetPath
        }

    } catch {
         Write-Warning "Could not fully resolve target path '$expandedTargetPath'. Proceeding with best guess."
    }


    # Get the target directory
    $targetDir = Split-Path -Path $expandedTargetPath -Parent

    # Check if source file exists
    if (-not (Test-Path -Path $absSourcePath -PathType Leaf)) {
        Write-Warning "Source file not found, skipping: $absSourcePath (from line: $line)"
        return
    }

    # Create target directory if it doesn't exist
    if ($targetDir -and (-not (Test-Path -Path $targetDir -PathType Container))) {
        Write-Host "Creating directory: $targetDir"
        try {
            New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Error "Failed to create directory $targetDir. Skipping. Error: $($_.Exception.Message)"
            return
        }
    }

    # Copy the file (force overwrite)
    Write-Host "Copying $absSourcePath -> $expandedTargetPath"
    try {
        Copy-Item -Path $absSourcePath -Destination $expandedTargetPath -Force -ErrorAction Stop
    } catch {
        Write-Error "Failed to copy to $expandedTargetPath. Check permissions. Error: $($_.Exception.Message)"
    }
}

Write-Host "Dotfiles installation complete."
exit 0 