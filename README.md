# Manuels Dotfiles

This repository contains my personal configuration files (dotfiles) for various tools across Linux, macOS, and Windows.

These dotfiles are managed using a custom Python script: `mdm.py` (Manuels Dotfile Manager).

## Management Tool: `mdm.py`

`mdm.py` is a simple Python script that automates the setup of these dotfiles by creating symbolic links from this repository to the appropriate locations in your home directory.

**Features:**

* Reads configuration from `links.yaml`.
* Supports common and OS-specific links (Linux, macOS, Windows).
* Automatically creates necessary parent directories for links.
* Checks for existing files or incorrect links before creating new ones.
* Includes a `--dry-run` mode to preview changes.

## Prerequisites

1. **Python 3:** Ensure you have Python 3 installed.
2. **PyYAML:** The script requires the PyYAML library. Install it using pip:

    ```bash
    pip install PyYAML
    # or
    python -m pip install PyYAML
    ```

## Usage

1. **Clone the repository:**

    ```bash
    git clone <repository-url> ~/dotfiles
    cd ~/dotfiles
    ```

2. **Install prerequisites:**

    ```bash
    pip install PyYAML
    # or
    python -m pip install PyYAML
    ```

3. **(Optional) Review and customize `links.yaml`** to match your preferences.
4. **Run the script:**
    * **Dry Run (Preview changes):**

        ```bash
        python mdm.py --dry-run
        # or
        python mdm.py -n
        ```

    * **Apply changes:**

        ```bash
        python mdm.py
        ```

    **Note for Windows Users:** You might need to run the script as Administrator or enable Developer Mode to create symbolic links. The script will provide guidance if it encounters permission errors.

## Configuration (`links.yaml`)

The core of the setup is the `links.yaml` file. It defines which files/directories in this repository should be linked to which locations in your home directory.

Structure:

```yaml
# links.yaml Example

# Base directory within the repo where dotfiles are located.
base_dir: .

# Links common to all operating systems
common:
  starship/starship.toml: ~/.config/starship.toml
  git/.gitconfig: ~/.gitconfig

# Links specific to Linux
linux:
  zsh/.zshrc: ~/.zshrc
  zsh/aliases.zsh: ~/.config/zsh/aliases.zsh
  wsl/.profile: ~/.profile # For WSL environments

# Links specific to macOS (Darwin)
macos:
  zsh/.zshrc: ~/.zshrc
  zsh/aliases.zsh: ~/.config/zsh/aliases.zsh

# Links specific to Windows
windows:
  # Overwrites common git/.gitconfig on Windows
  git/.gitconfig-windows: ~/.gitconfig
  powershell/profile/Microsoft.PowerShell_profile.ps1: ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
```

* Use `~` to represent the home directory in target paths.
* The script will create parent directories for targets if they don't exist.
* Source paths are relative to the `base_dir` defined in the YAML (or the repo root if `base_dir` is `.`).
