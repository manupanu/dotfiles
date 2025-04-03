# Manuel's Dotfile Manager (mdm)

This repository helps manage configuration files (dotfiles), install software packages, and deploy fonts across different operating systems (Windows, Linux, macOS) using native shell scripts.

By default, it installs all components (dotfiles, software, fonts). Specific flags can be used to perform actions like adding a dotfile (`--add`), updating software (`--update`), or installing only specific components (`--dotfiles`, `--software`, `--fonts`).

## Features

- **Dotfile Management:** Symlinks (Linux/macOS) or copies (Windows) configuration files based on `links.conf`.
- **Add Dotfiles:** Copies existing files/directories into the repository and automatically updates `links.conf` (using `--add`).
- **Software Installation:** Installs packages using native package managers (Winget, Homebrew, APT, Pacman) from predefined lists.
- **Software Update:** Updates installed packages using the native package manager (using `--update`).
- **Font Installation:** Copies fonts from a common directory to the user's font location.
- **Flexible Execution:** Run all installations by default, or use flags to target specific actions or installation components.
- **Dry Run Mode:** Preview changes without modifying the system using `-DryRun` (PowerShell) or `-n`/`--dry-run` (Bash).
- **Platform Aware:** Adapts behavior for Windows, macOS, and Linux (Debian/Arch based).
- **Automatic Elevation:** Attempts to relaunch with admin/sudo rights on Windows when needed (e.g., for software install/update).

## Configuration

### 1. Dotfiles (`links.conf`)

The `links.conf` file defines which dotfiles to manage. Each line specifies a source file/directory within the repository and its target destination on the system. An optional OS specifier can limit the link/copy to specific systems. The `add` task automatically generates entries in this format.

**Format:**

```
source/path/in/repo:destination/path/on/system [os1,os2,...]
```

- `source/path/in/repo`: Path relative to the repository root.
- `destination/path/on/system`: Absolute path. Use `~` for the home directory (e.g., `~/.config/nvim`). The scripts handle expansion.
- `[os1,os2,...]`: Optional. Square brackets containing a comma-separated list of target OSes (lowercase: `linux`, `macos`, `windows`). If omitted or set to `[all]`, the entry applies to all systems where the script runs.

**Example `links.conf`:**

```
# Common to all OSes (defaults to [all])
modules/common/git/.gitconfig:~/.gitconfig
modules/common/nvim: ~/.config/nvim [all] # Explicit [all] also works

# Linux and macOS only
modules/common/bash/.bashrc:~/.bashrc [linux,macos]

# Windows only
modules/windows/powershell/Microsoft.PowerShell_profile.ps1:~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1 [windows]
```

### 2. Software (`modules/<os>/...list`)

Software packages to be installed are listed in files within OS-specific directories under `modules/`:

- **macOS:** `modules/macos/software.list` (Package names for Homebrew)
- **Windows:** `modules/windows/software.list` (Package IDs for Winget)
- **Linux (Debian/Ubuntu):** `modules/linux/apt.list` (Package names for APT)
- **Linux (Arch):** `modules/linux/pacman.list` (Package names for Pacman)

**Format:**

- One package name/ID per line.
- Lines starting with `#` are ignored as comments.

### 3. Fonts (`modules/common/fonts/`)

Place font files (`.ttf`, `.otf`, etc.) inside the `modules/common/fonts/` directory. The scripts will copy them to the appropriate user font location:

- **macOS:** `~/Library/Fonts`
- **Linux:** `~/.local/share/fonts` (and updates font cache via `fc-cache`)
- **Windows:** `%LOCALAPPDATA%\Microsoft\Windows\Fonts` (logoff/logon may be needed)

## Usage

Run the appropriate script (`mdm.sh` for Linux/macOS, `mdm.ps1` for Windows) from the root of the repository using flags to specify the desired operation.

**Core Principles:**

*   **No Flags = Install All:** Running the script without any flags performs the default installation sequence: dotfiles, software (if applicable), and fonts (if applicable).
*   **Action Flags (`--add`, `--update`):** Perform a specific action instead of installation. These are mutually exclusive with each other and with Installation Flags.
*   **Installation Flags (`--dotfiles`, `--software`, `--fonts`):** Install *only* the specified components. These are mutually exclusive with Action Flags. Can be combined (e.g., `--dotfiles --fonts`).
*   **Dry Run (`-n`/`--dry-run`, `-DryRun`):** Can be added to any command to preview actions without execution.

### Examples (Bash - Linux/macOS)

```bash
# Install all (dotfiles, software, fonts) - Default Behavior
./mdm.sh

# Install only dotfiles
./mdm.sh --dotfiles

# Install only software (requires sudo on Linux)
./mdm.sh --software

# Install only dotfiles and fonts
./mdm.sh --dotfiles --fonts

# Add a new dotfile
./mdm.sh --add -s ~/.config/nvim -r modules/common/nvim

# Update installed software (requires sudo on Linux)
./mdm.sh --update

# Dry Run: Preview installing all
./mdm.sh -n

# Dry Run: Preview adding a dotfile
./mdm.sh --add -s ~/.bashrc -r modules/common/bash/.bashrc -n

# Dry Run: Preview updating software
./mdm.sh --update -n

# Show help
./mdm.sh --help
```

### Examples (PowerShell - Windows)

```powershell
# Set execution policy if needed (run once)
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install all (dotfiles, software, fonts) - Default Behavior
# (May require Admin rights for software - script will attempt to elevate)
.\mdm.ps1

# Install only dotfiles
.\mdm.ps1 -Dotfiles

# Install only software (Requires Admin - script will attempt to elevate)
.\mdm.ps1 -Software

# Install only dotfiles and fonts
.\mdm.ps1 -Dotfiles -Fonts

# Add a new dotfile
.\mdm.ps1 -Add -SourcePath ~\.config\starship.toml -RepoPath modules/common/starship.toml

# Update installed software (Requires Admin - script will attempt to elevate)
.\mdm.ps1 -Update

# Dry Run: Preview installing all
.\mdm.ps1 -DryRun

# Dry Run: Preview adding a dotfile
.\mdm.ps1 -Add -SourcePath ~\.config\git\config -RepoPath modules/common/git/config -DryRun

# Dry Run: Preview updating software
.\mdm.ps1 -Update -DryRun
```

*Note on Elevation:* On Windows, tasks requiring Administrator privileges (typically `-Software`, `-Update`, or default install) will cause the script to attempt to relaunch itself with elevated rights. On Linux, you'll need to run the script with `sudo` if needed (e.g., `sudo ./mdm.sh --software`).
