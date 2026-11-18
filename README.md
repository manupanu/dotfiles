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
