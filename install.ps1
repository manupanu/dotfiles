$ErrorActionPreference = "Stop"

$CONFIG = "windows.conf.yaml"
$DOTBOT_DIR = "dotbot"

$DOTBOT_BIN = "bin/dotbot"
$BASEDIR = $PSScriptRoot

Set-Location $BASEDIR
git -C $DOTBOT_DIR submodule sync --quiet --recursive
git submodule update --init --recursive $DOTBOT_DIR

foreach ($PYTHON in ('python', 'python3')) {
    # Python redirects to Microsoft Store in Windows 10 when not installed
    if (& { $ErrorActionPreference = "SilentlyContinue"
            ![string]::IsNullOrEmpty((&$PYTHON -V))
            $ErrorActionPreference = "Stop" }) {
        # Base arguments for dotbot
        $dotbotExe = Join-Path $BASEDIR -ChildPath $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN
        $dotbotArgs = @($dotbotExe)

        # Find all plugin directories in dotbot-plugins
        $pluginsBaseDir = Join-Path $BASEDIR -ChildPath 'dotbot-plugins'
        if (Test-Path $pluginsBaseDir) {
            $pluginDirs = Get-ChildItem -Path $pluginsBaseDir -Directory
            foreach ($dir in $pluginDirs) {
                $dotbotArgs += "--plugin-dir", $dir.FullName
            }
        }

        # Add standard arguments and any user-provided arguments
        $dotbotArgs += "-d", $BASEDIR, "-c", $CONFIG
        $dotbotArgs += $Args

        # Call dotbot with all arguments
        Write-Host "Running: $PYTHON $($dotbotArgs -join ' ')"
        &$PYTHON $dotbotArgs
        return
    }
}
Write-Error "Error: Cannot find Python."
