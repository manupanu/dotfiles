# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export OMZ_DIR="/usr/share/oh-my-zsh"

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

source $OMZ_DIR/oh-my-zsh.sh

# --- User Configuration --- #

# Source custom aliases if file exists
if [ -f "$ZSH_CUSTOM/aliases.zsh" ]; then
    source "$ZSH_CUSTOM/aliases.zsh"
fi

# Initialize Starship prompt.
eval "$(starship init zsh)"
