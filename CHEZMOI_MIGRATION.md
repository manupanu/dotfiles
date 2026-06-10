# Chezmoi Migration Playbook

This repository now contains a native chezmoi source state in the root:

- dot_gitconfig.tmpl
- dot_zshenv
- dot_zsh/
- dot_config/
- dot_pi/
- dot_Xresources
- dot_gtkrc-2.0
- Brewfile
- .chezmoidata.toml
- .chezmoiignore.tmpl

## What is implemented

1. Common files were ported to native chezmoi paths:
   - btop, fastfetch, starship, pi agent config.
2. Linux desktop stack was ported:
   - Hyprland, rofi, waybar, swaync, gtk, qt6ct, waypaper, systemd user unit.
3. Cross-OS templates were created:
   - gitconfig (OS-specific 1Password signing program path)
   - zshrc (Linux/macOS split for fpath + NVM)
   - zprofile (Homebrew only on macOS)
   - aliases (tiny Linux-only alias difference)
   - ghostty config (Darwin-only settings)
4. Target filtering is active in .chezmoiignore.tmpl:
   - Linux-only stack excluded on non-Linux.
   - Brewfile excluded on non-macOS.
5. Script-based package bootstrap is prepared:
   - run_onchange_install-brew-packages.sh.tmpl executes brew bundle only on macOS.
6. Cross-OS template validation helper:
   - validate_chezmoi_templates.sh renders key templates for linux/darwin/windows using targetOS override data.

## 1Password behavior for git signing key

By default, rendering uses .git.signingKey from .chezmoidata.toml.

To switch to 1Password lookup:

1. Set in .chezmoidata.toml:
   - op.useOnePassword = true
   - op.gitSigningKeyRef = "op://<vault>/<item>/<field>"
2. Confirm the reference with:
   - op read 'op://<vault>/<item>/<field>'
3. Re-run chezmoi status.

## Dry-run and validation

Run these first on Linux:

```sh
./validate_chezmoi_templates.sh
chezmoi --source=/home/manuel/.dotfiles status
chezmoi --source=/home/manuel/.dotfiles diff
chezmoi --source=/home/manuel/.dotfiles apply --dry-run --verbose
```

Then apply for real:

```sh
chezmoi --source=/home/manuel/.dotfiles apply --verbose
```

Repeat status/diff/dry-run/apply on macOS and Windows.

## Rollback

Use git history for rollback reference of pre-migration files.

## Next implementation tasks

1. Add optional run_once_ scripts for package bootstrap (Homebrew on macOS, apt/pacman on Linux if desired).
2. Add host-specific files using template conditionals on .chezmoi.hostname.
3. Retire legacy files once all machines pass validation.
