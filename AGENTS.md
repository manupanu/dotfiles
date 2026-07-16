# Coding Assistant Instructions for this Repo

This repository contains cross-platform dotfiles managed with `madm.py` (Manuel's Agentic Dotfiles Manager).

## Overview of madm.py

- **Configuration file**: `dotfiles.json` defines all file mappings (link, copy, template) and script hooks.
- **Local overrides**: `dotfiles.local.json` is a git-ignored file containing local configurations (e.g., git username, email, 1Password settings). It must conform to `dotfiles.local.json.example`.
- **Target OS & Hostname**: The manager automatically detects the current OS (`darwin`, `linux`, `windows`) and hostname, and processes only matching mappings/scripts.
- **Execution command**: Run the manager using `python3 madm.py` (or `python madm.py`).

## Template Syntax

Files marked with `"type": "template"` in `dotfiles.json` (or files ending in `.tmpl`) are processed with Python-based string substitution and block conditionals.

### Variables & Context
The template context contains:
- `os`: Current target OS (`darwin`, `linux`, `windows`).
- `hostname`: Current hostname.
- `home_dir`: Absolute path to user's home directory.
- `git`: Local Git settings object (accessed via `git.name`, `git.email`, etc.).
- `op_use_one_password`: Boolean indicating if 1Password is enabled.
- `op_git_signing_key_ref`: 1Password reference string for the Git signing key.
- `op(ref)`: Function that runs `op read ref` to resolve secrets dynamically.
- `env(name)`: Function to lookup environment variables.

### Template Conditionals
Conditionals use `{{ if ... }}`, `{{ elif ... }}`, `{{ else }}`, and `{{ end }}` block markers. The expression inside is evaluated as standard Python code:

```ini
[gpg "ssh"]
{{ if os == "darwin" }}
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
{{ elif os == "windows" }}
    program = {{ home_dir }}/AppData/Local/Microsoft/WindowsApps/op-ssh-sign.exe
{{ else }}
    program = /opt/1Password/op-ssh-sign
{{ end }}
```

### Secret Integration (1Password)
Use the `op` helper function to read secrets from 1Password:
```ini
signingkey = "{{ op(op_git_signing_key_ref) }}"
```

## Validating changes
Before applying changes, perform dry runs for all supported platforms to ensure templates render correctly and mappings resolve properly:

```bash
python3 madm.py --dry-run --target-os darwin
python3 madm.py --dry-run --target-os linux
python3 madm.py --dry-run --target-os windows
python3 madm.py --dry-run --target-os linux --target-hostname custom-host
```

Add `--verbose` to inspect more detailed output.
