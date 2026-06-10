# dotfiles

Cross-platform dotfiles, organized in layers for `mdm`.

## Layout

```text
common/                # shared on every machine
os/linux/              # Linux-only files
os/darwin/             # macOS-only files
os/windows/            # Windows-only files
host/<hostname>/       # optional machine-specific overrides
user/<user>/           # optional user-specific overrides
selectors/<k>/<v>/     # optional custom selectors
mdm.toml               # mdm config
```

Install order is:

1. `common/`
2. `os/<current-os>/`
3. `host/<hostname>/`
4. `user/<user>/`
5. `selectors/<key>/<value>/`

Later layers override earlier ones.

## Install `mdm`

### Linux / macOS

```bash
python3 -m pip install --user mdm-dotfiles
```

### Windows PowerShell

```powershell
py -3 -m pip install --user mdm-dotfiles
```

## Use

Preview what will be installed:

```bash
mdm --repo ~/.dotfiles plan
```

Apply the dotfiles:

```bash
mdm --repo ~/.dotfiles apply
```

Show detected facts:

```bash
mdm --repo ~/.dotfiles facts
```

Pass extra selectors when needed:

```bash
mdm --repo ~/.dotfiles apply --set role=work
```

## Notes

- Plain files are symlinked by default.
- Files can be copied instead via `mdm.toml` path rules.
- `.tmpl` files are rendered before install.
- `.append` files append text to the current layered file before install.
- Windows linking falls back from symlink to hard link to copy when needed.

## Current repo split

### Common

- `common/.config/btop/`
- `common/.config/fastfetch/`
- `common/.config/ghostty/config`
- `common/.config/starship.toml`
- `common/.pi/`

### Linux

- `os/linux/.Xresources`
- `os/linux/.gtkrc-2.0`
- `os/linux/.gitconfig`
- `os/linux/.zshenv`
- `os/linux/.zsh/`
- `os/linux/.config/gtk-3.0/`
- `os/linux/.config/gtk-4.0/`
- `os/linux/.config/hypr/`
- `os/linux/.config/hyprwhspr/`
- `os/linux/.config/qt6ct/`
- `os/linux/.config/rofi/`
- `os/linux/.config/swaync/`
- `os/linux/.config/systemd/`
- `os/linux/.config/waybar/`
- `os/linux/.config/waypaper/`
- `os/linux/.config/xdg-terminals.list`

### macOS

- `os/darwin/Brewfile`
- `os/darwin/.gitconfig`
- `os/darwin/.zshenv`
- `os/darwin/.zsh/`
- `os/darwin/.config/ghostty/config`

### Windows

- `os/windows/.gitconfig`
