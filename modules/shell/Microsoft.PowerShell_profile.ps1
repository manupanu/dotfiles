$ProgressPreference = 'SilentlyContinue'

# Load aliases
$aliasPath = Join-Path (Split-Path -Parent $PROFILE) "aliases.ps1"
if (Test-Path $aliasPath) {
    . $aliasPath
}

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })

# Terminal Icons
Import-Module -Name Terminal-Icons


# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo


# Environment variables

$env:STARSHIP_CACHE = "$env:LOCALAPPDATA\starship"

#Default editor configuration
$env:EDITOR = "code --wait"
$env:VISUAL = "code --wait"

# Pipenv configuration
$env:PIPENV_IGNORE_VIRTUALENVS = '1'
$env:PATH = "$HOME\.pipenv-venv\Scripts;$env:PATH"


