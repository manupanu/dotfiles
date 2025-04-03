# Manuel's Dotfile Manager (mdm)

This repository helps manage configuration files (dotfiles), install software packages, and deploy fonts across different operating systems (Windows, Linux, macOS) using native shell scripts. It also provides a command to easily add existing dotfiles to the manager.

## Features

- **Dotfile Management:** Symlinks (Linux/macOS) or copies (Windows) configuration files based on `links.conf`.
- **Add Dotfiles:** Copies existing files/directories into the repository structure and automatically adds the corresponding entry to `links.conf`.
- **Software Installation:** Installs packages using native package managers (Homebrew, Winget, APT, Pacman) from predefined lists.
- **Font Installation:** Copies fonts from a common directory to the system's user font location.
- **Task Selection:** Allows running specific tasks (dotfiles, software, fonts, add) or all installation/linking tasks at once.

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

Run the appropriate script (`mdm.sh` for Linux/macOS, `mdm.ps1` for Windows) from the root of the repository.

**Remember to rename `install.sh` to `mdm.sh` and `install.ps1` to `mdm.ps1` if you haven't already.**

### Installation & Linking Tasks

These tasks install software, fonts, or link/copy dotfiles specified in `links.conf`.

-   **Linux / macOS (Bash):**
    ```bash
    # Run all install/link tasks (dotfiles, software, fonts)
    ./mdm.sh -t all
    # Or simply run without -t (defaults to all)
    ./mdm.sh

    # Run only specific task (dotfiles, software, fonts)
    ./mdm.sh -t software
    ./mdm.sh -t dotfiles
    ```
    *Note: `sudo` access may be required for installing software (`apt`/`pacman`).*

-   **Windows (PowerShell):**
    ```powershell
    # You might need to set the execution policy first
    # Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

    # Run all install/link tasks (dotfiles, software, fonts)
    .\mdm.ps1 -Task all
    # Or simply run without -Task (defaults to all)
    .\mdm.ps1

    # Run only specific task (dotfiles, software, fonts)
    .\mdm.ps1 -Task software
    .\mdm.ps1 -Task dotfiles
    ```
    *Note: Running as Administrator might be necessary for the `software` task (winget).*

### Adding a New Dotfile

Use the `add` task to copy an existing file or directory from your system into the repository and automatically update `links.conf`.

-   **Linux / macOS (Bash):**
    ```bash
    ./mdm.sh -t add -s <path_on_system> -r <relative_path_in_repo>

    # Example: Add neovim config
    ./mdm.sh -t add -s ~/.config/nvim -r modules/common/nvim

    # Example: Add bashrc
    ./mdm.sh -t add -s ~/.bashrc -r modules/common/bash/.bashrc
    ```

-   **Windows (PowerShell):**
    ```powershell
    .\mdm.ps1 -Task add -SourcePath <path_on_system> -RepoPath <relative_path_in_repo>

    # Example: Add Starship config
    .\mdm.ps1 -Task add -SourcePath C:\Users\YourUser\.config\starship.toml -RepoPath modules/common/starship.toml
    # Or using ~ equivalent:
    .\mdm.ps1 -Task add -SourcePath ~\.config\starship.toml -RepoPath modules/common/starship.toml

    # Example: Add PowerShell profile
    .\mdm.ps1 -Task add -SourcePath ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 -RepoPath modules/windows/powershell/Microsoft.PowerShell_profile.ps1
    ```

**Arguments for `add` task:**

-   `-s` / `-SourcePath`: The full path to the existing file or directory on your system that you want to manage. Use `~` for your home directory if desired.
-   `-r` / `-RepoPath`: The relative path within *this* repository where the file/directory should be stored (e.g., `modules/common/toolname`, `modules/windows/config.txt`). Do not use leading slashes or absolute paths here.

The `add` task will:
1.  Copy the item from `<path_on_system>` to `<repo_root>/<relative_path_in_repo>`.
2.  Append a line to `links.conf` like: `<relative_path_in_repo>:<path_on_system> [all]`. It automatically converts the system path to use `~` if it's within your home directory.
3.  You may need to manually edit `links.conf` afterwards if you want to restrict the dotfile to specific operating systems (e.g., change `[all]` to `[linux,macos]`).
