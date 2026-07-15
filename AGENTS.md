# Copilot instructions for this repo

This is a cross-platform **chezmoi**-managed dotfiles repository (source state, not the applied
target). Files here are templates/renamed sources that chezmoi turns into real dotfiles in the
home directory — do not treat paths in this repo as the paths they represent on disk.

## Chezmoi naming conventions

- `dot_foo` → applies to `~/.foo` (e.g. `dot_zshenv` → `~/.zshenv`, `dot_config/` → `~/.config/`).
- Files ending in `.tmpl` are Go templates rendered with chezmoi's template data before being
  written to the target path (the `.tmpl` suffix is stripped on apply).
- Template data comes from `.chezmoidata.toml` (static values like git name/email/signing key)
  and `.chezmoi.toml.tmpl` (machine-generated config, sourceDir/mode).
- `.chezmoiignore.tmpl` conditionally excludes paths per-OS at apply time (e.g. Linux desktop
  configs like Hyprland/Waybar/Rofi are skipped on non-Linux; `.config`/`.zsh`/`.pi` are skipped
  on Windows, which only gets the git config).
- `run_onchange_*.sh.tmpl` scripts execute automatically on `chezmoi apply` when their rendered
  content changes (e.g. `run_onchange_install-brew-packages.sh.tmpl` runs `brew bundle` on macOS
  only).

## Cross-platform OS branching pattern

Templates determine OS via `{{ .chezmoi.os }}`, but support a `targetOS` override so templates
can be validated for a different OS than the one Copilot/dev is running on:

```
{{- $os := .chezmoi.os -}}
{{- if hasKey . "targetOS" -}}{{- $os = .targetOS -}}{{- end -}}
{{- if eq $os "darwin" -}} ... {{- else if eq $os "windows" -}} ... {{- else -}} ... {{- end -}}
```

Follow this exact pattern when adding new OS-conditional logic in templates (see
`dot_gitconfig.tmpl` and `run_onchange_install-brew-packages.sh.tmpl` for examples), so the
`targetOS`-based validation path keeps working.

## Secrets

Git commit signing key can come from either `.chezmoidata.toml` (`git.signingKey`) or 1Password
via `onepasswordRead` with the ref in `.chezmoidata.toml` (`op.gitSigningKeyRef`), gated by
`op.useOnePassword`. Never hardcode secrets directly into templates — use this existing pattern.

## Validating changes

There is no build/test suite. To validate template changes:

```bash
chezmoi --source=<repo-path> data                       # inspect template data
chezmoi --source=<repo-path> diff                        # preview rendered changes
chezmoi --source=<repo-path> apply --dry-run --verbose   # dry-run apply
```

Note: the README references `./validate_chezmoi_templates.sh` and `CHEZMOI_MIGRATION.md` for
multi-OS template validation, but these files do not currently exist in the repo — verify before
relying on them, or ask the user if they were intentionally removed.

## Layout reference

- `dot_config/` — Linux desktop stack (Hyprland, Waybar, Rofi, GTK/Qt, systemd user units) plus
  cross-platform tool configs (ghostty, btop, fastfetch, starship).
- `dot_zsh/` — zsh config templates and plugin list.
- `dot_pi/` — agent-related config.
- `Brewfile` — macOS-only Homebrew bundle, applied via the `run_onchange_*` script.
