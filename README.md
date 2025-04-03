# dotfiles

This repository helps manage configuration files (dotfiles), install software packages, and deploy fonts across different operating systems (Windows, Linux, macOS) using native shell scripts.

## Features

- **Dotfile Management:** Symlinks (Linux/macOS) or copies (Windows) configuration files based on `links.conf`.
- **Software Installation:** Installs packages using native package managers (Homebrew, Winget, APT, Pacman) from predefined lists.
- **Font Installation:** Copies fonts from a common directory to the system's user font location.
- **Task Selection:** Allows running specific tasks (dotfiles, software, fonts) or all at once.

## Configuration

### 1. Dotfiles (`links.conf`)

The `links.conf` file defines which dotfiles to manage. Each line specifies a source file/directory within the repository and its target destination on the system. An optional OS specifier can limit the link/copy to specific systems.

**Format:**

```
source/path/in/repo:destination/path/on/system [os1,os2,...]
```

- `source/path/in/repo`: Path relative to the repository root.
- `destination/path/on/system`: Absolute path (use `~` for home directory).
- `[os1,os2,...]`: Optional. Square brackets containing a comma-separated list of target OSes (lowercase: `linux`, `macos`, `windows`). If omitted, defaults to `all`.

**Example `links.conf`:**

```
# Common to all OSes (defaults to [all])
modules/common/git/.gitconfig:~/.gitconfig
modules/common/nvim: ~/.config/nvim

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

Run the appropriate script for your operating system from the root of the repository. You can optionally specify which task(s) to run.

-   **Linux / macOS:**
    ```bash
    # Run all tasks (default)
    bash install.sh

    # Run only specific task (dotfiles, software, fonts)
    bash install.sh -t software
    bash install.sh -t fonts
    ```
    *Note: `sudo` access may be required for installing software (`apt`/`pacman`).*

-   **Windows (using PowerShell):**
    ```powershell
    # You might need to set the execution policy first
    # Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

    # Run all tasks (default)
    .\install.ps1

    # Run only specific task (dotfiles, software, fonts)
    .\install.ps1 -Task software
    .\install.ps1 -Task fonts
    ```
    *Note: Running as Administrator might be necessary for certain `winget` operations or if modifying system-wide paths (though this script focuses on user paths).*
