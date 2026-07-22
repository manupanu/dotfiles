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


# Load Aliases
. "$PSScriptRoot\Aliases.ps1"

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

# Init zoxide
$zoxideCache = Join-Path $ProfileCacheDir "zoxide-init.ps1"
$zoxideCmd = Get-Command zoxide -ErrorAction SilentlyContinue
if ($zoxideCmd) {
    if (-not (Test-Path $zoxideCache) -or (Get-Item $zoxideCmd.Source).LastWriteTimeUtc -gt (Get-Item $zoxideCache).LastWriteTimeUtc) {
        & $zoxideCmd.Source init powershell | Set-Content -Path $zoxideCache -Encoding UTF8
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

# Yazi
function y
{
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
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) {
    # Keep pipenv shells in PowerShell so prompt customizations (like venv name) are visible.
    $env:PIPENV_SHELL = $pwshCmd.Source
}

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
