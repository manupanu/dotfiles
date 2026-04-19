# chezmoi features

This repository is a `chezmoi` source directory used to manage dotfiles. This note summarizes the most useful `chezmoi` features so the repo documents not just what is stored here, but what `chezmoi` can do for the setup over time.

The official documentation is at <https://www.chezmoi.io/>.

## Core ideas

- `chezmoi` manages a source state and applies it to a destination directory, which is usually your home directory.
- The source directory stays readable and Git-friendly: regular files and directories map to the files, directories, and symlinks that should exist on the machine.
- It is built for keeping one dotfiles repo working across multiple machines, operating systems, and host-specific setups.

## Key features

### 1. Cross-machine dotfile management

`chezmoi` is designed for maintaining one source of truth across macOS, Linux, Windows, and other Unix-like systems. It works well when a setup is mostly shared but still has a few machine-specific differences.

Useful commands:

```sh
chezmoi init
chezmoi apply
chezmoi update
```

### 2. Templates for machine-specific configuration

Files can be turned into templates using Go `text/template` syntax, with extra helper functions from `sprig` and `chezmoi`.

This is useful for:

- switching config by OS or hostname
- injecting values from config data
- reusing shared template snippets

Common examples include conditional shell config, editor settings, and Git identity values.

### 3. Data-driven configuration

`chezmoi` supports data files such as `.chezmoidata.*` and config values from the local `chezmoi` config file. That lets templates stay generic while machine-specific values live outside the tracked dotfiles content.

This is a good fit for:

- usernames
- email addresses
- hostnames
- work vs personal settings

### 4. Secret management

`chezmoi` can read secrets from a wide set of password managers and secret stores, including 1Password, Bitwarden, pass, Vault, macOS Keychain, and generic command-based secret sources.

This is useful when you want:

- secrets outside the repo
- templates that resolve secrets at apply time
- safer multi-machine bootstrapping

### 5. File encryption

Sensitive files can be stored encrypted in the source state and decrypted when editing or applying. The official docs list support for:

- `age`
- `gpg`
- `git-crypt`
- `transcrypt`

Example:

```sh
chezmoi add --encrypt ~/.ssh/id_rsa
```

### 6. Scripts and automation hooks

`chezmoi` can run scripts as part of applying the source state. This is helpful for setup steps that are not just file copies, such as:

- installing packages
- creating directories
- running bootstrap commands
- fixing platform-specific setup details

This is one of the main reasons `chezmoi` can replace a pile of ad hoc bootstrap notes.

### 7. External resources

`chezmoi` can pull external content into the managed state using `.chezmoiexternal.toml`, including git repos, archives, and remote files.

This repo already uses that feature for shell tooling:

- `oh-my-zsh`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

That makes it possible to keep the main repo small while still describing dependencies declaratively.

### 8. Ignore rules

`.chezmoiignore` lets the source repo contain helper files that should not be written to the destination directory. Patterns match the target path, not the source-state naming used inside the repo.

This is useful for:

- repo-only documentation
- notes and scratch files
- machine-specific exclusions
- template-driven ignore rules

In this repo, both `README.md` and this file are ignored so they stay as source documentation only.

### 9. Safe previews and diffs

`chezmoi` has dry-run and diff-style workflows so changes can be reviewed before they touch the home directory.

Useful commands:

```sh
chezmoi diff
chezmoi apply --dry-run
```

This makes it easier to trust changes before applying them on a workstation or a fresh machine.

### 10. Atomic, declarative updates

`chezmoi` computes the target state first and then updates files atomically. This reduces the chance of half-written config files if an update is interrupted.

That matters most for critical files like:

- shell startup files
- SSH config
- Git config
- editor config

## Special files worth knowing

Some of the most important special files in a `chezmoi` repo are:

- `.chezmoiignore` for ignoring targets
- `.chezmoiexternal.toml` for external resources
- `.chezmoidata.*` for template data
- `.chezmoitemplates/` for reusable templates
- `.chezmoiremove` for removing targets on apply
- `.chezmoiversion` for requiring a minimum `chezmoi` version

## Why `chezmoi` is a good fit for this repo

This repo is already using several of `chezmoi`'s strengths:

- tracked shell config files
- external dependency management with `.chezmoiexternal.toml`
- a repo-only docs pattern via `.chezmoiignore`

Natural next steps, if needed later, would be:

- converting repeated values into template data
- encrypting sensitive local config
- adding setup scripts for machine bootstrap

## References

- Homepage: <https://www.chezmoi.io/>
- What it does: <https://www.chezmoi.io/what-does-chezmoi-do/>
- Templating: <https://www.chezmoi.io/user-guide/templating/>
- Encryption: <https://www.chezmoi.io/user-guide/encryption/>
- Special files: <https://www.chezmoi.io/reference/special-files/>
- `.chezmoiignore`: <https://www.chezmoi.io/reference/special-files/chezmoiignore/>
