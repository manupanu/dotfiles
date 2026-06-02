# Homebrew Bundle for macOS
# https://github.com/Homebrew/homebrew-bundle
#
# This file is managed by chezmoi and deployed to ~/Brewfile.
# After changing it, run `chezmoi apply` to install new packages automatically.
# You can also run `brew bundle` anytime from anywhere.

# --- Formulae (CLI tools) ---

# Shell essentials (already referenced in dotfiles)
brew "git"
brew "zsh"

# Prompt & smart directory jumping (configured in zshrc)
# On macOS these are installed here; on Linux/Windows they fall back to
# run_once_install-starship.sh / run_once_install-zoxide.sh
brew "starship"
brew "zoxide"

# Node version manager (path referenced in zshrc)
brew "nvm"

# --- Casks (GUI apps) ---

# Password manager & SSH signing (referenced in gitconfig)
cask "1password"
cask "1password-cli"

# Terminal (config in dot_config/ghostty/)
cask "ghostty"

# Editor (config in dot_config/zed/)
cask "zed"

# --- Fonts ---

# Nerd Font used by Ghostty config
cask "font-jetbrains-mono-nerd-font"
