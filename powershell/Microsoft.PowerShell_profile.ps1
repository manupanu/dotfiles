# Fast Starship init (cache once per session)
$global:__starshipInit = $null
if (-not $global:__starshipInit) {
    $global:__starshipInit = & 'C:\Program Files\starship\bin\starship.exe' init powershell | Out-String
}
Invoke-Expression $global:__starshipInit


# Lazy-load Terminal-Icons without install attempts
$script:__termIconsAttempted = $false
function Ensure-TerminalIcons {
    if (Get-Module -Name Terminal-Icons) { return }
    if ($script:__termIconsAttempted) { return }
    $script:__termIconsAttempted = $true
    try {
        if (Get-Module -ListAvailable -Name Terminal-Icons) {
            Import-Module -Name Terminal-Icons -ErrorAction Stop
        } else {
            Write-Verbose "Terminal-Icons not installed; skipping."
        }
    } catch {
        Write-Verbose "Failed to import Terminal-Icons: $_"
    }
}

# Enhanced PSReadLine Configuration
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Enhanced Listing (with lazy Terminal-Icons)
function la {
    Ensure-TerminalIcons
    Get-ChildItem -Path . -Force | Format-Table -AutoSize
}
function ll {
    Ensure-TerminalIcons
    Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize
}

# Quick Edit Profile
function Edit-Profile {
    if ($env:EDITOR) { & $env:EDITOR $PROFILE.CurrentUserAllHosts }
    else { notepad $PROFILE.CurrentUserAllHosts }
}
Set-Alias -Name ep -Value Edit-Profile

# File and Directory Management
function touch($file) { "" | Out-File $file -Encoding ASCII }
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }
function md { param($dir) mkdir $dir -Force}
function trash($path) {
    $shell = New-Object -ComObject 'Shell.Application'
    $item = Get-Item $path
    $shell.NameSpace(0).ParseName($item.FullName).InvokeVerb('delete')
}

# Navigation Shortcuts
function docs { Set-Location ([Environment]::GetFolderPath("MyDocuments")) }
function dtop { Set-Location ([Environment]::GetFolderPath("Desktop")) }

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gp { git push }
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# System and Network Utilities
function Get-PubIP {
    try {
        (Invoke-WebRequest -Uri 'http://ifconfig.me/ip' -TimeoutSec 3 -UseBasicParsing).Content
    } catch {
        Write-Warning "Could not retrieve public IP."
    }
}
function flushdns { Clear-DnsClientCache; Write-Host "DNS has been flushed" }
function uptime {
    $bootTime = Get-WmiObject win32_operatingsystem | Select-Object lastbootuptime
    $uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($bootTime.lastbootuptime)
    Write-Host ("Uptime: {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
}

# Process Management
function pkill($name) { Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
function pgrep($name) { Get-Process $name }

# File Search and Text Processing
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue |
    ForEach-Object { $_.FullName }
}

function grep($regex, $dir) {
    if ($dir) { Get-ChildItem $dir | Select-String $regex }
    else { $input | Select-String $regex }
}

# Clipboard Operations
function cpy { Set-Clipboard $args[0] }
function pst { Get-Clipboard }

# Admin Elevation
function admin {
    $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    if (-not (Test-Path $pwsh)) {
        Write-Error "pwsh.exe not found at $pwsh. Please check your installation."
        return
    }
    if ($args.Count -gt 0) {
        Start-Process $pwsh -Verb runAs -ArgumentList "-NoExit -Command $($args -join ' ')"
    } else {
        Start-Process $pwsh -Verb runAs -ArgumentList "-NoExit"
    }
}
Set-Alias -Name su -Value admin

# File Operations
function head { param($Path, $n = 10) Get-Content $Path -Head $n }
function tail { param($Path, $n = 10, [switch]$f = $false) Get-Content $Path -Tail $n -Wait:$f }

# Help Function
function Show-Help {
    @"
PowerShell Profile Commands:
---------------------------
ep (Edit-Profile) - Edit PowerShell profile
la - List all files (detailed)
ll - List all files including hidden
touch <file> - Create empty file
mkcd <dir> - Create and enter directory
trash <path> - Move item to recycle bin
docs - Go to Documents folder
dtop - Go to Desktop folder
gs - Git status
ga - Git add .
gc <message> - Git commit
gp - Git push
lazyg <message> - Git add, commit, and push
Get-PubIP - Show public IP
flushdns - Clear DNS cache
uptime - Show system uptime
pkill <name> - Kill process
pgrep <name> - Find process
ff <pattern> - Find files
grep <regex> [dir] - Search in files
cpy <text> - Copy to clipboard
pst - Paste from clipboard
admin/su - Run as administrator
head/tail - View file contents
"@ | Write-Host
}

# Zoxide Integration (lazy init)
$script:__zoxideInited = $false
function __Ensure-Zoxide {
    if ($script:__zoxideInited) { return }
    try {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
        $script:__zoxideInited = $true
    } catch {
        Write-Verbose "Failed to init zoxide: $_"
    }
}
# Provide a safe wrapper for z that doesn't re-enter itself
function z {
    __Ensure-Zoxide
    # After init, the real 'z' function/alias from zoxide is available; forward to it safely.
    if (Get-Command -Name __zoxide_z -ErrorAction SilentlyContinue) {
        & __zoxide_z @args
        return
    }
    if (Get-Command -Name z -ErrorAction SilentlyContinue -CommandType Function,Alias,Application) {
        & (Get-Command -Name z -ErrorAction SilentlyContinue) @args
        return
    }
    Write-Warning "zoxide is not initialized."
}
Set-Alias zi z