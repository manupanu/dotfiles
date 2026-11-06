# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

This repository is used as chezmoi's **source directory**. A `.chezmoi.toml.tmpl`
file in the repo root pins `sourceDir` to `~/.dotfiles`, so once chezmoi is
initialized against this repo, it will always keep using `.dotfiles` (even if
the local chezmoi config gets deleted or regenerated).

## Setup on a new machine

1. Install chezmoi: https://www.chezmoi.io/install/
2. Initialize using this repo as the source directory (one-time, required so
   chezmoi knows where to clone/find `.dotfiles` before it can read any
   templates inside it):

   ```sh
   chezmoi init --source ~/.dotfiles <your-dotfiles-repo-url> --apply
   ```

   Replace `<your-dotfiles-repo-url>` with this repo's URL (e.g.
   `git@github.com:<user>/dotfiles.git`).

3. That's it. chezmoi will clone the repo into `~/.dotfiles`, generate
   `~/.config/chezmoi/chezmoi.toml` from `.chezmoi.toml.tmpl`, and apply the
   managed files to your home directory.

## Everyday usage

```sh
chezmoi edit ~/.gitconfig   # edit a managed file (edits the source, not the target)
chezmoi diff                # preview pending changes
chezmoi apply               # apply changes to the home directory
chezmoi add ~/.some_file    # start managing a new file
chezmoi cd                  # open a shell in the source directory (~/.dotfiles)
chezmoi status              # show managed files that differ from the source state
```

## Symlink mode

`mode = "symlink"` is set in `.chezmoi.toml.tmpl`, so plain (non-template)
managed files are deployed as real symlinks in the home directory pointing
back into `~/.dotfiles`, instead of being copied. This means edits made
directly to a symlinked target file (e.g. `~/.ssh/config`) go straight into
the source repo — no `chezmoi apply` needed for those files.

Files that use templating (e.g. `dot_gitconfig.tmpl`, which computes
name/email/GPG settings per machine) are **not** affected — chezmoi always
renders `.tmpl` files as regular files, since a symlink can't support
per-machine templated content.

## Desktop: MangoWM (Wayland, Arch / CachyOS)

The Linux desktop is [MangoWM](https://github.com/mangowm/mango) with Waybar,
Fuzzel, Mako, Swaylock, wlogout and a Catppuccin Mocha theme engine
(`~/.local/bin/mango-theme`, accents switch with `Super+Alt+T`). It started from
[anthonyportugal/dotfiles](https://github.com/anthonyportugal/dotfiles) (MIT, see
`LICENSES/`) and was adapted: Swiss `ch` layout, ghostty, firefox, thunar,
keyring-friendly session, window rules, cliphist on `Super+V`, Qt via
qt6ct + Kvantum, Bibata cursor.

- `packages/arch-mangowm.txt`: packages the desktop needs.
- `system/`: root-owned files (greetd + tuigreet, sched-ext, PAM keyring lines)
  that chezmoi cannot manage. See `system/README.md`.
- `themes/`: palettes and shared templates used by `dotfiles-theme`. The engine
  looks here via `~/.dotfiles` (chezmoi source dir).
- Machine-local, not tracked: `~/.config/mango/config.local.conf` (monitor
  rules, written by the monitors helper).

Executable files are deployed by chezmoi as real copies even in symlink mode
(a symlink cannot carry the exec bit). After editing a deployed script run
`chezmoi re-add ~/.local/lib/mangowm/<script>`; plain config files are symlinks
and need nothing.

Gotcha: `.gitconfig` rewrites `https://github.com/` to SSH. Until the 1Password
SSH agent is enabled (`~/.1password/agent.sock`), HTTPS clones from GitHub fail,
which also affects AUR `-git` packages and the antidote bootstrap.

## Notes

- Do **not** run `chezmoi add` on chezmoi's own config file
  (`~/.config/chezmoi/chezmoi.toml`) — chezmoi refuses this by design, since
  it needs that file to locate the source directory in the first place.
- `README.md` and `.chezmoiignore` itself are excluded from deployment via
  `.chezmoiignore` — they're repo housekeeping, not dotfiles.
- Source directory: `~/.dotfiles`
- Config template: `.chezmoi.toml.tmpl` (sets `sourceDir` and `mode`)
