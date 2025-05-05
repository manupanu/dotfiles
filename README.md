# Manuels Dotfiles

This repository contains my personal configuration files (dotfiles) for various tools across Linux, macOS, and Windows.

These dotfiles are managed using a custom Python script: `mdm.py` (Manuels Dotfile Manager).

## Management Tool: `mdm.py`

`mdm.py` is a simple Python script that automates the setup of these dotfiles by creating symbolic links from this repository to the appropriate locations in your home directory.

**Features:**

* Reads configuration from `mdm_conf.yaml`.
* Supports common and OS-specific links (Linux, macOS, Windows).
* Supports host-specific links (by hostname) using `host-HOSTNAME` sections in the config.
* Automatically creates necessary parent directories for links.
* Checks for existing files or incorrect links before creating new ones.
* Includes a `--dry-run` mode to preview changes.
* Supports copying files (type: copy) and running scripts (type: exec) as actions in the config.

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
    git clone https://github.com/manupanu/dotfiles ~/.dotfiles
    cd ~/.dotfiles
    ```

2. **Install prerequisites:**

    ```bash
    pip install PyYAML
    # or
    python -m pip install PyYAML
    ```

3. **(Optional) Review and customize `mdm_conf.yaml`** to match your preferences.
4. **Run the script:**
    * **Dry Run (Preview changes):**

        ```bash
        python mdm.py --dry-run
        # or
        python mdm.py -n
        ```

    * **Normal Run (Skip existing files):**

        ```bash
        python mdm.py
        ```

    * **Force Run (Overwrite existing files):**

        ```bash
        python mdm.py --force
        # or
        python mdm.py -f
        ```

    * **Combine options:**

        ```bash
        # Dry run with force mode (preview what would be overwritten)
        python mdm.py --dry-run --force
        # or
        python mdm.py -n -f
        ```
> [!INFO]
> **Note for Windows Users:** You might need to run the script as Administrator or enable Developer Mode to create symbolic links. The script will provide guidance if it encounters permission errors. 
> 
> **Host-specific links:** If you want to apply links only on a specific machine, add a section named `host-HOSTNAME:` to your config (replace `HOSTNAME` with your computer's hostname as returned by Python's `socket.gethostname()`).
    
## Configuration (`mdm_conf.yaml`)

The core of the setup is the `mdm_conf.yaml` file. It defines which files/directories in this repository should be linked, copied, or executed.

Structure:

```yaml
# mdm_conf.yaml Example

base_dir: .

common:
  # Linking a file (default)
  starship/starship.toml: ~/.config/starship.toml
  # Copying a file
  somefile.txt:
    type: copy
    target: ~/somefile.txt
  # Running a script
  scripts/setup.sh:
    type: exec
    args: ["--init"]

linux:
  zsh/.zshrc: ~/.zshrc
  zsh/aliases.zsh: ~/.config/zsh/aliases.zsh

macos:
  zsh/.zshrc: ~/.zshrc
  zsh/aliases.zsh: ~/.config/zsh/aliases.zsh

windows:
  git/.gitconfig-windows: ~/.gitconfig
  powershell/profile/Microsoft.PowerShell_profile.ps1: ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1

host-MYHOSTNAME:
  custom/hostfile.conf:
    type: link
    target: ~/.config/hostfile.conf
```

### Action Types

- **link** (default): Create a symbolic link from the repo to the target location.
- **copy**: Copy the file or directory from the repo to the target location.
- **exec**: Execute a script from the repo. You can provide arguments with the `args` list.

* Use `~` to represent the home directory in target paths.
* The script will create parent directories for targets if they don't exist.
* Source paths are relative to the `base_dir` defined in the YAML (or the repo root if `base_dir` is `.`).
* Host-specific sections (`host-HOSTNAME`) take precedence and are only applied on the matching machine.
