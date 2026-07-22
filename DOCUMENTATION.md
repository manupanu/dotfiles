# Manuel's Agentic Dotfiles Manager (`madm.py`) Documentation

`madm.py` is a lightweight, dependency-free, cross-platform dotfiles manager written in Python 3. It replaces complex tools like `chezmoi` with a simple configuration-driven design that supports symlinking, copying, Python-powered templates, 1Password integration, hook scripts, and multi-source configuration merges.

---

## 1. Directory Layout

The repository is structured to mirror your home directory's structure without prefixes, making dotfiles directly editable:

```text
.
├── madm.py                  # Self-contained Python installer/manager
├── dotfiles.json            # Central mapping and hook configuration
├── dotfiles.local.json      # Gitignored local machine settings & overrides
├── Brewfile                 # macOS Homebrew packages list
├── git/
│   └── gitconfig.tmpl       # Git config template
├── zsh/
│   ├── zshenv               # Linked directly to ~/.zshenv
│   ├── zprofile.tmpl        # Rendered to ~/.zsh/.zprofile
│   ├── zshrc.tmpl           # Rendered to ~/.zsh/.zshrc
│   ├── aliases.zsh.tmpl     # Rendered to ~/.zsh/aliases.zsh
│   └── zsh_plugins.txt      # Linked to ~/.zsh/.zsh_plugins.txt
├── config/                  # Subdirectories mapped to ~/.config/
│   ├── btop/
│   ├── ghostty/
│   └── ...
└── scripts/                 # Execution hooks (e.g. install-brew-packages.sh)
```

---

## 2. Command Line Interface Reference

Execute the manager using `python3 madm.py [flags]`.

| Flag | Shortcut | Description |
|:---|:---:|:---|
| `--init` | | Launches the interactive wizard to set up or modify `dotfiles.local.json`. |
| `--check` | | Runs template rendering validation and lists sync status for all mappings. |
| `--restore` | | Opens the interactive menu to restore a timestamped backup folder. |
| `--dry-run` | `-d` | Simulates file changes, logs warnings, and shows planned operations without modifying files. |
| `--diff` | | Prints a unified colorized diff showing planned changes (implies dry-run). |
| `--prune` | | Scans target directories and removes stale symlinks pointing to the repository. |
| `--interactive`| `-i` | Prompts you before overwriting existing destination files. |
| `--no-clobber` | | Skips any mapping whose target already exists instead of backing it up or overwriting it. |
| `--verbose` | `-v` | Prints extra debug information, such as skipped files. |
| `--no-color` | | Disables ANSI coloring in logs. |
| `--target-os` | | Overrides the current OS detection (`darwin`, `linux`, `windows`) for testing. |
| `--target-hostname`| | Overrides the detected system hostname for testing. |

---

## 3. Configuration Reference

### 3.1 Main Mappings Config (`dotfiles.json`)
The core configuration maps sources in the repository to target files in the filesystem.

```json
{
  "includes": [
    "optional_overlay.json"
  ],
  "mappings": [
    {
      "src": "git/gitconfig.tmpl",
      "dst": "~/.gitconfig",
      "type": "template"
    },
    {
      "src": "zsh/zshenv",
      "dst": "~/.zshenv",
      "type": "link"
    },
    {
      "src": "config/btop",
      "dst": "~/.config/btop",
      "type": "link",
      "os": ["darwin", "linux"]
    }
  ],
  "scripts": [
    {
      "path": "scripts/install-brew-packages.sh",
      "os": "darwin",
      "stage": "post"
    }
  ],
  "ignore": [
    "**/.DS_Store",
    "config/scratch/**"
  ],
  "secrets": {
    "github-token": "env",
    "ssh-passphrase": "pass"
  }
}
```

#### Mapping Fields:
- `src` (string, required): Repository path relative to root.
- `dst` (string, required): Destination target path (supports `~` and env vars like `$VAR`).
- `type` (string, optional): One of `"link"` (default), `"copy"`, or `"template"`.
- `os` (string/list, optional): Restricts this mapping to matching operating systems (`darwin`, `linux`, `windows`).
- `hostname` (string/list, optional): Restricts this mapping to matching hostnames.

#### Script Fields:
- `path` (string, required): Script path relative to root.
- `os` (string/list, optional): Restricts execution to matching operating systems.
- `hostname` (string/list, optional): Restricts execution to matching hostnames.
- `stage` (string, optional): One of `"pre"` (runs before mappings) or `"post"` (default, runs after mappings).

#### Top-level `ignore` (list of glob patterns, optional):
- Any mapping whose `src` (repo-relative) or `dst` (relative to the target home directory) matches one of these glob patterns is skipped entirely during apply, prune, and `--check`.
- Patterns are matched against the full path and every parent subpath, so `"config/scratch/**"` matches anything under `config/scratch/`, while `"**/.DS_Store"` matches a `.DS_Store` file at any depth.
- `ignore` entries from `dotfiles.json` and `dotfiles.local.json` are combined.

#### Top-level `secrets` (object, optional):
- Maps a secret name to the provider used to resolve it: `"op"` (1Password CLI), `"pass"` (the `pass` password manager), or `"env"` (an environment variable).
- Templates reference the value with the `secret("NAME")` helper (see §4.2). This is distinct from the existing `op("ref")` helper, which always reads directly from 1Password using a full `op://...` reference.
- Entries in `dotfiles.local.json` override/extend entries in `dotfiles.json`, so provider mappings can be kept out of version control if desired.

---

### 3.2 Machine-Specific Overrides (`dotfiles.local.json`)
This file is excluded from Git. It defines variables used during template rendering:

```json
{
  "git": {
    "name": "Manuel Anrig",
    "email": "me@manuelanrig.ch",
    "username": "manupanu",
    "signingKey": "ssh-ed25519 AAAAC3Nza..."
  },
  "op": {
    "useOnePassword": true,
    "gitSigningKeyRef": "op://Private/...",
    "account": "DN67FSOAANHD5P2YMMKVMEM2TA"
  }
}
```

---

### 3.3 Modular Configuration Merging (`includes`)
Both config files support `"includes": ["relative/path/to/other.json"]`.
- Files are parsed and merged recursively.
- Mappings and scripts lists are appended.
- Top-level variables (e.g. `git`, `op` configs) are merged dictionary-wise, allowing work/private overlays to easily supplement core variables.

---

## 4. Template Engine Specification

Files of type `"template"` are rendered dynamically. The parser evaluates control directives and substitutes expressions.

### 4.1 Syntax

#### Variable Substitution
Substitute variables using `{{ expression }}`. The expression is evaluated as standard Python.
```ini
name = {{ git.name }}
email = {{ git.email }}
```

#### Conditionals
Control blocks are line-based and use standard Python syntax within `{{ if ... }}`, `{{ elif ... }}`, `{{ else }}`, and `{{ end }}`:
```bash
{{ if os == "darwin" }}
    # Darwin settings
{{ elif os == "linux" }}
    # Linux settings
{{ else }}
    # Other settings
{{ end }}
```

### 4.2 Helper Functions

The following helpers are exposed to the template context:
- `os` (string): The current operating system (`darwin`, `linux`, `windows`).
- `hostname` (string): The current hostname.
- `home_dir` (string): Absolute path to the user's home directory.
- `env("NAME")`: Retrieves the value of the environment variable `NAME`.
- `command_exists("cmd")`: Returns `True` if `cmd` is available on the system PATH.
- `read_file("path")`: Reads and returns the contents of a file (path resolved relative to repository root).
- `quote(value)`: Safely escapes double-quotes and encloses the string in quotes.
- `op("ref")`: Reads a secret from 1Password using the `op` CLI.
  - If `op.account` is configured, the command is executed as `op read <ref> --account <account>`.
  - *Note: During `--dry-run` or `--diff` runs, `op` calls are mocked to output `<1Password secret: ref>` to prevent connection stalls or login prompts.*
- `secret("NAME")`: Resolves a secret through the provider configured for `NAME` in the top-level `secrets` section of `dotfiles.json`/`dotfiles.local.json` (§3.1).
  - Supported providers: `"op"` (calls `op read op://NAME`, or `op://NAME` as-is if already prefixed), `"pass"` (calls `pass show NAME`), `"env"` (reads the environment variable `NAME`).
  - Raises a clear error if `NAME` has no provider configured, or if the provider itself fails (missing CLI, unset variable, etc).
  - *Note: During `--dry-run`/`--diff`, `pass`/`env` providers are mocked the same way `op` is, to avoid unwanted side effects.*

---

## 5. Backups & Restoration

When `madm.py` overwrites a file or directory, it does not leave `.bak` files in target directories. Instead, it backs them up to a central repository folder.

### 5.1 Storage Structure
Backups are stored inside `.madm-backups/backup_YYYYMMDD_HHMMSS/`:
```text
.madm-backups/
└── backup_20260716_092000/
    ├── file_0                 # Backed up file or directory
    ├── file_1                 # Backed up file or directory
    └── metadata.json          # Index mapping backup files to original destinations
```

#### `metadata.json` Format:
```json
{
  "files": {
    "file_0": {
      "original_dst": "/Users/manuel/.gitconfig",
      "type": "file"
    },
    "file_1": {
      "original_dst": "/Users/manuel/.zshenv",
      "type": "link",
      "target": "/Users/manuel/.dotfiles/old_zshenv"
    }
  }
}
```

### 5.2 Restore Operation
Run `python3 madm.py --restore` to launch the restore manager:
1. Lists all available backups with timestamps and item counts.
2. Prompts you to pick a backup index.
3. Automatically moves files back to their original destinations, recreating symlinks or directories as necessary.
4. Deletes the backup directory once successfully restored.

---

## 6. Platform-Specific Integration

### 6.1 macOS
- Automatically registers the `scripts/install-brew-packages.sh` hook.
- Links tools like Ghostty, fastfetch, and btop.

### 6.2 Linux
- Links Hyprland desktop stack configs (`hypr/`, `waybar/`, `rofi/`, `swaync/`, `gtk-3.0/`, `gtk-4.0/`, `systemd/`, etc.).
- Evaluates Linux-only blocks (e.g. `aliases.zsh.tmpl` adding `alias free='free -h'`).

### 6.3 Windows
- Mappings filter down to minimal essentials (e.g. `gitconfig`, `zshenv`).
- **Symlinking Privileges**: Creating symlinks on Windows requires administrative privileges.
  - If a symlink fails with a `PermissionError`, the script checks if Developer Mode is disabled.
  - Prompts you to elevate to Administrator via UAC.
  - If accepted, re-launches the installer elevated. If rejected, safely falls back to copying the file.
- **Tool bootstrap**: `scripts/install-scoop-packages.ps1` runs as a `pre`-stage, `windows`-only hook and installs `starship`, `zoxide`, `fzf`, `yazi`, `git`, and `gh` via `scoop` (adding the `extras` bucket for `yazi` if needed; skipped gracefully if `scoop` isn't available).
- **PowerShell profile requires PowerShell 7+ (`pwsh`)**: the mapped profile path (`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) is the per-user profile location for `pwsh`, not Windows PowerShell 5.1 (`Documents\WindowsPowerShell\`).
- **`%OneDrive%` resolution**: profile/alias mappings target `%OneDrive%\Documents\PowerShell\...`, which requires OneDrive installed, signed in, and Known Folder Move enabled for `Documents`. On machines where only a work/school account is present (`%OneDriveCommercial%` set but `%OneDrive%` unset), `madm.py` automatically falls back to `%OneDriveCommercial%` before expanding mapping destinations.
- **Starship prompt**: the profile now calls `starship init powershell` (cached under `%LOCALAPPDATA%\PowerShellProfileCache`, same pattern as the `zoxide` init) before capturing `__BasePrompt`, so the custom venv-aware `prompt` function wraps the starship prompt instead of the plain PowerShell one.
- **`y` (yazi) function** now checks `Get-Command yazi.exe` first and prints a friendly message instead of throwing if yazi isn't installed.
