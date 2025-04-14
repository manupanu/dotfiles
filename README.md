# Manuels Dotfiles

These dotfiles are managed using [Dotbot](https://github.com/anishathalye/dotbot), a tool that automates the installation and management of dotfiles through symlinks.

## Installation

### Windows
> [!IMPORTANT]
> Only Admins can create Symlinks and Development maybe needs to be enabled.

Run:
```powershell
.\install.ps1
```

### Linux/macOS

Run:
```bash
./install
```

## About Dotbot

Dotbot is a configuration management tool that:
- Creates symlinks for your dotfiles
- Can install packages and run custom commands
- Uses YAML/JSON for configuration
- Handles cross-platform installations

Configuration is defined in `windows.conf.yaml` and `linux-darwin.conf.yaml`.
