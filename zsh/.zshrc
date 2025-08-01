# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Source environment variables
source "$HOME/.dotfiles/zsh/env.zsh"

# Source Aliases
source "$HOME/.dotfiles/zsh/aliases.zsh"

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
plugins=(git ansible zsh-syntax-highlighting zsh-autosuggestions direnv)

source $ZSH/oh-my-zsh.sh

# --- User Configuration --- #


# Use `brew --prefix` to make it portable between Intel and Apple Silicon Macs
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Homebrew autocompletion
# Oh My Zsh handles compinit, so we only need to add to FPATH.
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi


# 1Password CLI
eval "$(op completion zsh)"; compdef _op op # 1Password CLI completion

# Initialize Starship prompt (should be one of the last things).
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Yazi: Custom command to handle current working directory
# This function allows yazi to change the current working directory based on the output of the command
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Zoxide: cd replacement
eval "$(zoxide init zsh)"