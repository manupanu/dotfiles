# dotfiles

Managed with [chezmoi](https://www.chezmoi.io).

## Setup on a new machine

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b $HOME/.local/bin init --apply manupanu 

```

### Windows (PowerShell)

```powershell
winget install twpayne.chezmoi
chezmoi init --apply https://github.com/manupanu/dotfiles
```