# Environment Variables

# Editor
export EDITOR='code'

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set up PATH
# Order is important. Prepending ensures user-installed binaries are found first.

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Homebrew's bin directory
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# Cargo's bin directory for Rust tools
export PATH="$HOME/.cargo/bin:$PATH"

# Load Node Version Manager
export NVM_DIR="$HOME/.nvm"

# 1Password Socket
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Python
export PATH="$(brew --prefix python)/libexec/bin:$PATH"
