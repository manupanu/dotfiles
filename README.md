# dotfiles

Cross-platform dotfiles managed with `madm.py` (Manuel's Agentic Dotfiles Manager).

## Layout

```text
.
├── madm.py                  # Platform-independent Python installer & manager
├── dotfiles.json            # Central mapping and hook configuration
├── dotfiles.local.json      # Gitignored file for local settings & secrets
├── Brewfile                 # macOS Homebrew package list
├── git/                     # Git configurations
│   └── gitconfig.tmpl       # Git config template
├── zsh/                     # Zsh configurations
│   ├── zshenv               # Linked to ~/.zshenv
│   ├── zprofile.tmpl        # Rendered to ~/.zsh/.zprofile
│   ├── zshrc.tmpl           # Rendered to ~/.zsh/.zshrc
│   ├── aliases.zsh.tmpl     # Rendered to ~/.zsh/aliases.zsh
│   └── zsh_plugins.txt      # Linked to ~/.zsh/.zsh_plugins.txt
├── config/                  # Linked configurations (btop, ghostty, fastfetch, etc.)
└── scripts/                 # Platform-specific script hooks
```

## Quick Start

### 1. Initialize Local Settings
Run the interactive wizard to generate your machine-specific `dotfiles.local.json` file:
```bash
python3 madm.py --init
```
This prompts you for your Git credentials and 1Password settings, fetching defaults from Git where possible.

### 2. Run Health Check & Validate Configuration
Verify that all configuration templates compile and render without errors for **all** target platforms (macOS, Linux, and Windows) and inspect the synchronization state of your active dotfiles:
```bash
python3 madm.py --check
```

### 3. Preview Changes (Dry Run & Diff)
Inspect exactly what changes will be applied to your system (including line-by-line diffs of templates) without modifying any files:
```bash
python3 madm.py --diff
```
*Note: `--diff` automatically implies dry-run mode.*

You can simulate other platforms or hostnames to test configurations:
```bash
python3 madm.py --diff --target-os linux
```

### 4. Apply Dotfiles
Apply all symlinks, copies, and render the templates to your home directory:
```bash
python3 madm.py
```
To run interactively and approve any file overwrites:
```bash
python3 madm.py --interactive
```

### 5. Restore From Central Backups
If you ever need to rollback files overwritten during an apply run, you can restore them using the restore menu:
```bash
python3 madm.py --restore
```
This lists your timestamped backup directories stored in `.madm-backups/` and allows you to restore them cleanly.

---

## Command Line Flags

| Flag | Shortcut | Description |
|---|---|---|
| `--init` | | Start the interactive initialization wizard. |
| `--check` | | Run system health status checks and cross-platform template compilation checks. |
| `--restore` | | Restore a centralized backup from `.madm-backups/`. |
| `--dry-run` | `-d` | Dry run mode. Log what actions would be performed. |
| `--diff` | | Show unified, colorized diffs of file changes (implies dry-run). |
| `--prune` | | Remove stale symlinks in target directories that point to this repository. |
| `--interactive`| `-i` | Ask before overwriting target files that already exist (default: backup to `.madm-backups/`). |
| `--no-clobber` | | Skip any mapping whose target already exists instead of backing it up or overwriting it. |
| `--verbose` | `-v` | Enable detailed logging. |
| `--no-color` | | Disable colorized terminal outputs. |
| `--target-os` | | Override current operating system (darwin, linux, windows). |
| `--target-hostname` | | Override current hostname. |

---

## Features

### Configuration Inclusions (`includes`)
Both `dotfiles.json` and `dotfiles.local.json` support an optional `"includes"` array containing relative paths to other JSON configurations:
```json
{
  "includes": [
    "work_mappings.json",
    "private_settings.json"
  ]
}
```
`madm.py` recursively resolves and merges included configurations, combining mappings, scripts, and context variables.

### Template Helper Functions
The Python template context contains the following built-in helpers you can call inside `{{ ... }}` blocks:
- `command_exists("cmd")`: Returns `True` if `cmd` is installed and in PATH.
  - *Example*: `{{ if command_exists("zoxide") }}`
- `read_file("path")`: Returns the contents of a file (path resolved relative to repo root).
  - *Example*: `signingkey = {{ read_file("git/public_key.pub") }}`
- `quote(val)`: Safely escapes double-quotes and encloses the value in quotes.
  - *Example*: `name = {{ quote(git.name) }}`
- `op("ref")`: Dynamically reads a secret from 1Password using the `op` CLI.
  - If `op.account` is set in `dotfiles.local.json`, `madm.py` resolves secrets with `op read <ref> --account <account>`.
- `secret("name")`: Resolves a secret through a pluggable provider (`op`, `pass`, or `env`) configured in a top-level `"secrets"` object in `dotfiles.json`/`dotfiles.local.json`:
  ```json
  { "secrets": { "github-token": "env", "ssh-passphrase": "pass" } }
  ```
  - *Example*: `{{ quote(secret("github-token")) }}`
- `env("VAR")`: Reads an environment variable.

### Ignore Patterns
Add a top-level `"ignore"` array of glob patterns to `dotfiles.json` (and/or `dotfiles.local.json`) to skip specific mappings entirely across apply, `--prune`, and `--check`:
```json
{ "ignore": ["**/.DS_Store", "config/scratch/**"] }
```
Patterns are matched against both the repo-relative `src` and the home-relative `dst`, plus every parent subpath.

### Windows UAC Elevation
If a symlink creation fails on Windows due to insufficient permissions (Developer Mode disabled), the script will prompt you to automatically escalate to Administrator via UAC.

### Centralized Backups
All backups of overwritten targets are moved into `.madm-backups/backup_YYYYMMDD_HHMMSS/` along with a `metadata.json` mapping. This keeps target directories clean.
