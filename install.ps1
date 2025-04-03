#Requires -Version 5.1
# Removed static #Requires -RunAsAdministrator; elevation handled dynamically

<#
.SYNOPSIS
Installs dotfiles, software, or fonts based on specified task. Will attempt to relaunch with Admin rights if needed for software task.
.PARAMETER Task
Specifies the task to perform. Valid values are 'dotfiles', 'software', 'fonts', 'all'. Defaults to 'all'.
#>
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'dotfiles', 'software', 'fonts')]
    [string]$Task = 'all'
)

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

# --- Function Definitions ---

# Helper function to check for Administrator rights
function Test-IsAdmin {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Warning "Could not determine administrator status: $($_.Exception.Message)"
        return $false # Assume not admin if check fails
    }
}

function Install-Dotfiles {
    Write-Host "--- Installing Dotfiles ---"
    if (-not (Test-Path -Path $ConfigFile -PathType Leaf)) {
        Write-Error "Configuration file not found at $ConfigFile"
        return # Exit function
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
        if (-not (Test-Path -Path $absSourcePath -PathType Any)) { # Check if exists (file or dir)
            Write-Warning "Source not found, skipping: $absSourcePath (from line: $line)"
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

        # Copy the item (file or directory) (force overwrite)
        $copyAction = if (Test-Path -Path $absSourcePath -PathType Container) { "Copying directory" } else { "Copying file" }
        Write-Host "$copyAction $absSourcePath -> $expandedTargetPath"
        try {
            Copy-Item -Path $absSourcePath -Destination $expandedTargetPath -Force -Recurse -ErrorAction Stop
        } catch {
            Write-Error "Failed to copy to $expandedTargetPath. Check permissions. Error: $($_.Exception.Message)"
        }
    }
    Write-Host "Dotfiles installation complete."
}

function Install-Software {
    Write-Host "--- Installing Software ---"
    if ($CurrentOS -ne 'windows') {
        Write-Host "Software installation via this script is only supported on Windows."
        return
    }

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Error "Winget command not found. Please install App Installer from the Microsoft Store."
        return
    }

    $softwareList = Join-Path -Path $RepoRoot -ChildPath "modules\windows\software.list"
    if (-not (Test-Path -Path $softwareList -PathType Leaf)) {
        Write-Warning "Software list not found: $softwareList"
        return # Not an error, just nothing to install
    }

    Write-Host "Installing packages from $softwareList using winget..."
    Get-Content -Path $softwareList | ForEach-Object {
        $packageId = $_.Trim()
        if (-not ([string]::IsNullOrWhiteSpace($packageId)) -and -not $packageId.StartsWith('#')) {
            Write-Host "Installing $packageId..."
            try {
                # Use Invoke-Expression to handle potential redirection or complex commands if needed in future
                # For now, direct call is fine but using Start-Process allows waiting and better control.
                $process = Start-Process -FilePath $wingetPath.Source -ArgumentList "install", "--id", "$packageId", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity" -Wait -NoNewWindow -PassThru -ErrorAction Stop
                if ($process.ExitCode -ne 0) {
                    Write-Warning "Winget exited with code $($process.ExitCode) for package '$packageId'."
                    # Consider stopping or continuing based on preference
                }
            } catch {
                Write-Error "Failed to install package '$packageId'. Error: $($_.Exception.Message)"
                # Consider stopping or continuing
            }
        }
    }
    Write-Host "Software installation complete."
}

function Install-Fonts {
    Write-Host "--- Installing Fonts ---"
     if ($CurrentOS -ne 'windows') {
        Write-Host "Font installation via this script is only supported on Windows."
        return
    }

    $fontSourceDir = Join-Path -Path $RepoRoot -ChildPath "modules\common\fonts"
    if (-not (Test-Path -Path $fontSourceDir -PathType Container)) {
        Write-Error "Font source directory not found: $fontSourceDir"
        return
    }

    # User-specific font directory
    $fontTargetDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\Fonts"

    Write-Host "Ensuring font directory exists: $fontTargetDir"
    try {
        New-Item -Path $fontTargetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Failed to create font directory $fontTargetDir. Error: $($_.Exception.Message)"
        return
    }

    Write-Host "Copying fonts from $fontSourceDir to $fontTargetDir..."
    $fontFiles = Get-ChildItem -Path $fontSourceDir -Filter "*.ttf" -File # Add other extensions like .otf if needed
    if ($fontFiles.Count -eq 0) {
         Write-Warning "No font files found in $fontSourceDir."
         return
    }

    foreach ($fontFile in $fontFiles) {
        $targetFontPath = Join-Path -Path $fontTargetDir -ChildPath $fontFile.Name
        # Check if font already exists to avoid unnecessary copy/potential errors
        if (Test-Path -Path $targetFontPath -PathType Leaf) {
             Write-Host "Font already exists, skipping: $($fontFile.Name)"
             continue
        }
        Write-Host "Copying $($fontFile.Name)..."
        try {
            Copy-Item -Path $fontFile.FullName -Destination $targetFontPath -Force -ErrorAction Stop
            # Note: For system-wide registration, more complex steps involving Shell.Application or registry are needed.
            # This copy to user profile folder works for many apps but might require logoff/logon.
        } catch {
             Write-Warning "Failed to copy font '$($fontFile.Name)'. Error: $($_.Exception.Message)"
        }
    }

    Write-Host "Font installation complete. A logoff/logon might be required for fonts to be fully available."
}


# --- Main Execution ---
Write-Host "Starting installation for OS: $CurrentOS with task: $Task ..."

# Early exit if not on Windows, as primary tasks are Windows-specific
if ($CurrentOS -ne "windows") {
    Write-Warning "This script primarily targets Windows tasks (software, fonts). Skipping execution on $CurrentOS."
    exit 0 # Exit gracefully on non-windows OS
}

# Check for elevation only if software task is requested
if (($Task -eq 'all' -or $Task -eq 'software') -and (-not (Test-IsAdmin))) {
    Write-Warning "The 'software' task requires Administrator privileges for winget."
    Write-Host "Attempting to relaunch script with elevation..."

    # Prepare arguments for relaunch
    # Ensure the script path is quoted properly, especially if it contains spaces
    $scriptPath = "`"$($PSCommandPath)`""
    $powershellArgs = "-NoProfile -ExecutionPolicy Bypass -File $scriptPath"

    # Pass existing parameters to the new instance
    if ($PSBoundParameters.ContainsKey('Task')) {
        $powershellArgs += " -Task $($PSBoundParameters['Task'])"
    }
    # Add other parameters here if needed in the future
    # e.g., if ($PSBoundParameters.ContainsKey('SomeOtherParam')) { $powershellArgs += " -SomeOtherParam $($PSBoundParameters['SomeOtherParam'])" }

    try {
        # Start PowerShell elevated, passing the reconstructed arguments
        Start-Process powershell.exe -ArgumentList $powershellArgs -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Error "Failed to relaunch script with elevation. Please run the script manually as Administrator. Error: $($_.Exception.Message)"
        exit 1
    }
    # Exit the current non-elevated instance successfully (as the elevated one should take over)
    exit 0
}

# --- Proceed with tasks if already elevated or if software task wasn't requested ---

# Check for unknown OS (should have been caught earlier, but as a safeguard)
if ($CurrentOS -eq "unknown") {
    Write-Error "Exiting due to unsupported OS."
    exit 1 # Use non-zero exit code for errors
}

# Track if any task fails
$global:ScriptErrorOccurred = $false

function Invoke-Task {
    param (
        [scriptblock]$ScriptBlock
    )
    try {
        & $ScriptBlock
    } catch {
        Write-Error "Task failed: $($_.Exception.Message)"
        $global:ScriptErrorOccurred = $true
    }
}

if ($Task -eq 'all' -or $Task -eq 'dotfiles') {
    Invoke-Task -ScriptBlock ${function:Install-Dotfiles}
}

if ($Task -eq 'all' -or $Task -eq 'software') {
     if ($CurrentOS -eq 'windows') {
         Invoke-Task -ScriptBlock ${function:Install-Software}
     } else {
         Write-Host "Skipping software task: Not on Windows."
     }
}

if ($Task -eq 'all' -or $Task -eq 'fonts') {
     if ($CurrentOS -eq 'windows') {
        Invoke-Task -ScriptBlock ${function:Install-Fonts}
     } else {
         Write-Host "Skipping fonts task: Not on Windows."
     }
}

Write-Host "--- Installation finished ---"
if ($global:ScriptErrorOccurred) {
    Write-Error "One or more tasks encountered errors."
    exit 1
} else {
    Write-Host "All requested tasks completed successfully."
    exit 0
}

# Removed the old monolithic logic from here down 