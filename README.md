# dotfiles

Managed with [chezmoi](https://www.chezmoi.io).

## Setup on a new machine

```bash
sh -c "$(curl -fsLS chezmoi.io/lb)" -- init --apply https://github.com/manupanu/dotfiles
```

### Windows (PowerShell)

```powershell
winget install twpayne.chezmoi
chezmoi init --apply https://github.com/manupanu/dotfiles
```