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