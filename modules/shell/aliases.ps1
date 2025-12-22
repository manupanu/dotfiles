# Enhanced Listing
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# Reload PowerShell Profile
function reload-profile {
    & $profile
}

# Set UNIX-like aliases for the admin command, so su <command> will run the command with elevated rights.
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}


Set-Alias -Name su -Value admin