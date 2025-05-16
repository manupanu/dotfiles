Invoke-Expression (& 'C:\Program Files\starship\bin\starship.exe' init powershell --print-full-init | Out-String)

# Import Terminal-Icons module
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Enhanced PSReadLine Configuration
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

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
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }
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
    if ($args.Count -gt 0) {
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $($args -join ' ')"
    } else {
        Start-Process wt -Verb runAs
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