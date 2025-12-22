# Dotfiles

My personal dotfiles, managed with a custom Python utility. This repository contains my configurations for various tools and shells, organized into modular components.

## Features

- **Modular Configuration**: Each tool (git, shell, etc.) is a self-contained module.
- **Cross-Platform**: Supports Windows (`winget`), macOS (`brew`), and Linux (`apt`).
- **Automated Setup**: One-liner installation and bootstrap scripts.
- **Intelligent Linking**: Automatic symlinking with platform and hostname-specific overrides.
- **Safety First**: Automatic backups of existing configurations (unless `--no-backup` is used).

## Project Structure

```text
.dotfiles/
├── main.py            # Management utility
├── bootstrap.sh       # Mac/Linux setup script
├── bootstrap.ps1      # Windows setup script
└── modules/           # Configuration modules
    ├── git/           # Git configuration
    └── shell/         # Shell (PowerShell/Zsh) configuration
```

## Installation

### Quick Install (One-Liner)

**macOS / Linux:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manupanu/dotfiles/main/install.sh)"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/manupanu/dotfiles/main/install.ps1 | iex"
```

### Manual Setup
If you have already cloned the repository, run the bootstrap script for your system:

**Windows:**
```powershell
.\bootstrap.ps1
```
*Note: Enable **Developer Mode** in Windows Settings to allow symlinks without Administrator privileges.*

**macOS / Linux:**
```bash
./bootstrap.sh
```

## Management Utility

The dotfiles are managed by a Python script (`main.py`) that handles package installation and file linking.

### Advanced Usage
```bash
# Preview changes without applying them
python main.py --dry-run

# Skip creating .bak files when overwriting existing files
python main.py --no-backup
```

### Adding a Module
Create a folder in `modules/` with a `module.json` file.

#### Example `module.json`
```json
{
  "name": "example",
  "platforms": ["win32", "darwin"],
  "packages": {
    "darwin": ["htop"],
    "win32": ["HTOP.HTOP"]
  },
  "links": {
    "all": {
      "shared_config": "~/.config/shared"
    },
    "hostnames": {
      "WORK-LAPTOP": {
        "work_overrides": "~/.config/local"
      },
      "default": {
        "personal_overrides": "~/.config/local"
      }
    }
  }
}
```

## Configuration Schema

### Root Filters
- `platforms`: (Optional) List of supported platforms (`win32`, `darwin`, `linux`).
- `hostnames`: (Optional) String or list of hostnames allowed to use this module.

### Packages
- Maps platform keys to a list of package identifiers for the native package manager.

### Links & Copy
- `links`: Files linked via symlinks (best for most configs).
- `copy`: Files copied directly (best for apps that don't follow symlinks).

Both support `all`, `platforms`, and `hostnames` (with `"default"` support).

#### Example `module.json` with advanced filtering
```json
{
  "name": "advanced",
  "links": {
    "all": {
      "shared": "~/.shared"
    },
    "platforms": {
      "darwin, linux": {
        "bashrc": "~/.bashrc"
      },
      "win32": {
        "powershell_profile.ps1": "~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
      }
    },
    "hostnames": {
      "WORK-LAPTOP": {
        "gitconfig-work": "~/.gitconfig-local"
      },
      "default": {
        "gitconfig-personal": "~/.gitconfig-local"
      }
    }
  }
}
```

## How it Works
1. **Detection**: identifies current platform and hostname.
2. **Filtering**: Skips modules that don't match `platforms` or `hostnames` filters.
3. **Packages**: Installs missing packages using `winget`, `brew`, or `apt`.
4. **Symlinking**:
   - Resolves `~` to the user's home directory.
   - If a file exists at the target, it moves it to `{filename}.bak`.
   - Creates a symlink from the module file to the target location.
