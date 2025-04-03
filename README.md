# dotfiles

## Dotfile Management

This repository helps manage configuration files (dotfiles) across different operating systems (Windows, Linux, macOS) using simple, native shell scripts.

## Configuration (`links.conf`)

The core of the system is the `links.conf` file. It defines which files should be linked and for which operating system(s). Each line follows the format:

```
source_path:destination_path:os_target
```

- `source_path`: The path to the dotfile within this repository (relative to the repository root).
- `destination_path`: The absolute path where the symbolic link should be created in the user's home directory (e.g., `~/.config/nvim/init.vim`). The `~` will be expanded automatically.
- `os_target`: Specifies the target operating system(s). Can be one of:
    - `windows`: Link only on Windows.
    - `linux`: Link only on Linux.
    - `macos`: Link only on macOS.
    - `all`: Link on all supported operating systems.

**Example `links.conf`:**

```
# Common
git/.gitconfig:~/.gitconfig:all
nvim/init.lua:~/.config/nvim/init.lua:all

# Linux/macOS only
bash/.bashrc:~/.bashrc:linux
bash/.bashrc:~/.bashrc:macos # Or combine with linux if identical: bash/.bashrc:~/.bashrc:linux,macos (Note: current scripts don't support comma separation, use separate lines)

# Windows only
powershell/Microsoft.PowerShell_profile.ps1:~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1:windows
```

*(Note: The current scripts require separate lines for each OS if a file applies to multiple specific OSes like Linux and macOS but not Windows. Using `all` works as expected).*

## Adding New Dotfiles

1.  Place the actual configuration file (e.g., `mytool.conf`) inside this repository, perhaps in a relevant subdirectory (like `mytool/mytool.conf`).
2.  Add a line to `links.conf` specifying the source path within the repo, the desired destination path in your home directory, and the target OS (`windows`, `linux`, `macos`, or `all`).

## Installation

Run the appropriate script for your current operating system from the root of this repository:

-   **Linux / macOS:**
    ```bash
    bash install.sh
    ```
-   **Windows (using PowerShell as Administrator):**
    ```powershell
    # You might need to set the execution policy first
    # Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    .\install.ps1
    ```

The scripts will read `links.conf` and create the necessary symbolic links for your OS. Existing links managed by this script will be overwritten, and backups of existing *files* (not links) at the target destination will be created with a `.bak` extension.
