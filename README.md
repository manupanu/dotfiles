# dotfiles

Managed with [chezmoi](https://www.chezmoi.io).

## Structure

```
scripts/
├── macos/        # macOS-only (Homebrew, Brewfile)
├── unix/         # cross-platform Unix (starship, zoxide, pi, zsh)
└── windows/     # Windows-only (scoop, PowerShell)
```

`.chezmoiignore.tmpl` excludes each platform's scripts on other OSes.
`_functions.sh` is shared helpers (included via `{{ include }}`, never deployed).

## Setup on a new machine

### Linux / macOS

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply https://github.com/manupanu/dotfiles
```

### Windows (PowerShell)

```powershell
winget install twpayne.chezmoi
chezmoi init --apply https://github.com/manupanu/dotfiles
```

## Key decisions

- **NVM** manages Node.js (`nvm install --lts`)
- **Pi** is installed via `npm install -g` under nvm's node (no bundled pi-node)
- **Zsh** config lives in `~/.zsh/` (set via `ZDOTDIR` in `~/.zshenv`)
- **Ghostty** has cross-platform opacity/blur; macOS-only glass blur + transparent titlebar
- **Git** uses SSH signing via 1Password (`op-ssh-sign`), platform-specific paths in template
- **No zsh on Windows** — `.chezmoiignore` skips all zsh/ghostty configs there
- **Hyprland/Waybar on Linux** live in `dot_config/hypr` and `dot_config/waybar` as a small ML4W-free base
- **Hyprland uses one Lua file**: upstream Hyprland 0.55 deprecated hyprlang `.conf` configs in favor of Lua, so `dot_config/hypr/hyprland.lua` is the single source of truth with no generation step
- **hyprwhspr** is managed via `dot_config/hyprwhspr/config.json` and shown as `custom/hyprwhspr` in Waybar

## Hyprland quick keys

- `Super+Enter` — terminal (`ghostty`)
- `Super+B` — browser (`helium-browser`)
- `Super+D` — app launcher (`rofi`)
- `Super+Alt+D` — toggle hyprwhspr speech-to-text
- `Super+Shift+B` — restart Waybar
- `Super+Print` — area screenshot to clipboard
