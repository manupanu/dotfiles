# dotfiles

Cross-platform dotfiles managed with chezmoi.

## Migration Status

This repository has switched to a native chezmoi source state.

Use `CHEZMOI_MIGRATION.md` for implementation and validation steps.

Quick checks:

```bash
./validate_chezmoi_templates.sh
chezmoi --source=/home/manuel/.dotfiles status
chezmoi --source=/home/manuel/.dotfiles apply --dry-run --verbose
```

## Layout

```text
dot_*                  # target files in home (e.g., dot_gitconfig.tmpl -> ~/.gitconfig)
dot_config/            # ~/.config/* files
dot_zsh/               # ~/.zsh/* files
dot_pi/                # ~/.pi/* files
Brewfile               # macOS package bundle (applied only on darwin)
.chezmoidata.toml      # template data
.chezmoiignore.tmpl    # conditional ignore rules
run_*.sh.tmpl          # apply scripts
```

## Install chezmoi

### Linux / macOS

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Windows PowerShell

```powershell
winget install twpayne.chezmoi
```

## Use

Initialize on a new machine:

```bash
chezmoi init --source ~/.dotfiles <your-repo> --apply
```

Inspect rendered changes:

```bash
chezmoi --source=/home/manuel/.dotfiles diff
```

Apply the dotfiles:

```bash
chezmoi --source=/home/manuel/.dotfiles apply --verbose
```

Show available template data:

```bash
chezmoi --source=/home/manuel/.dotfiles data
```

Validate templates for all supported OS branches:

```bash
./validate_chezmoi_templates.sh
```

## Notes

- Templates use `.chezmoi.os` and a `targetOS` override for cross-platform validation.
- Linux desktop files are Linux-only via `.chezmoiignore.tmpl`.
- Brewfile and brew bundle script are macOS-only.
- Git signing key can come from `.chezmoidata.toml` or 1Password lookup.

## Supported platforms

- Linux: full desktop stack in `dot_config/*` (Hyprland, Waybar, Rofi, GTK, Qt, systemd user).
- macOS: zsh/git/ghostty templates and Brewfile bootstrap.
- Windows: minimal support via git template branch.
