# PowerShell Aliases

# Navigation shortcuts
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function mkcd {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	New-Item -ItemType Directory -Path $Path -Force | Out-Null
	Set-Location -LiteralPath $Path
}

$Global:CdiRoots = [ordered]@{}
$Global:CdiRootsInitialized = $false

function Initialize-CdiRoots {
	# Populating roots involves several Test-Path/Resolve-Path calls against
	# OneDrive-hosted folders, which can be slow. Defer this work until `cdi`
	# is actually used instead of paying for it on every shell launch.
	if ($Global:CdiRootsInitialized) { return }
	$Global:CdiRootsInitialized = $true

	@(
		@{ Name = 'home'; Path = $HOME },
		@{ Name = 'docs'; Path = [Environment]::GetFolderPath('MyDocuments') },
		@{ Name = 'desktop'; Path = [Environment]::GetFolderPath('Desktop') },
		@{ Name = 'downloads'; Path = Join-Path $HOME 'Downloads' },
		@{ Name = 'powershell'; Path = $PSScriptRoot },
		@{ Name = 'projects'; Path = Join-Path $HOME 'Projects' },
		@{ Name = 'repos'; Path = Join-Path $HOME 'Repos' },
		@{ Name = 'source'; Path = Join-Path $HOME 'Source' },
		@{ Name = 'dev'; Path = Join-Path $HOME 'Dev' }
	) | ForEach-Object {
		if ($_.Path -and (Test-Path -LiteralPath $_.Path -PathType Container)) {
			$Global:CdiRoots[$_.Name] = (Resolve-Path -LiteralPath $_.Path).Path
		}
	}

	foreach ($oneDriveRoot in @($env:OneDriveCommercial, $env:OneDrive)) {
		if ($oneDriveRoot -and (Test-Path -LiteralPath $oneDriveRoot -PathType Container)) {
			$Global:CdiRoots['onedrive'] = (Resolve-Path -LiteralPath $oneDriveRoot).Path

			$oneDriveDocs = Join-Path $oneDriveRoot 'Documents'
			if (Test-Path -LiteralPath $oneDriveDocs -PathType Container) {
				$Global:CdiRoots['onedrive-docs'] = (Resolve-Path -LiteralPath $oneDriveDocs).Path
			}
			break
		}
	}
}

function cdi {
	param([string]$Name)

	Initialize-CdiRoots

	if (-not $Name) {
		if (Get-Command fzf -ErrorAction SilentlyContinue) {
			$selection = $Global:CdiRoots.GetEnumerator() |
				ForEach-Object { "$($_.Key)`t$($_.Value)" } |
				fzf --height 40% --layout reverse --prompt 'cdi> '

			if ($selection) {
				$Name = ($selection -split "`t", 2)[0]
			}
		}
		else {
			$Global:CdiRoots.GetEnumerator() |
				Sort-Object Name |
				Format-Table -AutoSize @{ Label = 'Name'; Expression = { $_.Key } }, @{ Label = 'Path'; Expression = { $_.Value } }
			return
		}
	}

	if (-not $Name) {
		return
	}

	if ($Global:CdiRoots.Contains($Name)) {
		Set-Location -LiteralPath $Global:CdiRoots[$Name]
		return
	}

	if (Test-Path -LiteralPath $Name -PathType Container) {
		Set-Location -LiteralPath $Name
		return
	}

	$matchingRoots = $Global:CdiRoots.GetEnumerator() | Where-Object { $_.Key -like "$Name*" }
	if (@($matchingRoots).Count -eq 1) {
		Set-Location -LiteralPath @($matchingRoots)[0].Value
		return
	}

	Write-Host "Unknown cdi root: $Name"
}

Register-ArgumentCompleter -CommandName cdi -ParameterName Name -ScriptBlock {
	param($CommandName, $ParameterName, $WordToComplete)

	Initialize-CdiRoots
	$Global:CdiRoots.Keys |
		Where-Object { $_ -like "$WordToComplete*" } |
		ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $Global:CdiRoots[$_]) }
}

# Listing shortcuts
Set-Alias -Name l -Value Get-ChildItem -Option AllScope
function ll { Get-ChildItem -Force }
function la { Get-ChildItem -Force -Hidden }

# Common command aliases
Set-Alias -Name grep -Value Select-String -Option AllScope
Set-Alias -Name which -Value Get-Command -Option AllScope
Set-Alias -Name g -Value git -Option AllScope

# Create file or update timestamp (similar to Unix touch)
function touch {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	if (Test-Path -LiteralPath $Path) {
		(Get-Item -LiteralPath $Path).LastWriteTime = Get-Date
		return
	}

	New-Item -ItemType File -Path $Path | Out-Null
}

function rmf {
	param(
		[Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
		[string[]]$Path
	)

	Remove-Item -LiteralPath $Path -Force
}

function rmrf {
	param(
		[Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
		[string[]]$Path
	)

	Remove-Item -LiteralPath $Path -Recurse -Force -Confirm
}

# Git shortcuts
function gs { git status }
function ga {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git add @Args
}
function gb {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git branch @Args
}
function gco {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git checkout @Args
}
function gd {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git diff @Args
}
function gl {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git log @Args
}
function gp {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git push @Args
}
function gpl {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git pull @Args
}
function gcom {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git commit @Args
}
function gcam {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
	git commit -am @Args
}
