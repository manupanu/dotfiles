# Dotfiles Manager

A simple, modular, and cross-platform dotfiles manager written in Python. It supports Windows, macOS, and Linux with native package manager integration and hostname-based configuration overrides.

## Features

- **Cross-Platform**: Works on Windows (`winget`), macOS (`brew`), and Linux (`apt`).
- **One-Command Bootstrap**: Easy setup scripts for Unix and Windows.
- **Dry Run Support**: Preview changes with `--dry-run` or `-d`.
- **Modular Design**: Every configuration is a self-contained folder in the `modules/` directory.
- **Performance Optimized**: 
  - Batched package installation across all modules.
  - Efficient package existence checks for all platforms.
- **Intelligent Linking**: 
  - Automatic backup of existing files (appends `.bak`).
  - Creates parent directories automatically.
  - Supports platform and hostname-specific overrides with fallbacks.
- **Conditional Loading**: Filter entire modules based on platform or hostname.

## Project Structure

```text
.dotfiles/
├── main.py            # Core engine
├── bootstrap.sh       # Mac/Linux setup script
├── bootstrap.ps1      # Windows setup script
└── modules/           # Configuration modules
    └── git/
        ├── module.json    # Module definition
        ├── .gitconfig     # Shared config
        └── .gitconfig-work
```

## Usage

### 1. Quick Install (One-Liner)

**macOS / Linux:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manupanu/dotfiles/main/install.sh)"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/manupanu/dotfiles/main/install.ps1 | iex"
```

### 2. Manual Bootstrap
If you have already cloned the repository, run the script appropriate for your system:

**Windows:**
```powershell
.\bootstrap.ps1
```
*Note: Enable **Developer Mode** in Windows Settings to allow symlinks without Administrator privileges.*

**macOS / Linux:**
```bash
./bootstrap.sh
```

### 3. Advanced Usage
The manager supports command-line arguments:

```bash
# Preview changes without applying them
python main.py --dry-run

# Skip creating .bak files when overwriting existing files
python main.py --no-backup
```

### 2. Adding a Module
Create a folder in `modules/` with a `module.json` file.

#### Example `module.json`
```json
{
  "name": "example",
  "platforms": ["win32", "darwin"],
  "hostnames": "WORK-LAPTOP, HOME-PC",
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

Both support `all`, `platforms`, and `hostnames` (with `"default"` support) just like the package installer.

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
