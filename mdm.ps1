#Requires -Version 5.1
# Removed static #Requires -RunAsAdministrator; elevation handled dynamically

<#
.SYNOPSIS
Manages dotfiles, software, and fonts. Installs by default, or performs specific actions like add/update via flags.
Attempts to relaunch with Admin rights if needed for software install/update.
.PARAMETER SourcePath
Required for 'add' task: Path to the existing file/dir on the system
.PARAMETER RepoPath
Required for 'add' task: Relative path within the repo (e.g., modules/common/mytool)
.PARAMETER DryRun
If specified, the script will print actions it would take without actually executing them.
.PARAMETER Add
Adds a new dotfile. Requires -SourcePath and -RepoPath.
.PARAMETER Update
Updates installed software using the system package manager (Windows only for now).
.PARAMETER Dotfiles
Installs dotfiles only.
.PARAMETER Software
Installs software only.
.PARAMETER Fonts
Installs fonts only.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$SourcePath, # Required for 'add' task: Path to the existing file/dir on the system

    [Parameter(Mandatory=$false)]
    [string]$RepoPath, # Required for 'add' task: Relative path within the repo (e.g., modules/common/mytool)

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    # Action Flags (Mutually Exclusive with each other and Installation Flags)
    [Parameter(Mandatory=$false)]
    [switch]$Add,

    [Parameter(Mandatory=$false)]
    [switch]$Update,

    # Installation Flags (Mutually Exclusive with Action Flags)
    # If none of these are specified, and no Action flag, run all installations.
    [Parameter(Mandatory=$false)]
    [switch]$Dotfiles,

    [Parameter(Mandatory=$false)]
    [switch]$Software,

    [Parameter(Mandatory=$false)]
    [switch]$Fonts
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
    Write-Host "--- Installing/Linking Dotfiles ---"
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
            if (-not $DryRun) {
                try {
                    New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Error "Failed to create directory $targetDir. Skipping. Error: $($_.Exception.Message)"
                    return
                }
            } else {
                 Write-Host "DRY RUN: Would create directory $targetDir"
            }
        }

        # Copy the item (file or directory) (force overwrite)
        $copyAction = if (Test-Path -Path $absSourcePath -PathType Container) { "Copying directory" } else { "Copying file" }
        Write-Host "$copyAction $absSourcePath -> $expandedTargetPath"
        if (-not $DryRun) {
            try {
                Copy-Item -Path $absSourcePath -Destination $expandedTargetPath -Force -Recurse -ErrorAction Stop
            } catch {
                Write-Error "Failed to copy to $expandedTargetPath. Check permissions. Error: $($_.Exception.Message)"
            }
        } else {
             Write-Host "DRY RUN: Would $copyAction from $absSourcePath to $expandedTargetPath"
        }
    }
    Write-Host "Dotfiles installation/linking complete."
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
            if (-not $DryRun) {
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
            } else {
                 Write-Host "DRY RUN: Would install winget package '$packageId'"
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
    if (-not $DryRun) {
        try {
            New-Item -Path $fontTargetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Error "Failed to create font directory $fontTargetDir. Error: $($_.Exception.Message)"
            return
        }
    } else {
        Write-Host "DRY RUN: Would ensure font directory exists: $fontTargetDir"
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
        if (-not $DryRun) {
            try {
                Copy-Item -Path $fontFile.FullName -Destination $targetFontPath -Force -ErrorAction Stop
                # Note: For system-wide registration, more complex steps involving Shell.Application or registry are needed.
                # This copy to user profile folder works for many apps but might require logoff/logon.
            } catch {
                 Write-Warning "Failed to copy font '$($fontFile.Name)'. Error: $($_.Exception.Message)"
            }
        } else {
             Write-Host "DRY RUN: Would copy font '$($fontFile.Name)' to $targetFontPath"
        }
    }

    Write-Host "Font installation complete. A logoff/logon might be required for fonts to be fully available."
}

function Add-Dotfile {
    Write-Host "--- Adding Dotfile ---"
    # Validate parameters
    if (-not $SourcePath -or -not $RepoPath) {
        Write-Error "For the 'add' task, both -SourcePath and -RepoPath parameters are required."
        return
    }
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Error "Source path does not exist: $SourcePath"
        return
    }
    # Validate RepoPath: Must be relative, no leading slashes/drive letters, no upward traversal.
    if ($RepoPath -match '^[\\/:]' -or $RepoPath -match '\.\.') {
         Write-Error "RepoPath '$RepoPath' must be a relative path within the repository, cannot start with a drive letter, slash, or backslash, and cannot contain '..' components."
         return
    }

    # Construct full destination path in the repo
    $absRepoDestPath = Join-Path -Path $RepoRoot -ChildPath $RepoPath
    $repoDestDir = Split-Path -Path $absRepoDestPath -Parent

    # Create parent directories in repo if they don't exist
    if ($repoDestDir -and (-not (Test-Path -Path $repoDestDir -PathType Container))) {
        Write-Host "Creating repository directory: $repoDestDir"
        if (-not $DryRun) {
            try {
                New-Item -Path $repoDestDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Error "Failed to create repository directory $repoDestDir. Error: $($_.Exception.Message)"
                return
            }
        } else {
             Write-Host "DRY RUN: Would create repository directory $repoDestDir"
        }
    }

    # Copy the source file/directory to the repo
    $copyAction = if (Test-Path -Path $SourcePath -PathType Container) { "Copying directory" } else { "Copying file" }
    Write-Host "$copyAction from '$SourcePath' to '$absRepoDestPath'"
    if (-not $DryRun) {
        try {
            Copy-Item -Path $SourcePath -Destination $absRepoDestPath -Force -Recurse -ErrorAction Stop
        } catch {
            Write-Error "Failed to copy to repository path $absRepoDestPath. Error: $($_.Exception.Message)"
            return
        }
    } else {
         Write-Host "DRY RUN: Would $copyAction from '$SourcePath' to '$absRepoDestPath'"
    }

    # Normalize the original source path for links.conf (replace $HOME with ~)
    $normalizedTargetPath = $SourcePath
    if ($SourcePath.StartsWith($HOME)) {
        $normalizedTargetPath = '~' + $SourcePath.Substring($HOME.Length)
        # Ensure consistent slash after ~
        $normalizedTargetPath = $normalizedTargetPath.Replace('\', '/')
    } else {
        # Consider warning if path doesn't start with HOME? Might be valid in some cases.
        Write-Warning "Source path '$SourcePath' does not start with the home directory ('$HOME'). Storing absolute path in links.conf."
         # Replace backslashes for consistency if storing absolute path
         $normalizedTargetPath = $normalizedTargetPath.Replace('\', '/')
    }

    # Ensure consistent slashes for repo path in links.conf
    $normalizedRepoPath = $RepoPath.Replace('\', '/')

    # Append the entry to links.conf
    $newLine = "${normalizedRepoPath}:${normalizedTargetPath} [all]" # Explicitly delimited variables
    Write-Host ("Adding entry to {0}: {1}" -f $ConfigFile, $newLine) # Using format operator
    if (-not $DryRun) {
        try {
            # Add newline before adding content if file not empty and doesn't end with newline
            if ((Get-Content $ConfigFile -Raw -ErrorAction SilentlyContinue).Length -gt 0 -and (Get-Content $ConfigFile -Tail 1) -ne '') {
                 Add-Content -Path $ConfigFile -Value ([System.Environment]::NewLine) -ErrorAction Stop
            }
            Add-Content -Path $ConfigFile -Value $newLine -ErrorAction Stop
        } catch {
            Write-Error "Failed to update $ConfigFile. Error: $($_.Exception.Message)"
            # Consider attempting to revert the file copy here? For now, just error out.
            return
        }
    } else {
         Write-Host "DRY RUN: Would add line '$newLine' to $ConfigFile"
    }

    Write-Host "Dotfile '$SourcePath' added successfully."
    Write-Host "You may want to manually edit '$ConfigFile' to adjust OS specificity (currently '[all]')."
}

function Update-Software {
    Write-Host "--- Updating Software ---"
    if ($CurrentOS -ne 'windows') {
        Write-Host "Software update via this script is only supported on Windows."
        return
    }

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Error "Winget command not found. Please install App Installer from the Microsoft Store."
        return
    }

    # Note: Winget upgrade often requires Admin rights
    if (-not (Test-IsAdmin)) {
         Write-Warning "Winget upgrade usually requires Administrator privileges."
         # Script should have already attempted elevation if task 'update' was chosen,
         # but we warn here if somehow it's still not elevated.
    }

    Write-Host "Checking for updates using winget..."
    if (-not $DryRun) {
        try {
            # Consider filtering updates based on software.list? Could be complex.
            # For now, update all managed by winget.
            $process = Start-Process -FilePath $wingetPath.Source -ArgumentList "upgrade", "--all", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity" -Wait -NoNewWindow -PassThru -ErrorAction Stop
            if ($process.ExitCode -ne 0) {
                # Winget often returns non-zero codes even on success (e.g., no updates found), handle specific codes if needed.
                 Write-Warning "Winget upgrade exited with code $($process.ExitCode)."
            } else {
                 Write-Host "Winget upgrade command completed."
            }
        } catch {
            Write-Error "Failed to run winget upgrade. Error: $($_.Exception.Message)"
        }
    } else {
         Write-Host "DRY RUN: Would run winget upgrade --all"
    }
     Write-Host "Software update check complete."
}


# --- Main Execution ---
Write-Host "Starting mdm for OS: $CurrentOS ..."
if ($DryRun) { Write-Host "*** DRY RUN MODE ENABLED ***" -ForegroundColor Yellow }


# --- Parameter Validation ---
$actionFlags = @($Add, $Update).Where({$PSItem -eq $true}).Count
$installFlags = @($Dotfiles, $Software, $Fonts).Where({$PSItem -eq $true}).Count

if ($actionFlags -gt 1) {
    Write-Error "Action flags (-Add, -Update) are mutually exclusive."
    exit 1
}

if ($actionFlags -gt 0 -and $installFlags -gt 0) {
    Write-Error "Action flags (-Add, -Update) cannot be combined with Installation flags (-Dotfiles, -Software, -Fonts)."
    exit 1
}

if ($Add) {
    if (-not $SourcePath -or -not $RepoPath) {
        Write-Error "-Add flag requires both -SourcePath and -RepoPath parameters."
        exit 1
    }
} elseif ($SourcePath -or $RepoPath) {
    Write-Error "-SourcePath and -RepoPath parameters can only be used with the -Add flag."
    exit 1
}
# --- End Parameter Validation ---


# Early exit if not on Windows, as primary tasks are Windows-specific
if ($CurrentOS -ne "windows") {
    # Only allow dotfiles operations (-Add or install involving dotfiles) on non-Windows
    $isInstallAction = ($actionFlags -eq 0)
    $installIncludesDotfiles = ($Dotfiles -or $installFlags -eq 0) # True if -Dotfiles flag used or if default install (no flags)
    $allowNonWindows = $Add -or ($isInstallAction -and $installIncludesDotfiles)
    if (-not $allowNonWindows) {
        Write-Warning "Tasks other than dotfile management primarily target Windows. Skipping execution on $CurrentOS."
        exit 0 # Exit gracefully on non-windows OS
    }
}

# Check for elevation if required actions are requested on Windows
$requiresElevation = $false
if ($CurrentOS -eq 'windows') {
    if ($Update) { $requiresElevation = $true }
    # If default install or filtered install includes Software
    if ($actionFlags -eq 0 -and ($Software -or $installFlags -eq 0)) {
         $requiresElevation = $true
     }
}

if ($requiresElevation -and (-not (Test-IsAdmin))) {
    $triggerTask = if ($Update) { "Update" } else { "Software installation" }
    Write-Warning "The $triggerTask requires Administrator privileges for winget on Windows."
    Write-Host "Attempting to relaunch script with elevation..."

    # Prepare arguments for relaunch
    # Ensure the script path is quoted properly, especially if it contains spaces
    $scriptPath = "`"$($PSCommandPath)`""

    # Corrected argument reconstruction
    # Get parameters except -Task (which shouldn't exist anyway, but safe check)
    $paramsToPass = $PSBoundParameters.Where({$_.Key -ne 'Task'})

    # Build the argument list string array
    $argListStrings = $paramsToPass.ForEach({ 
        $paramName = "-$($_.Key)"
        if ($_.Value -is [switch]) {
            # For switches, just include the name
            $paramName 
        } else {
            # For parameters with values, include the name and quoted value
            $paramName + ' "' + $_.Value + '"' 
        }
    })

    # Join the arguments with spaces
    $joinedArgs = $argListStrings -join ' '

    # Construct the final command line arguments
    $powershellArgs = "-NoProfile -ExecutionPolicy Bypass -File $scriptPath $joinedArgs"

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

# Track if any task fails
$global:ScriptErrorOccurred = $false

function Invoke-Task {
    param (
        [string]$FunctionName
    )
    try {
        & $FunctionName
    } catch {
        Write-Error "Task '$FunctionName' failed: $($_.Exception.Message)"
        # $global:ScriptErrorOccurred = $true
        Set-Variable -Scope Global -Name ScriptErrorOccurred -Value $true -ErrorAction Stop
    }
}

if ($Add) {
    # Add task does not require elevation or specific OS checks here
    Invoke-Task -FunctionName 'Add-Dotfile'
} elseif ($Update) {
    if ($CurrentOS -eq 'windows') {
        Invoke-Task -FunctionName 'Update-Software'
    } else {
        Write-Warning "Software update is currently only supported on Windows."
        # Consider this an error? For now, just warn and skip.
        # $global:ScriptErrorOccurred = $true
    }
} else {
    # Default Installation (all or filtered)
    Write-Host "--- Running Default Installation Tasks ---"
    # Determine which parts to run
    $runAll = ($installFlags -eq 0) # Run all if no specific install flags are set
    $runDotfiles = $Dotfiles -or $runAll
    $runSoftware = ($Software -or $runAll) -and ($CurrentOS -eq 'windows')
    $runFonts = ($Fonts -or $runAll) -and ($CurrentOS -eq 'windows')

    if ($runDotfiles) {
        Invoke-Task -FunctionName 'Install-Dotfiles'
    } else {
        Write-Host "Skipping dotfiles task based on flags."
    }

    if ($runSoftware) {
        Invoke-Task -FunctionName 'Install-Software'
    } else {
        # Explain skip reason only if it *would* have run but for the OS
        if (($Software -or $runAll) -and $CurrentOS -ne 'windows') {
             Write-Host "Skipping software task: Not on Windows."
         } else {
              Write-Host "Skipping software task based on flags."
         }
    }

    if ($runFonts) {
        Invoke-Task -FunctionName 'Install-Fonts'
    } else {
        # Explain skip reason only if it *would* have run but for the OS
        if (($Fonts -or $runAll) -and $CurrentOS -ne 'windows') {
             Write-Host "Skipping fonts task: Not on Windows."
         } else {
              Write-Host "Skipping fonts task based on flags."
         }
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