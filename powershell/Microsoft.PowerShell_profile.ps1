# =====================================================================
# Optional startup profiling: set $env:DOTFILES_PROFILE_DEBUG = "1"
# before opening a new shell to print per-section timings to stderr.
# =====================================================================
$__ProfileDebug = [bool]$env:DOTFILES_PROFILE_DEBUG
$__ProfileStopwatch = if ($__ProfileDebug) { [System.Diagnostics.Stopwatch]::StartNew() } else { $null }
$__ProfileLastMark = 0.0

function __Profile-Mark {
    param([string]$Label)
    if (-not $__ProfileDebug) { return }
    $elapsed = $__ProfileStopwatch.Elapsed.TotalMilliseconds
    $delta = $elapsed - $script:__ProfileLastMark
    $script:__ProfileLastMark = $elapsed
    Write-Host ("[profile] {0,-28} +{1,7:N1}ms (total {2,7:N1}ms)" -f $Label, $delta, $elapsed) -ForegroundColor DarkGray
}

# Set PSReadLine for a better completion experience
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -CompletionQueryItems 200
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord "Shift+Tab" -Function TabCompletePrevious
Set-PSReadLineKeyHandler -Chord "Ctrl+Spacebar" -Function MenuComplete
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Chord "Ctrl+Backspace" -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord "Ctrl+Delete" -Function KillWord
Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord
Set-PSReadLineKeyHandler -Chord "Alt+b" -Function BackwardWord
Set-PSReadLineKeyHandler -Chord "Alt+f" -Function NextWord
Set-PSReadLineKeyHandler -Chord "Ctrl+u" -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Chord "Ctrl+k" -Function KillLine
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

__Profile-Mark "PSReadLine"

# Load Aliases
. "$PSScriptRoot\Aliases.ps1"

__Profile-Mark "Aliases.ps1"

# Load autocompletions only when their command is available.
$CompletionPath = "$PSScriptRoot\Completions"
if (Test-Path -Path $CompletionPath -PathType Container) {
    Get-ChildItem -Path $CompletionPath -Filter *.ps1 -File | ForEach-Object {
        $commandName = $_.BaseName
        if (Get-Command $commandName -ErrorAction SilentlyContinue) {
            . $_.FullName
        }
    }
}

__Profile-Mark "Completions"

function Measure-ProfileStartup {
    Measure-Command { . $PROFILE }
}

function Measure-Prompt {
    param(
        [int]$Count = 200
    )

    Measure-Command {
        1..$Count | ForEach-Object { & (Get-Command prompt) > $null }
    }
}

# Cache shell init scripts so PowerShell doesn't spend seconds rebuilding them on every launch.
$ProfileCacheDir = Join-Path $env:LOCALAPPDATA "PowerShellProfileCache"
New-Item -ItemType Directory -Force -Path $ProfileCacheDir | Out-Null

# ---------------------------------------------------------------------
# Resolved-tool-path cache.
#
# `Get-Command <exe>` walks every directory in $env:PATH looking for a
# match, which is slow (tens to hundreds of ms per call, worse on cloud-
# synced or network paths) and pays that cost on every single shell
# launch even though the result almost never changes between sessions.
# We persist the resolved path once and just Test-Path it afterwards
# (a single fast stat) until the TTL expires or the cached file
# disappears (e.g. the tool was uninstalled), at which point we fall
# back to a real Get-Command lookup.
# ---------------------------------------------------------------------
$ToolPathCacheFile = Join-Path $ProfileCacheDir "tool-paths.json"
$ToolPathCacheTtlMinutes = 1440 # 1 day

function Get-CachedToolPath {
    param([Parameter(Mandatory)][string]$Name)

    $cache = $script:__ToolPathCache
    if (-not $cache) {
        $cache = @{}
        if (Test-Path -LiteralPath $script:ToolPathCacheFile) {
            try {
                $raw = Get-Content -LiteralPath $script:ToolPathCacheFile -Raw -ErrorAction Stop
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                foreach ($prop in $parsed.PSObject.Properties) {
                    $cache[$prop.Name] = $prop.Value
                }
            } catch {
                $cache = @{}
            }
        }
        $script:__ToolPathCache = $cache
    }

    $entry = $cache[$Name]
    $now = Get-Date
    if ($entry -and $entry.CheckedAt) {
        $checkedAt = [datetime]$entry.CheckedAt
        $fresh = $checkedAt -gt $now.AddMinutes(-$script:ToolPathCacheTtlMinutes)
        $stillValid = (-not $entry.Path) -or (Test-Path -LiteralPath $entry.Path)
        if ($fresh -and $stillValid) {
            return $entry.Path
        }
    }

    $resolved = Get-Command $Name -ErrorAction SilentlyContinue
    $path = if ($resolved) { $resolved.Source } else { $null }
    $cache[$Name] = @{ Path = $path; CheckedAt = $now.ToString("o") }
    $script:__ToolPathCache = $cache
    try {
        $cache | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:ToolPathCacheFile -Encoding UTF8
    } catch {
        # Non-fatal: worst case we re-resolve next launch too.
    }
    return $path
}

function Clear-ProfileToolCache {
    <#
        .SYNOPSIS
        Clears the cached tool paths and init scripts (zoxide/starship).
        Run this after installing/uninstalling a CLI tool so the next
        shell launch re-detects it immediately instead of waiting for
        the cache TTL to expire.
    #>
    Remove-Item -LiteralPath $script:ToolPathCacheFile -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $script:ProfileCacheDir "zoxide-init.ps1") -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $script:ProfileCacheDir "starship-init.ps1") -ErrorAction SilentlyContinue
    $script:__ToolPathCache = $null
    Write-Host "Cleared profile tool cache. Restart the shell to re-detect tools."
}

__Profile-Mark "Tool cache setup"

# Init zoxide
$zoxidePath = Get-CachedToolPath -Name "zoxide"
if ($zoxidePath) {
    $zoxideCache = Join-Path $ProfileCacheDir "zoxide-init.ps1"
    if (-not (Test-Path $zoxideCache) -or (Get-Item $zoxidePath).LastWriteTimeUtc -gt (Get-Item $zoxideCache).LastWriteTimeUtc) {
        & $zoxidePath init powershell | Set-Content -Path $zoxideCache -Encoding UTF8
    }
    . $zoxideCache

    if (-not (Get-Command zi -ErrorAction SilentlyContinue)) {
        function zi {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

            if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
                Write-Host "zi requires fzf to be installed and available on PATH."
                return
            }

            $target = zoxide query --interactive @Args
            if ($LASTEXITCODE -eq 0 -and $target) {
                Set-Location -LiteralPath $target
            }
        }
    }
}

__Profile-Mark "zoxide init"

# Init starship prompt
$starshipPath = Get-CachedToolPath -Name "starship"
if ($starshipPath) {
    $starshipCache = Join-Path $ProfileCacheDir "starship-init.ps1"
    if (-not (Test-Path $starshipCache) -or (Get-Item $starshipPath).LastWriteTimeUtc -gt (Get-Item $starshipCache).LastWriteTimeUtc) {
        & $starshipPath init powershell | Set-Content -Path $starshipCache -Encoding UTF8
    }
    . $starshipCache
}

__Profile-Mark "starship init"

# Yazi
function y
{
    if (-not (Get-Command yazi.exe -ErrorAction SilentlyContinue)) {
        Write-Host "yazi is not installed or not on PATH."
        return
    }

    $tmp = (New-TemporaryFile).FullName
    yazi.exe $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container))
    {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# Environment variables
$env:PIPENV_VENV_IN_PROJECT = "1"
# We're always running under pwsh here (this is pwsh's own profile), so
# grab the actual running executable directly instead of paying for a
# Get-Command PATH scan just to rediscover ourselves.
$env:PIPENV_SHELL = (Get-Process -Id $PID).Path

function Enter-Pipenv {
    $venvPath = pipenv --venv 2>$null
    if (-not $venvPath) {
        Write-Host "No Pipenv virtual environment found in this directory."
        return
    }

    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (-not (Test-Path -Path $activateScript -PathType Leaf)) {
        Write-Host "Pipenv virtual environment found, but activate script is missing: $activateScript"
        return
    }

    . $activateScript
}

function Show-ShellDiagnostics {
    [pscustomobject]@{
        PSVersion         = $PSVersionTable.PSVersion.ToString()
        VIRTUAL_ENV       = $env:VIRTUAL_ENV
        CONDA_DEFAULT_ENV = $env:CONDA_DEFAULT_ENV
        PIPENV_SHELL      = $env:PIPENV_SHELL
    } | Format-List
}

__Profile-Mark "yazi/pipenv/env setup"

# Prefix prompt with active Python environment name when available.
if (-not (Get-Command __BasePrompt -ErrorAction SilentlyContinue)) {
    Copy-Item -Path Function:\prompt -Destination Function:\__BasePrompt -Force
}

function prompt {
    $venvName = $null

    if ($env:VIRTUAL_ENV) {
        $venvName = Split-Path -Leaf $env:VIRTUAL_ENV
    }
    elseif ($env:CONDA_DEFAULT_ENV) {
        $venvName = $env:CONDA_DEFAULT_ENV
    }

    $basePrompt = __BasePrompt
    if (Get-Command __zoxide_hook -ErrorAction SilentlyContinue) {
        $null = __zoxide_hook
    }

    if ($venvName) {
        $venvPrefix = "$($PSStyle.Foreground.BrightCyan)($venvName)$($PSStyle.Reset)"
        return "$venvPrefix $basePrompt"
    }

    return $basePrompt
}

__Profile-Mark "prompt setup"

if ($__ProfileDebug) {
    Write-Host ("[profile] {0,-28} ={1,7:N1}ms" -f "TOTAL", $__ProfileStopwatch.Elapsed.TotalMilliseconds) -ForegroundColor Gray
}
