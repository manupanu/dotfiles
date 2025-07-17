# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Editor
export EDITOR='code'

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# --- Oh My Zsh Settings --- #

# Hyphen insensitive completion: '_' and '-' are treated the same.
HYPHEN_INSENSITIVE="true"

# Auto-update Oh My Zsh without prompting.
zstyle ':omz:update' mode auto

# Enable command auto-correction suggestions.
ENABLE_CORRECTION="true"


# Set history timestamp format to 'dd.mm.yyyy'.
HIST_STAMPS="dd.mm.yyyy"

# Path to custom configuration files (plugins, themes, etc.).
ZSH_CUSTOM=$HOME/.config/zsh

# Plugins to load (git is default).
# Standard plugins: $ZSH/plugins/
# Custom plugins: $ZSH_CUSTOM/plugins/
plugins=(git zsh-syntax-highlighting zsh-autosuggestions direnv)

source $ZSH/oh-my-zsh.sh

# --- User Configuration --- #

# Source custom aliases if file exists
if [ -f "$ZSH_CUSTOM/aliases.zsh" ]; then
    source "$ZSH_CUSTOM/aliases.zsh"
fi

# Initialize Starship prompt.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Load Node Version Manager
 export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add Homebrew binaries to path
export PATH="/opt/homebrew/bin:$PATH"

# Homebrew autocompletion
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
  autoload -Uz compinit
  compinit
fi

# 1Password Socket
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
# 1Password CLI
eval "$(op completion zsh)"; compdef _op op # 1Password CLI completion

# Rustup
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# Load Rust binaries
if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi