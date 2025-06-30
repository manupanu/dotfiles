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
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# --- User Configuration --- #

# Source custom aliases if file exists
if [ -f "$ZSH_CUSTOM/aliases.zsh" ]; then
    source "$ZSH_CUSTOM/aliases.zsh"
fi

# Initialize Starship prompt.
eval "$(starship init zsh)"

# Load Node Version Manager
 export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add Homebrew binaries to path
export PATH="/opt/homebrew/bin:$PATH"

# 1Password CLI
eval "$(op completion zsh)"; compdef _op op # 1Password CLI completion
