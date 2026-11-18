# Dotfiles

Personal macOS dotfiles, deployed with [mise dotfiles](https://mise.jdx.dev/dotfiles.html).

## Layout

- `home/` mirrors `~`: every file is symlinked to the same path in your home directory.
- `templates/` holds Tera templates rendered per machine (`~/.gitconfig`, `~/.ssh/config`).
- `mise.toml` declares every target under `[dotfiles]` and the template `[vars]`.
- `mise.local.toml` (git-ignored) holds per-machine overrides, e.g. `work = true`.

## Setup on a new Mac

```sh
brew install mise fish
git clone git@github.com:manupanu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
printf '[vars]\nwork = true\n' > mise.local.toml   # work machines only
mise trust
mise dot apply --dry-run
mise dot apply
mise run nvim                                      # optional: LazyVim starter
```

Make fish the login shell:

```sh
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

## Everyday usage

```sh
mise dot status      # check what is applied
mise dot diff        # preview pending changes
mise dot apply       # deploy changes (needed for templates and new files)
mise dot add <path>  # move a new file into the repo and link it back
```

Symlinked files can be edited in place; changes land in the repo directly.
Edit templates in `templates/` and run `mise dot apply`.

## Shells

fish is the primary shell (`home/.config/fish`). It loads Homebrew, mise, fnm,
fzf, zoxide, starship, and Copilot completions. The zsh config is kept as a fallback.

### Fish appearance

The Starship prompt, Fish command line, and Ghostty terminal use Catppuccin Mocha:

| To change | Edit |
| --- | --- |
| Two-line prompt, modules, and prompt colors | [`home/.config/starship.toml`](home/.config/starship.toml) |
| Syntax highlighting, autosuggestions, and the Tab completion menu | [`home/.config/fish/conf.d/20-catppuccin-mocha.fish`](home/.config/fish/conf.d/20-catppuccin-mocha.fish) |
| Font, background, opacity, and terminal palette | [`home/.config/ghostty/config`](home/.config/ghostty/config) |

Edits to already-linked files are visible through their symlinks. When adding a
new file under `home/.config/fish/`, preview and apply the Fish links from the
dotfiles repo:

```sh
mise dot apply --dry-run ~/.config/fish
mise dot apply ~/.config/fish
```

Open a new terminal tab or run `fish` to start a fresh interactive shell. Type
`git` followed by a space, then press Tab to see the completion menu. Start
typing a command from your history to see its autosuggestion. Fish loads these
colors per session without saving universal variables.
